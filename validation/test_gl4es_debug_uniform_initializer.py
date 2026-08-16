import pathlib
import shutil
import subprocess
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
GL4ES_GL = ROOT / "deps" / "gl4es" / "src" / "gl"
FIXTURE = ROOT / "validation" / "fixtures" / "gl4es_debug_uniform_initializer.c"


class Gl4esDebugUniformInitializerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.compiler = shutil.which("cc") or shutil.which("clang") or shutil.which("gcc")
        if cls.compiler is None:
            raise unittest.SkipTest("host C compiler is not available")

        cls.tempdir = tempfile.TemporaryDirectory()
        cls.binary = pathlib.Path(cls.tempdir.name) / "gl4es-debug-uniform-initializer"
        result = subprocess.run(
            [
                cls.compiler,
                "-std=c99",
                "-Wall",
                "-Wextra",
                "-Werror",
                "-Wno-sign-compare",
                str(FIXTURE),
                str(GL4ES_GL / "shader_hacks.c"),
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

    def test_vertex_and_fragment_initializers_are_normalized(self) -> None:
        result = subprocess.run(
            [str(self.binary)],
            check=False,
            capture_output=True,
            text=True,
            timeout=10,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("declaration and references preserved", result.stdout)


if __name__ == "__main__":
    unittest.main()
