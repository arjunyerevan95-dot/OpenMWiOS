#!/usr/bin/env python3

import pathlib
import subprocess
import sys
import tempfile
import unittest

PORT_ROOT = pathlib.Path(__file__).resolve().parents[1]
VERIFIER = PORT_ROOT / "scripts" / "verify-link-map.py"


class LinkMapVerifierTests(unittest.TestCase):
    def run_verifier(
            self, link_map: pathlib.Path, manifest: pathlib.Path, report: pathlib.Path
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(VERIFIER), str(link_map), str(manifest), str(report)],
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

    def test_exact_archive_object_contribution_passes(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            archive = root / "products" / "libExact.a"
            archive.parent.mkdir()
            archive.touch()
            link_map = root / "smoke.map"
            link_map.write_text(f"# Object files:\n[  1] {archive}(anchor.o)\n")
            manifest = root / "participation.tsv"
            manifest.write_text(
                "name\tcategory\tarchive\n"
                f"Exact\ttest\t{archive}\n")
            report = root / "report.tsv"

            result = self.run_verifier(link_map, manifest, report)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("\t1\tpassed", report.read_text())

    def test_same_basename_at_wrong_path_does_not_pass(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            expected = root / "expected" / "libSame.a"
            unrelated = root / "unrelated" / "libSame.a"
            expected.parent.mkdir()
            unrelated.parent.mkdir()
            expected.touch()
            unrelated.touch()
            link_map = root / "smoke.map"
            link_map.write_text(f"# Object files:\n[  1] {unrelated}(wrong.o)\n")
            manifest = root / "participation.tsv"
            manifest.write_text(
                "name\tcategory\tarchive\n"
                f"Expected\ttest\t{expected}\n")
            report = root / "report.tsv"

            result = self.run_verifier(link_map, manifest, report)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("did not contribute", result.stderr)


if __name__ == "__main__":
    unittest.main()
