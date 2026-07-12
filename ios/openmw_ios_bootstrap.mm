#import "openmw_ios_paths.h"

#import <Foundation/Foundation.h>

#include <SDL.h>

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

namespace
{
    std::vector<std::string> sArguments;
    std::vector<char*> sArgumentPointers;

    void append(std::string value)
    {
        sArguments.emplace_back(std::move(value));
    }

    void createInitialConfig(const std::filesystem::path& root)
    {
        const std::filesystem::path config = root / "openmw.cfg";
        const std::filesystem::path data = root / "Morrowind" / "Data Files";
        if (std::filesystem::exists(config) || !std::filesystem::exists(data / "Morrowind.esm"))
            return;

        std::ofstream stream(config);
        stream << "data=\"" << data.string() << "\"\n";
        stream << "fallback-archive=Morrowind.bsa\n";
        stream << "content=Morrowind.esm\n";

        if (std::filesystem::exists(data / "Tribunal.esm"))
        {
            stream << "fallback-archive=Tribunal.bsa\n";
            stream << "content=Tribunal.esm\n";
        }
        if (std::filesystem::exists(data / "Bloodmoon.esm"))
        {
            stream << "fallback-archive=Bloodmoon.bsa\n";
            stream << "content=Bloodmoon.esm\n";
        }
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

        std::filesystem::create_directories(root);
        std::filesystem::create_directories(library / "OpenMW");
        createInitialConfig(root);

        setenv("HOME", library.parent_path().c_str(), 1);
        setenv("TMPDIR", NSTemporaryDirectory().fileSystemRepresentation, 1);
        setenv("OPENMW_DECOMPRESS_TEXTURES", "1", 1);
        setenv("LIBGL_ES", "2", 1);
        setenv("LIBGL_GL", "21", 1);

        SDL_SetHint(SDL_HINT_ORIENTATIONS, "LandscapeLeft LandscapeRight");
        SDL_SetHint(SDL_HINT_IOS_HIDE_HOME_INDICATOR, "2");

        sArguments.clear();
        append("openmw");
        append("--config");
        append(root.string());
        append("--user-data");
        append((library / "OpenMW").string());
        append("--resources");
        append((bundle / "resources").string());

        sArgumentPointers.clear();
        for (std::string& argument : sArguments)
            sArgumentPointers.push_back(argument.data());
        sArgumentPointers.push_back(nullptr);
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
