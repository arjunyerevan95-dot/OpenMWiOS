#!/usr/bin/env python3

import pathlib
import subprocess
import sys
import tempfile
import unittest

PORT_ROOT = pathlib.Path(__file__).resolve().parents[1]
EXTRACTOR = PORT_ROOT / "scripts" / "extract-link-command.py"


class LinkCommandExtractorTests(unittest.TestCase):
    def test_compile_command_is_not_mistaken_for_final_link(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            log = root / "xcodebuild.log"
            output = root / "final.txt"
            compile_command = (
                "/usr/bin/clang++ -c main.cpp -o /tmp/openmw-ios-link-smoke.build/main.o")
            link_command = (
                "/usr/bin/clang++ /tmp/main.o -o "
                "/tmp/Release-iphoneos/openmw-ios-link-smoke.app/openmw-ios-link-smoke")
            log.write_text(f"{compile_command}\n{link_command}\n")

            result = subprocess.run(
                [
                    sys.executable,
                    str(EXTRACTOR),
                    str(log),
                    str(output),
                    "--bundle-executable",
                    "openmw-ios-link-smoke",
                ],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(output.read_text(), link_command + "\n")

    def test_requested_app_is_selected_from_multiple_link_commands(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            log = root / "xcodebuild.log"
            output = root / "final.txt"
            smoke_command = (
                "/usr/bin/clang++ /tmp/smoke.o -o "
                "/tmp/Release-iphoneos/openmw-ios-link-smoke.app/openmw-ios-link-smoke")
            app_command = (
                "/usr/bin/clang++ /tmp/openmw.o -o "
                "/tmp/Release-iphoneos/openmw.app/openmw")
            log.write_text(f"{smoke_command}\n{app_command}\n")

            result = subprocess.run(
                [
                    sys.executable,
                    str(EXTRACTOR),
                    str(log),
                    str(output),
                    "--bundle-executable",
                    "openmw",
                ],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(output.read_text(), app_command + "\n")


if __name__ == "__main__":
    unittest.main()
