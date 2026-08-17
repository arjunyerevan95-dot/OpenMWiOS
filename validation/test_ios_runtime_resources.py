import pathlib
import re
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
OPENMW_ROOT = ROOT / "deps" / "openmw"


class IosRuntimeResourceTests(unittest.TestCase):
    def test_ios_config_uses_relocated_vfs_mw_path(self) -> None:
        cmake = (OPENMW_ROOT / "CMakeLists.txt").read_text(encoding="utf-8")
        ios_branches = re.findall(
            r"if \(OPENMW_IOS\)(?P<body>.*?)elseif \(APPLE\)",
            cmake,
            flags=re.DOTALL,
        )
        body = next((candidate for candidate in ios_branches if "configure_resource_file" in candidate), None)
        self.assertIsNotNone(body)
        self.assertIn("files/openmw.cfg", body)
        self.assertNotIn("files/openmw.cfg.local", body)

        template = (OPENMW_ROOT / "files" / "openmw.cfg").read_text(encoding="utf-8")
        configured = template.replace("${OPENMW_RESOURCE_FILES}", "openmw-resources")
        self.assertIn("resources=openmw-resources\n", configured)
        self.assertIn("data=openmw-resources/vfs-mw\n", configured)
        self.assertIn("fallback=FontColor_color_header,223,201,159", configured)
        self.assertIn("fallback=FontColor_color_normal,202,165,96", configured)

    def test_vfs_mw_contains_the_fallback_gmst_bridge(self) -> None:
        script = OPENMW_ROOT / "files" / "data-mw" / "scripts" / "omw" / "esmfallbacks.lua"
        manifest = OPENMW_ROOT / "files" / "data-mw" / "builtin.omwscripts.in"
        self.assertTrue(script.is_file())
        self.assertIn("content.gameSettings.getFallbacks()", script.read_text(encoding="utf-8"))
        self.assertIn("LOAD: scripts/omw/esmfallbacks.lua", manifest.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
