import math
import pathlib
import plistlib
import re
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
PATCH = ROOT / "patches" / "openmw" / "0011-ios-aspect-render-scale.patch"
BOOTSTRAP = ROOT / "ios" / "openmw_ios_bootstrap.mm"
INFO_PLIST = ROOT / "ios" / "Info.plist.in"
DRAWABLE_PATCH = ROOT / "patches" / "openmw" / "0006-ios-reconcile-post-context-drawable.patch"
RENDERING_MANAGER = ROOT / "deps" / "openmw" / "apps" / "openmw" / "mwrender" / "renderingmanager.cpp"


def scaled_dimension(output_dimension: int, scale: float) -> int:
    if scale >= 1.0:
        return output_dimension
    rounded = max(2, math.floor(output_dimension * scale + 0.5))
    return rounded + rounded % 2


class IosRenderScaleTests(unittest.TestCase):
    def test_production_plist_opts_into_modern_fullscreen_scene_sizing(self) -> None:
        plist = plistlib.loads(INFO_PLIST.read_bytes())
        self.assertIn("UILaunchScreen", plist)
        self.assertEqual(plist["UILaunchScreen"], {})

    def test_native_scale_preserves_authoritative_drawable_dimensions(self) -> None:
        for width, height in ((1440, 960), (2868, 1320), (2732, 2048)):
            self.assertEqual(scaled_dimension(width, 1.0), width)
            self.assertEqual(scaled_dimension(height, 1.0), height)

    def test_point_five_eight_scale_applies_to_both_axes_and_preserves_aspect(self) -> None:
        for width, height in ((1440, 960), (2868, 1320), (2732, 2048)):
            scaled_width = scaled_dimension(width, 0.58)
            scaled_height = scaled_dimension(height, 0.58)
            self.assertEqual(scaled_width % 2, 0)
            self.assertEqual(scaled_height % 2, 0)
            self.assertLessEqual(abs(scaled_width - width * 0.58), 2.0)
            self.assertLessEqual(abs(scaled_height - height * 0.58), 2.0)
            self.assertLess(abs((scaled_width / scaled_height) - (width / height)), 0.002)
            self.assertAlmostEqual((scaled_width * scaled_height) / (width * height), 0.58**2, delta=0.0015)

    def test_runtime_interface_defaults_and_clamps_without_device_dimensions(self) -> None:
        bootstrap = BOOTSTRAP.read_text(encoding="utf-8")
        self.assertIn('"ios-render-scale.txt"', bootstrap)
        self.assertIn('setenv("OPENMW_IOS_RENDER_SCALE"', bootstrap)
        self.assertIn("DefaultRenderScale = 1.0f", bootstrap)
        self.assertIn("MinimumRenderScale = 0.25f", bootstrap)
        self.assertNotRegex(bootstrap, re.compile(r"\b(?:1440|960|2868|1320|800|600)\b"))

    def test_internal_scene_and_output_canvas_use_distinct_dimensions(self) -> None:
        patch = PATCH.read_text(encoding="utf-8")
        self.assertIn("mHUDCamera->resize(mWidth, mHeight);", patch)
        self.assertIn("mViewer->getCamera()->resize(renderWidth(), renderHeight());", patch)
        self.assertIn("return scaledRenderDimension(mWidth);", patch)
        self.assertIn("return scaledRenderDimension(mHeight);", patch)
        self.assertNotIn("mHUDCamera->resize(renderWidth(), renderHeight());", patch)

    def test_projection_uses_full_output_aspect_and_drawable_is_runtime_derived(self) -> None:
        rendering = RENDERING_MANAGER.read_text(encoding="utf-8")
        self.assertIn("const int width = Settings::video().mResolutionX;", rendering)
        self.assertIn("const int height = Settings::video().mResolutionY;", rendering)
        self.assertIn("static_cast<double>(width) / height", rendering)

        drawable_patch = DRAWABLE_PATCH.read_text(encoding="utf-8")
        self.assertIn("Settings::video().mResolutionX.set(drawableWidth);", drawable_patch)
        self.assertIn("Settings::video().mResolutionY.set(drawableHeight);", drawable_patch)

    def test_bounded_performance_instrumentation_is_gameplay_only(self) -> None:
        patch = PATCH.read_text(encoding="utf-8")
        self.assertIn("iosPerformanceWindowFrames = 300", patch)
        self.assertIn("iosPerformanceWindowLimit = 4", patch)
        self.assertIn("StateManager::State_Running", patch)
        self.assertIn('openmw_ios_log("performance_window", detail);', patch)


if __name__ == "__main__":
    unittest.main()
