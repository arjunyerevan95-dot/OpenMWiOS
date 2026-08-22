import pathlib
import re
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
OPENMW_PATCH = ROOT / "patches/openmw/0013-ios-wo30-exterior-renderer-diagnostics.patch"
GL4ES_PATCH = ROOT / "patches/gl4es/0006-ios-wo30-exterior-renderer-diagnostics.patch"


class Wo30RendererDiagnosticTests(unittest.TestCase):
    def test_openmw_diagnostics_cover_intended_fog_and_alpha_inputs(self):
        patch = OPENMW_PATCH.read_text(encoding="utf-8")
        self.assertIn("WO30 R2 intended fog", patch)
        self.assertIn("WO30 R1 alpha-state", patch)
        self.assertIn("WO30 R1 dds", patch)
        self.assertIn("#ifdef OPENMW_IOS", patch)

    def test_gl4es_diagnostics_cover_received_fog_and_dxt_alpha(self):
        patch = GL4ES_PATCH.read_text(encoding="utf-8")
        self.assertIn("WO30 R2 gl4es fog", patch)
        self.assertIn("WO30 R2 builtin fog", patch)
        self.assertIn("WO30 R1 dxt upload", patch)

    def test_diagnostics_are_bounded_and_not_frame_spam(self):
        combined = OPENMW_PATCH.read_text(encoding="utf-8") + GL4ES_PATCH.read_text(encoding="utf-8")
        budgets = [int(value) for value in re.findall(r"(?:Samples|calls|uniforms)\s*<\s*(\d+)", combined)]
        self.assertGreaterEqual(len(budgets), 5)
        self.assertTrue(all(0 < value <= 96 for value in budgets))
        self.assertNotIn("glReadPixels", combined)

    def test_diagnostics_do_not_change_renderer_state(self):
        combined = OPENMW_PATCH.read_text(encoding="utf-8") + GL4ES_PATCH.read_text(encoding="utf-8")
        forbidden = (
            "glEnable(GL_FOG",
            "glDisable(GL_FOG",
            "setFogStart(",
            "setFogEnd(",
            "setAttributeAndModes(alphaFunc",
            "transparent0 =",
        )
        added_lines = "\n".join(
            line[1:] for line in combined.splitlines() if line.startswith("+") and not line.startswith("+++")
        )
        for token in forbidden:
            self.assertNotIn(token, added_lines)


if __name__ == "__main__":
    unittest.main()
