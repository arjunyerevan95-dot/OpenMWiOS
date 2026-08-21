#import "openmw_ios_paths.h"
#import "openmw_ios_logging.h"

#include "openmw_ios_data_path.hpp"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#include <SDL.h>

#include <cmath>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <string>
#include <vector>

namespace
{
    constexpr float DefaultRenderScale = 1.0f;
    constexpr float MinimumRenderScale = 0.25f;

    std::vector<std::string> sArguments;
    std::vector<char*> sArgumentPointers;

    void append(std::string value)
    {
        sArguments.emplace_back(std::move(value));
    }

    void migrateLegacyGeneratedDataEntry(const std::filesystem::path& config)
    {
        if (!std::filesystem::exists(config))
            return;

        std::ifstream stream(config, std::ios::binary);
        const std::string source((std::istreambuf_iterator<char>(stream)), std::istreambuf_iterator<char>());
        if (!stream.good() && !stream.eof())
        {
            openmw_ios_log("data_path_migration", "unable to read openmw.cfg; leaving it unchanged");
            return;
        }

        const OpenMWIOS::DataPath::ConfigMigration migration
            = OpenMWIOS::DataPath::removeLegacyGeneratedDataEntries(source);
        if (migration.removedEntries == 0)
        {
            openmw_ios_log("data_path_migration", "no legacy generated data entry found");
            return;
        }

        NSData* migrated = [NSData dataWithBytes:migration.text.data() length:migration.text.size()];
        NSString* configPath = [NSString stringWithUTF8String:config.c_str()];
        const BOOL written = [migrated writeToFile:configPath options:NSDataWritingAtomic error:nil];
        openmw_ios_log("data_path_migration",
            written ? "removed legacy sandbox-UUID data entry" : "failed to atomically update openmw.cfg");
    }

    void createInitialConfig(const std::filesystem::path& root, const std::filesystem::path& data)
    {
        const std::filesystem::path config = root / "openmw.cfg";
        if (std::filesystem::exists(config)
            || !std::filesystem::exists(data / "Morrowind.esm")
            || !std::filesystem::exists(data / "Morrowind.bsa"))
            return;

        std::ofstream stream(config);
        stream << "fallback-archive=Morrowind.bsa\n";
        stream << "content=Morrowind.esm\n";

        if (std::filesystem::exists(data / "Tribunal.esm") && std::filesystem::exists(data / "Tribunal.bsa"))
        {
            stream << "fallback-archive=Tribunal.bsa\n";
            stream << "content=Tribunal.esm\n";
        }
        if (std::filesystem::exists(data / "Bloodmoon.esm") && std::filesystem::exists(data / "Bloodmoon.bsa"))
        {
            stream << "fallback-archive=Bloodmoon.bsa\n";
            stream << "content=Bloodmoon.esm\n";
        }
    }

    float readRenderScale(const std::filesystem::path& root)
    {
        const std::filesystem::path config = root / "ios-render-scale.txt";
        std::ifstream stream(config);
        float scale = DefaultRenderScale;
        if (!(stream >> scale) || !std::isfinite(scale))
            return DefaultRenderScale;
        if (scale < MinimumRenderScale)
            return MinimumRenderScale;
        if (scale > DefaultRenderScale)
            return DefaultRenderScale;
        return scale;
    }
}

