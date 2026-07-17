#!/usr/bin/env python3

import os
import pathlib
import subprocess
import tempfile
import unittest

PORT_ROOT = pathlib.Path(__file__).resolve().parents[1]
VERIFIER = PORT_ROOT / "scripts" / "verify-linked-product.sh"


class LinkedProductVerifierTests(unittest.TestCase):
    def make_fake_xcrun(self, root: pathlib.Path) -> pathlib.Path:
        fake_bin = root / "bin"
        fake_bin.mkdir()
        xcrun = fake_bin / "xcrun"
        xcrun.write_text(
            """#!/usr/bin/env bash
set -euo pipefail
case \"$1:$2\" in
    lipo:-archs)
        echo arm64
        ;;
    vtool:-show-build)
        printf 'platform IOS\\nminos 16.3\\n'
        ;;
    nm:-u)
        echo '                 U _UIApplicationMain'
        ;;
    otool:-L)
        printf '%s:\\n\\t/usr/lib/libc++.1.dylib (compatibility version 1.0.0, current version 1.0.0)\\n' \"$3\"
        ;;
    *)
        echo \"unexpected xcrun invocation: $*\" >&2
        exit 1
        ;;
esac
""")
        xcrun.chmod(0o755)
        return fake_bin

    def run_verifier(
        self,
        root: pathlib.Path,
        linker_command: pathlib.Path | None,
    ) -> subprocess.CompletedProcess[str]:
        binary = root / "openmw-ios-link-smoke"
        binary.write_bytes(b"fixture")
        diagnostics = root / "diagnostics"
        diagnostics.mkdir(exist_ok=True)
        command = [str(VERIFIER), str(binary)]
        if linker_command is not None:
            command.append(str(linker_command))
        environment = os.environ.copy()
        environment.update(
            {
                "BUILD_DIAGNOSTICS_DIR": str(diagnostics),
                "IOS_DEPLOYMENT_TARGET": "16.3",
                "PATH": f"{self.make_fake_xcrun(root)}:{environment['PATH']}",
            }
        )
        return subprocess.run(
            command,
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=environment,
            cwd=PORT_ROOT,
        )

    def test_canonical_linker_command_is_not_copied_onto_itself(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            diagnostics = root / "diagnostics"
            diagnostics.mkdir()
            linker_command = diagnostics / "openmw-ios-link-smoke.final-link-command.txt"
            linker_command.write_text("clang++ smoke.o -o smoke\n")

            result = self.run_verifier(root, linker_command)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(linker_command.read_text(), "clang++ smoke.o -o smoke\n")

    def test_missing_linker_command_is_a_validation_failure(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)

            result = self.run_verifier(root, None)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("final linker command is required", result.stderr)


if __name__ == "__main__":
    unittest.main()
