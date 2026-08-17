import pathlib
import re
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
OPENMW_ROOT = ROOT / "deps" / "openmw"


class IosDrawableFramebufferTests(unittest.TestCase):
    def test_gl4es_main_framebuffer_uses_drawable_pixels(self) -> None:
        source = (OPENMW_ROOT / "components" / "sdlutil" / "gl4esinit.cpp").read_text(encoding="utf-8")
        callback = re.search(
            r"void openmw_gl4es_GetMainFBSize\(int\* width, int\* height\)(?P<body>.*?)\n    }",
            source,
            flags=re.DOTALL,
        )
        self.assertIsNotNone(callback)
        body = callback.group("body")
        self.assertIn("SDL_GL_GetDrawableSize(gWindow, width, height);", body)
        self.assertNotIn("SDL_GetWindowSize(gWindow, width, height);", body)
        self.assertNotRegex(body, r"\b(?:1320|2868|1290|2796)\b")


if __name__ == "__main__":
    unittest.main()