extern "C" void openmw_ios_prepare_environment(void)
{
    @autoreleasepool
    {
        const std::filesystem::path documents(openmw_ios_documents_path());
        const std::filesystem::path library(openmw_ios_library_path());
        const std::filesystem::path bundle(openmw_ios_bundle_path());
        const std::filesystem::path root = documents / "OpenMW";
        const std::filesystem::path data = OpenMWIOS::DataPath::defaultMorrowindDataPath(documents);

        UIScreen* screen = UIScreen.mainScreen;
        const CGRect screenBounds = screen.bounds;
        const CGRect nativeBounds = screen.nativeBounds;
        NSString* displayMetrics = [NSString stringWithFormat:
            @"screen_points=%.0fx%.0f;native_pixels=%.0fx%.0f;scale=%.3f;native_scale=%.3f",
            CGRectGetWidth(screenBounds), CGRectGetHeight(screenBounds), CGRectGetWidth(nativeBounds),
            CGRectGetHeight(nativeBounds), screen.scale, screen.nativeScale];
        openmw_ios_log("uikit_display_metrics", displayMetrics.UTF8String);

        std::filesystem::create_directories(root);
        std::filesystem::create_directories(data);
        std::filesystem::create_directories(library / "OpenMW");
        openmw_ios_log("sandbox_paths", ("documents=" + documents.string() + ";library=" + library.string()
            + ";bundle=" + bundle.string()).c_str());
        migrateLegacyGeneratedDataEntry(root / "openmw.cfg");
        createInitialConfig(root, data);

        setenv("HOME", library.parent_path().c_str(), 1);
        setenv("TMPDIR", NSTemporaryDirectory().fileSystemRepresentation, 1);
        setenv("OPENMW_DECOMPRESS_TEXTURES", "1", 1);
        setenv("LIBGL_ES", "2", 1);
        setenv("LIBGL_GL", "21", 1);
        setenv("OPENMW_GLES_VERSION", "2", 1);
        const float renderScale = readRenderScale(root);
        const std::string renderScaleValue = std::to_string(renderScale);
        setenv("OPENMW_IOS_RENDER_SCALE", renderScaleValue.c_str(), 1);
        openmw_ios_log("render_scale_config",
            ("path=" + (root / "ios-render-scale.txt").string() + ";scale=" + renderScaleValue).c_str());
        openmw_ios_log("requested_gl_profile", "OpenGL ES 2.0 through GL4ES");

        SDL_SetHint(SDL_HINT_ORIENTATIONS, "LandscapeLeft LandscapeRight");
        SDL_SetHint(SDL_HINT_IOS_HIDE_HOME_INDICATOR, "2");

        sArguments.clear();
        append("openmw");
        append("--config");
        append(root.string());
        append("--user-data");
        append((library / "OpenMW").string());
        append("--resources");
        append((bundle / "openmw-resources").string());
        append("--data");
        append(data.string());

        openmw_ios_log("config_path", (root / "openmw.cfg").c_str());
        openmw_ios_log("resources_path", (bundle / "openmw-resources").c_str());
        const bool hasMorrowindEsm = std::filesystem::exists(data / "Morrowind.esm");
        const bool hasMorrowindBsa = std::filesystem::exists(data / "Morrowind.bsa");
        if (hasMorrowindEsm && hasMorrowindBsa)
        {
            std::filesystem::remove(root / "MISSING_GAME_DATA.txt");
            openmw_ios_log("game_data_validation", "Morrowind.esm and Morrowind.bsa found");
        }
        else
        {
            const std::string message
                = "Morrowind game data was not found. Copy Morrowind.esm and Morrowind.bsa to "
                  "On My iPhone/OpenMW/Morrowind/Data Files.";
            std::ofstream(root / "MISSING_GAME_DATA.txt") << message << '\n';
            openmw_ios_log_fatal(message.c_str());
            SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "OpenMW game data not found", message.c_str(), nullptr);
        }

        sArgumentPointers.clear();
        for (std::string& argument : sArguments)
            sArgumentPointers.push_back(argument.data());
        sArgumentPointers.push_back(nullptr);
        std::string argvLog;
        for (const std::string& argument : sArguments)
            argvLog += (argvLog.empty() ? "" : " | ") + argument;
        openmw_ios_log("generated_argv", argvLog.c_str());
    }
}

extern "C" int openmw_ios_argc(void)
{
    return static_cast<int>(sArguments.size());
}

extern "C" char** openmw_ios_argv(void)
{
    return sArgumentPointers.data();
}
