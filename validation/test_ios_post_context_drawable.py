import pathlib
import re
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
OPENMW_ROOT = ROOT / "deps" / "openmw"


def reconcile_traits(current: tuple[int, int], drawable: tuple[int, int]) -> tuple[int, int]:
    """Contract model for the guarded production reconciliation."""
    if drawable[0] > 0 and drawable[1] > 0:
        return drawable
    return current


class IosPostContextDrawableTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.graphics = (
            OPENMW_ROOT / "components" / "sdlutil" / "sdlgraphicswindow.cpp"
        ).read_text(encoding="utf-8")
        cls.engine = (OPENMW_ROOT / "apps" / "openmw" / "engine.cpp").read_text(encoding="utf-8")
        cls.input_wrapper = (
            OPENMW_ROOT / "components" / "sdlutil" / "sdlinputwrapper.cpp"
        ).read_text(encoding="utf-8")

    def test_drawable_is_queried_after_context_and_before_gl4es_init(self) -> None:
        context = self.graphics.index("mContext = SDL_GL_CreateContext(mWindow);")
        post_query = self.graphics.index("SDL_GL_GetDrawableSize(mWindow, &drawableWidth, &drawableHeight);")
        gl4es = self.graphics.index("openmw_gl4es_init(mWindow);")
        self.assertLess(context, post_query)
        self.assertLess(post_query, gl4es)

    def test_traits_are_reconciled_only_from_valid_drawable_pixels(self) -> None:
        self.assertRegex(
            self.graphics,
            re.compile(
                r"if \(drawableWidth > 0 && drawableHeight > 0\).*?"
                r"_traits->width = drawableWidth;.*?_traits->height = drawableHeight;",
                re.DOTALL,
            ),
        )
        self.assertEqual(reconcile_traits((480, 320), (960, 640)), (960, 640))
        self.assertEqual(reconcile_traits((960, 640), (960, 640)), (960, 640))
        self.assertEqual(reconcile_traits((480, 320), (0, 0)), (480, 320))
        self.assertEqual(reconcile_traits((960, 640), (640, 960)), (640, 960))

    def test_renderer_settings_and_camera_consume_reconciled_traits(self) -> None:
        graphics_window = self.engine.index("graphicsWindow = new SDLUtil::GraphicsWindowSDL2(traits, vsync);")
        settings = self.engine.index("Settings::video().mResolutionX.set(drawableWidth);")
        camera = self.engine.index("camera->setViewport(0, 0, graphicsWindow->getTraits()->width")
        self.assertLess(graphics_window, settings)
        self.assertLess(settings, camera)
        self.assertIn("Settings::video().mResolutionY.set(drawableHeight);", self.engine)
        self.assertIn("Settings::Manager::resetPendingChanges(resolutionSettings);", self.engine)

    def test_runtime_resize_path_uses_drawable_pixels_too(self) -> None:
        self.assertIn("SDL_GL_GetDrawableSize(mSDLWindow, &w, &h);", self.input_wrapper)
        self.assertIn("getGraphicsContext()->resized(x, y, w, h);", self.input_wrapper)
        self.assertIn("windowResize(x, y, w, h);", self.input_wrapper)

    def test_fix_contains_no_device_resolution_or_scale_multiplier(self) -> None:
        patch = (ROOT / "patches" / "openmw" / "0006-ios-reconcile-post-context-drawable.patch").read_text(
            encoding="utf-8"
        )
        additions = "\n".join(line[1:] for line in patch.splitlines() if line.startswith("+") and not line.startswith("+++"))
        for forbidden in ("480", "320", "800", "600", "1440", "960", "nativeScale *", "screen.scale *"):
            self.assertNotIn(forbidden, additions)


if __name__ == "__main__":
    unittest.main()
