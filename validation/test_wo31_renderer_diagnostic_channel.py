import pathlib
import re
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
BRIDGE = ROOT / "ios" / "openmw_ios_renderer_diagnostics.mm"
HEADER = ROOT / "ios" / "openmw_ios_renderer_diagnostics.h"
BOOTSTRAP = ROOT / "ios" / "openmw_ios_bootstrap.mm"
OPENMW_PATCH = ROOT / "patches" / "openmw" / "0013-ios-file-backed-renderer-diagnostics.patch"
GL4ES_PATCH = ROOT / "patches" / "gl4es" / "0006-ios-file-backed-renderer-diagnostics.patch"


def added_lines(patch: str) -> str:
    return "\n".join(
        line[1:]
        for line in patch.splitlines()
        if line.startswith("+") and not line.startswith("+++")
    )


class WorkOrder31RendererDiagnosticChannelTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.bridge = BRIDGE.read_text(encoding="utf-8")
        cls.header = HEADER.read_text(encoding="utf-8")
        cls.bootstrap = BOOTSTRAP.read_text(encoding="utf-8")
        cls.openmw_patch = OPENMW_PATCH.read_text(encoding="utf-8")
        cls.gl4es_patch = GL4ES_PATCH.read_text(encoding="utf-8")

    def test_log_uses_runtime_documents_directory_and_logical_public_path(self) -> None:
        self.assertIn("openmw_ios_documents_path()", self.bridge)
        self.assertIn('@"OpenMW"', self.bridge)
        self.assertIn('@"renderer-diagnostic.jsonl"', self.bridge)
        self.assertIn("Documents/OpenMW/renderer-diagnostic.jsonl", self.bridge)
        self.assertNotIn("/var/mobile/Containers/Data/Application", self.bridge)

    def test_channel_is_explicitly_gated_and_defaults_disabled(self) -> None:
        self.assertIn('std::getenv("OPENMW_IOS_RENDERER_DIAGNOSTICS")', self.bridge)
        self.assertIn('enabled && std::string(enabled) == "1"', self.bridge)
        self.assertIn('setenv("OPENMW_IOS_RENDERER_DIAGNOSTICS", "1", 1)', self.bootstrap)
        self.assertNotRegex(self.bridge, r"sEnabled\s*=\s*true")

    def test_schema_supports_session_sample_family_source_and_correlation(self) -> None:
        for field in ("schema", "session", "sample", "family", "source", "correlation", "detail"):
            self.assertIn(f'@"{field}"', self.bridge)
        self.assertIn("openmw-ios-renderer-diagnostic-v1", self.bridge)
        self.assertIn("NSUUID.UUID.UUIDString", self.bridge)

    def test_probe_families_and_total_output_are_hard_bounded(self) -> None:
        self.assertIn("MaxFileBytes = 256 * 1024", self.bridge)
        expected_budgets = {
            "r1.asset": 48,
            "r1.upload": 48,
            "r1.draw": 96,
            "r1.state": 48,
            "r2.intent": 16,
            "r2.received": 32,
            "r2.applied": 32,
        }
        for family, budget in expected_budgets.items():
            self.assertRegex(
                self.bridge,
                rf'family\.rfind\("{re.escape(family)}", 0\) == 0\)\s*return {budget};',
            )
        self.assertIn('state.exhausted = true', self.bridge)
        self.assertIn('@"correlation" : @"exhausted"', self.bridge)
        self.assertIn("sBytes + line.length > MaxFileBytes", self.bridge)

    def test_openmw_and_gl4es_records_share_texture_hash_correlation(self) -> None:
        self.assertIn("openmw_ios_renderer_diag_hash(image->data()", self.openmw_patch)
        self.assertIn("openmw_ios_renderer_diag_register_texture", self.openmw_patch)
        self.assertIn('"r1.asset"', self.bridge)
        self.assertIn("openmw_ios_renderer_diag_texture_category(hash)", self.gl4es_patch)
        self.assertIn('"r1.upload"', self.gl4es_patch)
        self.assertIn('"r1.draw"', self.gl4es_patch)
        self.assertIn('"r1.state"', self.openmw_patch)

    def test_r1_records_capture_asset_intent_upload_and_applied_draw_state(self) -> None:
        for token in (
            "identity=", "pixel_format=", "compressed=", "translucent=",
            "alpha_func=", "alpha_ref=", "alpha_blend=", "render_bin=",
        ):
            self.assertIn(token, self.openmw_patch)
        for token in (
            "format=", "simple_alpha=", "complex_alpha=", "blend_func=",
            "alpha_test=", "fog_start=", "fog_end=", "program=",
        ):
            self.assertIn(token, self.gl4es_patch)

    def test_r2_records_capture_openmw_intent_and_gl4es_received_and_applied_values(self) -> None:
        self.assertIn('"r2.intent"', self.openmw_patch)
        self.assertIn("start=%.6g;end=%.6g;far=%.6g;color=", self.openmw_patch)
        self.assertIn('"r2.received"', self.gl4es_patch)
        self.assertIn('"r2.applied"', self.gl4es_patch)
        self.assertIn("wo31_diag_fog_received", self.gl4es_patch)
        self.assertIn("wo31_diag_fog_applied", self.gl4es_patch)

    def test_gl4es_diagnostics_do_not_mutate_renderer_state(self) -> None:
        additions = added_lines(self.gl4es_patch)
        forbidden = (
            "gl4es_glEnable(", "gl4es_glDisable(", "gl4es_glBlendFunc(",
            "gl4es_glAlphaFunc(", "gl4es_glFog", "gles_gl", "glBindFramebuffer(",
            "glClear(", "glViewport(",
        )
        for token in forbidden:
            self.assertNotIn(token, additions)

    def test_gl4es_draw_probe_only_records_registered_representative_textures(self) -> None:
        self.assertIn("if (!category)", self.gl4es_patch)
        self.assertIn("if (wo31_category)", self.gl4es_patch)
        self.assertEqual(self.gl4es_patch.count("wo31_diag_draw("), 3)

    def test_diagnostic_sources_are_present_in_deterministic_patch_stacks(self) -> None:
        self.assertIn("openmw_ios_renderer_diagnostics.mm", self.openmw_patch)
        self.assertIn("ios_renderer_diag.c", self.gl4es_patch)
        self.assertIn("OPENMW_IOS", self.openmw_patch)
        self.assertIn("defined(__APPLE__)", self.gl4es_patch)


if __name__ == "__main__":
    unittest.main()
