import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
BUILD_IOS = (ROOT / "scripts" / "build-ios.sh").read_text(encoding="utf-8")
STRUCTURAL_PATCH = (
    ROOT / "patches" / "openmw" / "0001-openmw-ios-structural-port.patch"
).read_text(encoding="utf-8")
VERSIONS = (ROOT / "versions.env").read_text(encoding="utf-8")


def openmw_configure_command() -> str:
    start = BUILD_IOS.index('cmake -S "${DEPS_DIR}/openmw"')
    end = BUILD_IOS.index('\necho "Generated ${BUILD_DIR}/ios/OpenMW.xcodeproj"', start)
    return BUILD_IOS[start:end]


class WO38ColdOSGConfigurationTests(unittest.TestCase):
    def test_ios_openmw_configure_disables_only_optional_glib_discovery(self) -> None:
        configure = openmw_configure_command()
        self.assertEqual(1, configure.count("-DCMAKE_DISABLE_FIND_PACKAGE_GLIB=ON"))
        self.assertNotRegex(configure, r"CMAKE_DISABLE_FIND_PACKAGE_(?!GLIB)[A-Za-z0-9_]+")

    def test_no_homebrew_or_host_glib_path_is_embedded(self) -> None:
        combined = BUILD_IOS + STRUCTURAL_PATCH
        for forbidden in (
            "/usr/local/Cellar",
            "/opt/homebrew",
            "glibconfig.h",
            "GLIB_ROOT",
            "GLIB_DIR",
        ):
            self.assertNotIn(forbidden, combined)

    def test_ios_static_osg_plugin_filter_only_moves_dae(self) -> None:
        self.assertIn("-    osgdb_dae", STRUCTURAL_PATCH)
        self.assertIn("+    list(APPEND USED_OSG_PLUGINS osgdb_dae)", STRUCTURAL_PATCH)
        for required in (
            "osgdb_bmp",
            "osgdb_dds",
            "osgdb_freetype",
            "osgdb_jpeg",
            "osgdb_osg",
            "osgdb_png",
            "osgdb_serializers_osg",
            "osgdb_tga",
        ):
            self.assertNotIn(f"-    {required}", STRUCTURAL_PATCH)

    def test_platform_architecture_and_runtime_contract_are_unchanged(self) -> None:
        configure = openmw_configure_command()
        for required in (
            'IOS_DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET:-16.3}"',
            'VCPKG_TRIPLET="${VCPKG_TRIPLET:-arm64-ios-openmw-release}"',
            "-DPLATFORM=OS64",
            "-DOPENMW_IOS=ON",
            "-DOPENMW_GL4ES_MANUAL_INIT=ON",
            "-DOSG_STATIC=ON",
            "-DOSG_BUILD_PLATFORM_IPHONE=ON",
            "-DOSG_WINDOWING_SYSTEM=None",
        ):
            source = BUILD_IOS if required.startswith(("IOS_", "VCPKG_")) else configure
            self.assertIn(required, source)

    def test_dependency_pins_remain_exact(self) -> None:
        expected = {
            "OPENMW_REVISION": "f4bec41444214a7903bebd178389ca22ca13f646",
            "OSG_REVISION": "01cc2b585c8456a4ff843066b7e1a8715558289f",
            "GL4ES_REVISION": "c9895df34cd466c23bc60c2bd3db3d87e98fcbe7",
            "IOS_CMAKE_REVISION": "99f99df73dc752c7e88916fc1f9df6b9f8c40f8d",
            "VCPKG_REVISION": "cd61e1e26a038e82d6550a3ebbe0fbbfe7da78e3",
            "LUAJIT_REVISION": "8e6520a7aecd0517e792b359afbbfd7274791f5f",
        }
        actual = dict(
            line.split("=", 1)
            for line in VERSIONS.splitlines()
            if "=" in line and not line.startswith("#")
        )
        for key, value in expected.items():
            self.assertEqual(value, actual.get(key), key)


if __name__ == "__main__":
    unittest.main()
