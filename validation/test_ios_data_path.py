import os
import pathlib
import shutil
import subprocess
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
HEADER = ROOT / "ios" / "openmw_ios_data_path.hpp"
BOOTSTRAP = ROOT / "ios" / "openmw_ios_bootstrap.mm"
PATHS = ROOT / "ios" / "openmw_ios_paths.mm"

PREFIX = "/var/mobile/Containers/Data/Application/"
SUFFIX = "/Documents/OpenMW/Morrowind/Data Files"


def default_data_path(documents: str) -> str:
    return f"{documents}/OpenMW/Morrowind/Data Files"


def is_legacy_generated_path(value: str) -> bool:
    value = value.strip(" \t\r")
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        value = value[1:-1]
    if value.startswith("/private"):
        value = value[len("/private"):]
    if not value.startswith(PREFIX):
        return False
    remainder = value[len(PREFIX):]
    separator = remainder.find("/")
    return separator > 0 and remainder[separator:] == SUFFIX


def migrate(config: str):
    output = []
    removed = 0
    for line in config.splitlines(keepends=True):
        candidate = line.strip(" \t\r\n")
        if candidate.startswith("data"):
            remainder = candidate[len("data"):].lstrip(" \t")
            if remainder.startswith("=") and is_legacy_generated_path(remainder[1:]):
                removed += 1
                continue
        output.append(line)
    return "".join(output), removed


