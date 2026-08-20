import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
PATCH = ROOT / "patches" / "openmw" / "0010-ios-bound-white-world-diagnostics.patch"


class WorkOrder23BoundedDiagnosticsTests(unittest.TestCase):
    def test_program_inventory_uses_pinned_osg_accessors(self) -> None:
        source = PATCH.read_text(encoding="utf-8")
        self.assertIn("getNumShaders()", source)
        self.assertIn("getShader(i)", source)
        self.assertNotIn("getShaderList()", source)

    def test_program_and_readback_logging_are_hard_capped(self) -> None:
        source = PATCH.read_text(encoding="utf-8")
        self.assertIn("wo23ProgramCount < 8", source)
        self.assertIn("sampleFrames{ 600, 1200, 1800 }", source)
        self.assertIn("nextSample >= sampleFrames.size()", source)
        self.assertEqual(source.count("glReadPixels("), 1)

    def test_readback_is_pre_ui_and_does_not_change_render_state(self) -> None:
        source = PATCH.read_text(encoding="utf-8")
        draw = source.index("drawGeometry(renderInfo);")
        sample = source.index("logBoundedSceneReadback(state);", draw)
        pop = source.index("state.popStateSet();", sample)
        self.assertLess(draw, sample)
        self.assertLess(sample, pop)
        self.assertNotIn("glClear(", source)
        self.assertNotIn("glBindFramebuffer", source)


if __name__ == "__main__":
    unittest.main()
