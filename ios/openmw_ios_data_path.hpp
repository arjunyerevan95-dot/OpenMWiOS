#pragma once

#include <cstddef>
#include <filesystem>
#include <string>
#include <string_view>

namespace OpenMWIOS::DataPath
{
    inline std::filesystem::path defaultMorrowindDataPath(const std::filesystem::path& documents)
    {
        return documents / "OpenMW" / "Morrowind" / "Data Files";
    }

    inline std::string_view trim(std::string_view value)
    {
        while (!value.empty() && (value.front() == ' ' || value.front() == '\t'))
            value.remove_prefix(1);
        while (!value.empty() && (value.back() == ' ' || value.back() == '\t' || value.back() == '\r'))
            value.remove_suffix(1);
        return value;
    }

    inline bool isLegacyGeneratedDataPath(std::string_view value)
    {
        value = trim(value);
        if (value.size() >= 2 && ((value.front() == '"' && value.back() == '"')
                                   || (value.front() == '\'' && value.back() == '\'')))
        {
            value.remove_prefix(1);
            value.remove_suffix(1);
        }

        constexpr std::string_view PrivatePrefix = "/private";
        if (value.substr(0, PrivatePrefix.size()) == PrivatePrefix)
            value.remove_prefix(PrivatePrefix.size());

        constexpr std::string_view ContainerPrefix = "/var/mobile/Containers/Data/Application/";
        constexpr std::string_view DataSuffix = "/Documents/OpenMW/Morrowind/Data Files";
        if (value.substr(0, ContainerPrefix.size()) != ContainerPrefix || value.size() <= ContainerPrefix.size())
            return false;

        value.remove_prefix(ContainerPrefix.size());
        const std::size_t separator = value.find('/');
        return separator != std::string_view::npos && separator > 0 && value.substr(separator) == DataSuffix;
    }

    inline bool isLegacyGeneratedDataLine(std::string_view line)
    {
        line = trim(line);
        constexpr std::string_view Key = "data";
        if (line.substr(0, Key.size()) != Key)
            return false;
        line.remove_prefix(Key.size());
        line = trim(line);
        if (line.empty() || line.front() != '=')
            return false;
        line.remove_prefix(1);
        return isLegacyGeneratedDataPath(line);
    }

    struct ConfigMigration
    {
        std::string text;
        std::size_t removedEntries = 0;
    };

    inline ConfigMigration removeLegacyGeneratedDataEntries(std::string_view config)
    {
        ConfigMigration result;
        result.text.reserve(config.size());

        std::size_t offset = 0;
        while (offset < config.size())
        {
            const std::size_t newline = config.find('\n', offset);
            const std::size_t lineEnd = newline == std::string_view::npos ? config.size() : newline;
            const std::string_view line = config.substr(offset, lineEnd - offset);
            if (isLegacyGeneratedDataLine(line))
                ++result.removedEntries;
            else
            {
                const std::size_t copyEnd = newline == std::string_view::npos ? config.size() : newline + 1;
                result.text.append(config.substr(offset, copyEnd - offset));
            }

            if (newline == std::string_view::npos)
                break;
            offset = newline + 1;
        }
        return result;
    }
}