class IosDataPathTests(unittest.TestCase):
    def test_current_documents_uses_canonical_foundation_lookup(self) -> None:
        source = PATHS.read_text(encoding="utf-8")
        self.assertIn("NSSearchPathForDirectoriesInDomains", source)
        self.assertIn("NSDocumentDirectory", source)
        self.assertIn("NSUserDomainMask", source)

    def test_default_path_is_relative_to_runtime_documents(self) -> None:
        self.assertEqual(
            default_data_path("/current/Documents"),
            "/current/Documents/OpenMW/Morrowind/Data Files",
        )
        header = HEADER.read_text(encoding="utf-8")
        self.assertIn('documents / "OpenMW" / "Morrowind" / "Data Files"', header)

    def test_simulated_container_a_is_recognized_as_legacy(self) -> None:
        old = f'{PREFIX}AAAAAAAA{SUFFIX}'
        self.assertTrue(is_legacy_generated_path(old))
        migrated, removed = migrate(f'data="{old}"\ncontent=Morrowind.esm\n')
        self.assertEqual(removed, 1)
        self.assertEqual(migrated, "content=Morrowind.esm\n")

    def test_simulated_container_b_is_runtime_derived_without_a(self) -> None:
        documents_b = f"{PREFIX}BBBBBBBB/Documents"
        resolved = default_data_path(documents_b)
        self.assertEqual(resolved, f"{PREFIX}BBBBBBBB{SUFFIX}")
        self.assertNotIn("AAAAAAAA", resolved)

    def test_stale_private_prefixed_generated_path_migrates(self) -> None:
        old = f'/private{PREFIX}AAAAAAAA{SUFFIX}'
        migrated, removed = migrate(f"  data = '{old}'\r\ncontent=Morrowind.esm\r\n")
        self.assertEqual(removed, 1)
        self.assertEqual(migrated, "content=Morrowind.esm\r\n")

    def test_unrelated_data_entries_are_preserved_byte_for_byte(self) -> None:
        config = (
            'data="/var/mobile/Documents/Custom Data"\n'
            'data="/private/var/mobile/Containers/Shared/AppGroup/group.example/Mods"\n'
        )
        self.assertEqual(migrate(config), (config, 0))

    def test_mod_paths_and_content_order_survive_migration(self) -> None:
        old = f'{PREFIX}AAAAAAAA{SUFFIX}'
        config = (
            f'data="{old}"\n'
            'data="/mods/base"\n'
            'data="/mods/override"\n'
            'content=Morrowind.esm\ncontent=MyMod.esp\n'
        )
        migrated, removed = migrate(config)
        self.assertEqual(removed, 1)
        self.assertEqual(
            migrated,
            'data="/mods/base"\ndata="/mods/override"\n'
            'content=Morrowind.esm\ncontent=MyMod.esp\n',
        )

    def test_settings_are_preserved_exactly(self) -> None:
        old = f'{PREFIX}AAAAAAAA{SUFFIX}'
        config = f'encoding=win1252\ndata="{old}"\nno-sound=0\n'
        migrated, _ = migrate(config)
        self.assertEqual(migrated, "encoding=win1252\nno-sound=0\n")

    def test_missing_directory_is_created_and_reports_stable_files_location(self) -> None:
        source = BOOTSTRAP.read_text(encoding="utf-8")
        self.assertIn("std::filesystem::create_directories(data);", source)
        self.assertIn("On My iPhone/OpenMW/Morrowind/Data Files", source)
        self.assertIn("SDL_ShowSimpleMessageBox", source)
        self.assertNotIn("<UUID>", source)

    def test_base_discovery_requires_morrowind_bsa(self) -> None:
        source = BOOTSTRAP.read_text(encoding="utf-8")
        self.assertIn('std::filesystem::exists(data / "Morrowind.bsa")', source)
        self.assertIn("hasMorrowindBsa", source)

    def test_base_discovery_requires_morrowind_esm(self) -> None:
        source = BOOTSTRAP.read_text(encoding="utf-8")
        self.assertIn('std::filesystem::exists(data / "Morrowind.esm")', source)
        self.assertIn("hasMorrowindEsm", source)

    def test_repeated_launch_migration_is_idempotent(self) -> None:
        old = f'{PREFIX}AAAAAAAA{SUFFIX}'
        first, first_removed = migrate(f'data="{old}"\ncontent=Morrowind.esm\n')
        second, second_removed = migrate(first)
        self.assertEqual(first_removed, 1)
        self.assertEqual(second_removed, 0)
        self.assertEqual(first, second)

    def test_runtime_argv_owns_default_path_and_new_config_does_not_persist_it(self) -> None:
        source = BOOTSTRAP.read_text(encoding="utf-8")
        self.assertIn('append("--data");', source)
        self.assertIn("append(data.string());", source)
        self.assertNotIn('stream << "data=', source)
        self.assertLess(source.index("migrateLegacyGeneratedDataEntry"), source.index("createInitialConfig(root, data)"))

    def test_expansions_are_enabled_only_when_matching_esm_and_bsa_exist(self) -> None:
        source = BOOTSTRAP.read_text(encoding="utf-8")
        self.assertIn(
            'std::filesystem::exists(data / "Tribunal.esm") && std::filesystem::exists(data / "Tribunal.bsa")',
            source,
        )
        self.assertIn(
            'std::filesystem::exists(data / "Bloodmoon.esm") && std::filesystem::exists(data / "Bloodmoon.bsa")',
            source,
        )

    def test_production_header_fixture_when_host_cxx_is_available(self) -> None:
        compiler = shutil.which("clang++") or shutil.which("g++") or shutil.which("c++")
        if compiler is None:
            self.skipTest("host C++ compiler is not available")
        fixture = r'''
#include "ios/openmw_ios_data_path.hpp"
#include <cassert>
#include <string>
int main()
{
    using namespace OpenMWIOS::DataPath;
    const std::string a = "/var/mobile/Containers/Data/Application/AAAAAAAA/Documents";
    const std::string b = "/var/mobile/Containers/Data/Application/BBBBBBBB/Documents";
    assert(defaultMorrowindDataPath(a).string().find("AAAAAAAA") != std::string::npos);
    assert(defaultMorrowindDataPath(b).string().find("BBBBBBBB") != std::string::npos);
    assert(isLegacyGeneratedDataPath(
        "\"/private/var/mobile/Containers/Data/Application/AAAAAAAA/Documents/OpenMW/Morrowind/Data Files\""));
    assert(!isLegacyGeneratedDataPath("\"/mods/Morrowind/Data Files\""));
    const std::string cfg =
        "data=\"/var/mobile/Containers/Data/Application/AAAAAAAA/Documents/OpenMW/Morrowind/Data Files\"\n"
        "data=\"/mods/override\"\ncontent=Morrowind.esm\n";
    const auto first = removeLegacyGeneratedDataEntries(cfg);
    assert(first.removedEntries == 1);
    assert(first.text == "data=\"/mods/override\"\ncontent=Morrowind.esm\n");
    const auto second = removeLegacyGeneratedDataEntries(first.text);
    assert(second.removedEntries == 0 && second.text == first.text);
}
'''
        with tempfile.TemporaryDirectory() as directory:
            directory_path = pathlib.Path(directory)
            source = directory_path / "fixture.cpp"
            binary = directory_path / ("fixture.exe" if os.name == "nt" else "fixture")
            source.write_text(fixture, encoding="utf-8")
            subprocess.run(
                [compiler, "-std=c++17", "-I", str(ROOT), str(source), "-o", str(binary)],
                check=True,
                capture_output=True,
                text=True,
            )
            subprocess.run([str(binary)], check=True, capture_output=True, text=True)


if __name__ == "__main__":
    unittest.main()
