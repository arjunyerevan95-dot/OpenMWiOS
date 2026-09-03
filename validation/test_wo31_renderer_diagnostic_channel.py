import json
import os
import pathlib
import re
import shutil
import subprocess
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
BRIDGE = ROOT / "ios" / "openmw_ios_renderer_diagnostics.mm"
HEADER = ROOT / "ios" / "openmw_ios_renderer_diagnostics.h"
BOOTSTRAP = ROOT / "ios" / "openmw_ios_bootstrap.mm"
OPENMW_PATCH = ROOT / "patches" / "openmw" / "0013-ios-file-backed-renderer-diagnostics.patch"
GL4ES_PATCH = ROOT / "patches" / "gl4es" / "0006-ios-file-backed-renderer-diagnostics.patch"
GL4ES_OBSERVABILITY_PATCH = ROOT / "patches" / "gl4es" / "0007-ios-renderer-diagnostics-observable-paths.patch"
OPENMW_RUNTIME_PATCH = ROOT / "patches" / "openmw" / "0014-ios-renderer-diagnostics-runtime-fog-intent.patch"
OSG_PATCH = ROOT / "ios" / "patches" / "osg-route-gl-entry-points-through-gl4es.patch"
BRIDGE_FIXTURE = ROOT / "validation" / "fixtures" / "wo31_gl4es_bridge_fixture.c"


def added_lines(patch: str) -> str:
    return "\n".join(
        line[1:]
        for line in patch.splitlines()
        if line.startswith("+") and not line.startswith("+++")
    )


def persistent_foundation_globals_are_copied(source: str) -> bool:
    return (
        'sPath = [[directory stringByAppendingPathComponent:@"renderer-diagnostic.jsonl"] copy];'
        in source
        and "sSession = [NSUUID.UUID.UUIDString copy];" in source
        and 'sPath = [directory stringByAppendingPathComponent:@"renderer-diagnostic.jsonl"];'
        not in source
        and "sSession = NSUUID.UUID.UUIDString;" not in source
    )


def extract_added_file(patch: str, path: str) -> str:
    marker = f"diff --git a/{path} b/{path}"
    block = patch.split(marker, 1)[1].split("\ndiff --git ", 1)[0]
    return "\n".join(
        line[1:] for line in block.splitlines() if line.startswith("+") and not line.startswith("+++")
    ) + "\n"


def apply_file_patch(source: str, patch: str, path: str) -> str:
    marker = f"diff --git a/{path} b/{path}"
    block = patch.split(marker, 1)[1].split("\ndiff --git ", 1)[0]
    original = source.splitlines()
    output = []
    cursor = 0
    chunks = re.split(r"(?=^@@ )", block, flags=re.MULTILINE)
    for chunk in chunks:
        if not chunk.startswith("@@ "):
            continue
        lines = chunk.splitlines()
        match = re.match(r"@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@", lines[0])
        if not match:
            raise AssertionError(f"invalid hunk header: {lines[0]}")
        old_start = int(match.group(1)) - 1
        output.extend(original[cursor:old_start])
        cursor = old_start
        for line in lines[1:]:
            if line.startswith(" "):
                assert original[cursor] == line[1:]
                output.append(original[cursor])
                cursor += 1
            elif line.startswith("-"):
                assert original[cursor] == line[1:]
                cursor += 1
            elif line.startswith("+"):
                output.append(line[1:])
            elif line == "\\ No newline at end of file":
                continue
    output.extend(original[cursor:])
    return "\n".join(output) + "\n"


class WorkOrder31RendererDiagnosticChannelTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.bridge = BRIDGE.read_text(encoding="utf-8")
        cls.header = HEADER.read_text(encoding="utf-8")
        cls.bootstrap = BOOTSTRAP.read_text(encoding="utf-8")
        cls.openmw_patch = OPENMW_PATCH.read_text(encoding="utf-8")
        cls.gl4es_patch = GL4ES_PATCH.read_text(encoding="utf-8")
        cls.gl4es_observability_patch = GL4ES_OBSERVABILITY_PATCH.read_text(encoding="utf-8")
        cls.openmw_runtime_patch = OPENMW_RUNTIME_PATCH.read_text(encoding="utf-8")
        cls.osg_patch = OSG_PATCH.read_text(encoding="utf-8")

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

    def test_persistent_foundation_objects_have_explicit_mrc_ownership(self) -> None:
        self.assertTrue(persistent_foundation_globals_are_copied(self.bridge))

        rejected_source = self.bridge.replace(
            'sPath = [[directory stringByAppendingPathComponent:@"renderer-diagnostic.jsonl"] copy];',
            'sPath = [directory stringByAppendingPathComponent:@"renderer-diagnostic.jsonl"];',
        ).replace(
            "sSession = [NSUUID.UUID.UUIDString copy];",
            "sSession = NSUUID.UUID.UUIDString;",
        )
        self.assertFalse(persistent_foundation_globals_are_copied(rejected_source))

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

    def test_amendment_two_uses_guaranteed_lookup_draw_and_osg_texture_name_boundaries(self) -> None:
        self.assertIn('wo31_diag_handshake("gl4es_GetProcAddress")', self.gl4es_observability_patch)
        self.assertIn("wo31_diag_fog_applied(wo31_program", self.gl4es_observability_patch)
        self.assertIn("openmw_ios_renderer_diag_texture_category_for_gl_name", self.gl4es_observability_patch)
        self.assertIn("registerRendererDiagnosticTexture(textureObject, image.get())", self.osg_patch)
        self.assertIn("openmw_ios_renderer_diag_register_gl_texture", self.osg_patch)
        self.assertIn('"r2.intent.apply"', self.openmw_runtime_patch)

    def test_gl4es_translation_unit_executes_app_bridge_and_writes_gl4es_r2_records(self) -> None:
        compiler = os.environ.get("CC") or shutil.which("cc") or shutil.which("clang") or shutil.which("gcc")
        if not compiler:
            self.skipTest("C compiler unavailable; set CC after entering the platform build environment")

        source = extract_added_file(self.gl4es_patch, "src/gl/ios_renderer_diag.c")
        header = extract_added_file(self.gl4es_patch, "src/gl/ios_renderer_diag.h")
        source = apply_file_patch(
            source, self.gl4es_observability_patch, "src/gl/ios_renderer_diag.c"
        )
        header = apply_file_patch(
            header, self.gl4es_observability_patch, "src/gl/ios_renderer_diag.h"
        )

        with tempfile.TemporaryDirectory() as directory:
            temp = pathlib.Path(directory)
            (temp / "ios_renderer_diag.c").write_text(source, encoding="utf-8")
            (temp / "ios_renderer_diag.h").write_text(header, encoding="utf-8")
            executable = temp / ("wo31-fixture.exe" if os.name == "nt" else "wo31-fixture")
            compiler_name = pathlib.Path(compiler).name.lower()
            if compiler_name in {"cl", "cl.exe"}:
                command = [
                    compiler, "/nologo", "/TC", "/DWO31_DIAGNOSTIC_TEST_BRIDGE=1",
                    f"/I{temp}", str(temp / "ios_renderer_diag.c"), str(BRIDGE_FIXTURE),
                    f"/Fe:{executable}",
                ]
            else:
                command = [
                    compiler, "-std=c11", "-DWO31_DIAGNOSTIC_TEST_BRIDGE=1", f"-I{temp}",
                    str(temp / "ios_renderer_diag.c"), str(BRIDGE_FIXTURE), "-o", str(executable),
                ]
            subprocess.run(command, check=True, capture_output=True, text=True)
            result = subprocess.run([str(executable)], check=True, capture_output=True, text=True)

        records = [json.loads(line) for line in result.stdout.splitlines()]
        self.assertEqual(sum(record["family"] == "handshake" for record in records), 1)
        self.assertTrue(any(record["source"] == "gl4es" for record in records))
        self.assertTrue(any(record["family"] == "r1.draw" for record in records))
        self.assertTrue(any(record["family"] == "r2.received" for record in records))
        applied = [record for record in records if record["family"] == "r2.applied"]
        self.assertEqual(len(applied), 1)
        self.assertIn("received_count=2", applied[0]["detail"])


if __name__ == "__main__":
    unittest.main()
