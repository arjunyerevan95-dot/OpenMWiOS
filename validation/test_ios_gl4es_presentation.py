import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
GL4ES = ROOT / "deps" / "gl4es"
OPENMW = ROOT / "deps" / "openmw"


def native_default_framebuffer(main_fbo: int, external_fbo: int) -> int:
    """Contract model for GL4ES logical framebuffer zero."""
    return main_fbo if main_fbo else external_fbo


class IosGl4esPresentationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.framebuffers = (GL4ES / "src" / "gl" / "framebuffers.c").read_text(encoding="utf-8")
        cls.gl4es = (GL4ES / "src" / "gl" / "gl4es.c").read_text(encoding="utf-8")
        cls.init_header = (GL4ES / "include" / "gl4esinit.h").read_text(encoding="utf-8")
        cls.openmw_init = (
            OPENMW / "components" / "sdlutil" / "gl4esinit.cpp"
        ).read_text(encoding="utf-8")
        cls.graphics_window = (
            OPENMW / "components" / "sdlutil" / "sdlgraphicswindow.cpp"
        ).read_text(encoding="utf-8")

    def test_logical_zero_maps_to_external_drawable_without_main_fbo(self) -> None:
        self.assertEqual(native_default_framebuffer(0, 37), 37)
        self.assertEqual(native_default_framebuffer(91, 37), 91)
        self.assertIn(
            "return glstate->fbo.mainfbo_fbo ? glstate->fbo.mainfbo_fbo : glstate->fbo.default_fbo;",
            self.framebuffers,
        )
        self.assertIn("framebuffer = defaultFramebuffer();", self.framebuffers)

    def test_external_targets_are_registered_after_gl4es_initialization(self) -> None:
        native_query = self.openmw_init.index(
            'SDL_GL_GetProcAddress("glGetIntegerv")'
        )
        initialize = self.openmw_init.index("initialize_gl4es();")
        register = self.openmw_init.index(
            "set_defaultframebuffer(gDefaultFramebuffer, gDefaultRenderbuffer);"
        )
        self.assertLess(native_query, initialize)
        self.assertLess(initialize, register)
        self.assertIn(
            "void set_defaultframebuffer(unsigned int framebuffer, unsigned int renderbuffer);",
            self.init_header,
        )

    def test_logical_renderbuffer_zero_maps_to_sdl_drawable(self) -> None:
        self.assertIn(
            "renderbuffer ? renderbuffer : glstate->fbo.default_rbo",
            self.framebuffers,
        )
        self.assertIn(
            "(!rend->renderbuffer && renderbuffer!=0)",
            self.framebuffers,
        )
        self.assertIn("gl4es_bindDefaultRenderbuffer();", self.gl4es)

    def test_external_swap_hooks_wrap_sdl_swap(self) -> None:
        pre = self.graphics_window.index("openmw_gl4es_pre_swap();")
        swap = self.graphics_window.index("SDL_GL_SwapWindow(mWindow);")
        post = self.graphics_window.index("openmw_gl4es_post_swap();")
        self.assertLess(pre, swap)
        self.assertLess(swap, post)

    def test_patches_do_not_hardcode_native_fbo_or_renderbuffer_ids(self) -> None:
        patch_paths = (
            ROOT / "patches" / "gl4es" / "0005-map-external-default-drawable.patch",
            ROOT / "patches" / "openmw" / "0007-ios-present-through-sdl-drawable.patch",
        )
        for patch_path in patch_paths:
            text = patch_path.read_text(encoding="utf-8")
            additions = "\n".join(
                line[1:]
                for line in text.splitlines()
                if line.startswith("+") and not line.startswith("+++")
            )
            self.assertNotRegex(additions, r"default_(?:fbo|rbo)\s*=\s*[1-9]\d*")
            self.assertNotRegex(additions, r"set_defaultframebuffer\s*\(\s*[1-9]\d*")


if __name__ == "__main__":
    unittest.main()
