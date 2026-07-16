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
                [sys.executable, str(EXTRACTOR), str(log), str(output)],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(output.read_text(), link_command + "\n")


if __name__ == "__main__":
    unittest.main()
