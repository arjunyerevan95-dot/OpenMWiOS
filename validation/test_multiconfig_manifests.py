#!/usr/bin/env python3

import pathlib
import unittest

PORT_ROOT = pathlib.Path(__file__).resolve().parents[1]


class MultiConfigManifestTests(unittest.TestCase):
    def test_registrar_inventory_is_configuration_specific_end_to_end(self) -> None:
        ios_cmake = (PORT_ROOT / "ios" / "CMakeLists.txt").read_text()
        dependency_validator = (
            PORT_ROOT / "scripts" / "validate-ios-dependencies.sh").read_text()
        workflow = (PORT_ROOT / ".github" / "workflows" / "ios.yml").read_text()

        self.assertIn("required-osg-plugins-$<CONFIG>.txt", ios_cmake)
        self.assertNotIn("required-osg-plugins.txt", ios_cmake)
        self.assertIn(
            "required-osg-plugins-${CONFIGURATION}.txt",
            dependency_validator,
        )
        self.assertIn("required-osg-plugins-*.txt", workflow)


if __name__ == "__main__":
    unittest.main()
