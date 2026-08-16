import pathlib
import shutil
import subprocess
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
GL4ES_GL = ROOT / "deps" / "gl4es" / "src" / "gl"
FIXTURE = ROOT / "validation" / "fixtures" / "gl4es_mainless_linked_shader.c"


class Gl4esMainlessLinkedShaderTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.compiler = shutil.which("cc") or shutil.which("clang") or shutil.which("gcc")
        if cls.compiler is None:
            raise unittest.SkipTest("host C compiler is not available")

        cls.tempdir = tempfile.TemporaryDirectory()
        cls.binary = pathlib.Path(cls.tempdir.name) / "gl4es-mainless-linked-shader"
        result = subprocess.run(
            [
                cls.compiler,
                "-std=c99",
                "-Wall",
                "-Wextra",
                "-Werror",
                str(FIXTURE),
                str(GL4ES_GL / "string_utils.c"),
                "-I",
                str(GL4ES_GL),
                "-o",
                str(cls.binary),
            ],
            check=False,
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode != 0:
            raise AssertionError(f"fixture compilation failed:\n{result.stdout}\n{result.stderr}")

    @classmethod
    def tearDownClass(cls) -> None:
        cls.tempdir.cleanup()

    def run_fixture(self, mode: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(self.binary), mode],
            check=False,
            capture_output=True,
            text=True,
            timeout=10,
        )

    def test_legacy_nested_search_crashes_for_mainless_unit(self) -> None:
        result = self.run_fixture("legacy")
        self.assertNotEqual(result.returncode, 0)

    def test_fixed_path_skips_helper_and_transforms_entry_shader(self) -> None:
        result = self.run_fixture("fixed")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("main-less helper skipped", result.stdout)


if __name__ == "__main__":
    unittest.main()
