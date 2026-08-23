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
GL4ES_BASE = ROOT / "patches" / "gl4es" / "0006-ios-file-backed-renderer-diagnostics.patch"
GL4ES_OBSERVABILITY = ROOT / "patches" / "gl4es" / "0007-ios-renderer-diagnostics-observable-paths.patch"
GL4ES_TARGETED = ROOT / "patches" / "gl4es" / "0008-ios-renderer-diagnostics-targeted-boundaries.patch"
OPENMW_TARGETED = ROOT / "patches" / "openmw" / "0015-ios-renderer-diagnostics-targeted-boundaries.patch"
OSG_ROUTE = ROOT / "ios" / "patches" / "osg-route-gl-entry-points-through-gl4es.patch"
FIXTURE = ROOT / "validation" / "fixtures" / "wo32_gl4es_target_fixture.c"


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
    for chunk in re.split(r"(?=^@@ )", block, flags=re.MULTILINE):
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
            if line == "":
                assert original[cursor] == ""
                output.append(original[cursor])
                cursor += 1
            elif line.startswith(" "):
                assert original[cursor] == line[1:]
                output.append(original[cursor])
                cursor += 1
            elif line.startswith("-"):
                assert original[cursor] == line[1:]
                cursor += 1
            elif line.startswith("+"):
                output.append(line[1:])
    output.extend(original[cursor:])
    return "\n".join(output) + "\n"


class WorkOrder32TargetedRendererDiagnosticTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.bridge = BRIDGE.read_text(encoding="utf-8")
        cls.header = HEADER.read_text(encoding="utf-8")
        cls.gl4es_base = GL4ES_BASE.read_text(encoding="utf-8")
        cls.gl4es_observability = GL4ES_OBSERVABILITY.read_text(encoding="utf-8")
        cls.gl4es_targeted = GL4ES_TARGETED.read_text(encoding="utf-8")
        cls.openmw_targeted = OPENMW_TARGETED.read_text(encoding="utf-8")
        cls.osg_route = OSG_ROUTE.read_text(encoding="utf-8")

    def test_apply_file_patch_preserves_empty_blank_context(self) -> None:
        source = "alpha\n\nomega\n"
        patch = """diff --git a/fixture.txt b/fixture.txt
--- a/fixture.txt
+++ b/fixture.txt
@@ -1,3 +1,3 @@
 alpha

-omega
+beta
"""
        self.assertEqual(apply_file_patch(source, patch, "fixture.txt"), "alpha\n\nbeta\n")

    def test_bridge_classifies_only_named_targets_and_arms_miss_summaries(self) -> None:
        for token in ("moss", "fern", "leaf", "flora", "tree", "smoke"):
            self.assertIn(f'contains("{token}")', self.bridge)
        self.assertIn("OPENMW_IOS_RENDERER_TARGET_OPAQUE_CONTROL", self.bridge)
        self.assertIn("status=miss-until-first-applied-draw", self.bridge)
        self.assertIn("openmw_ios_renderer_diag_target_for_gl_name", self.bridge)

    def test_r1_sampling_is_target_gated_and_late(self) -> None:
        self.assertIn("if (wo32_target)", self.gl4es_targeted)
        self.assertIn("target <= 0 || target >= 4", self.gl4es_targeted)
        self.assertIn("wo32_target_hits[target] >= 4", self.gl4es_targeted)
        self.assertIn('"r1.draw.targeted"', self.gl4es_targeted)
        additions = "\n".join(
            line[1:] for line in self.gl4es_targeted.splitlines()
            if line.startswith("+") and not line.startswith("+++")
        )
        self.assertNotIn("if (wo31_category)", additions)
        for token in (
            "depth_test=", "depth_write=", "depth_func=", "fragment_has_discard=",
            "fragment_writes_alpha=", "has_fpe=", "default_fragment=",
        ):
            self.assertIn(token, self.gl4es_targeted)

    def test_r2_sampling_requires_complete_receipt_and_matching_exterior_intent(self) -> None:
        self.assertIn("wo32_fog_received_mask != 15u", self.gl4es_targeted)
        self.assertIn("openmw_ios_renderer_diag_matching_exterior_fog_generation", self.gl4es_targeted)
        self.assertIn('"r2.applied.targeted"', self.gl4es_targeted)
        self.assertIn("fog_locations=", self.gl4es_targeted)
        self.assertIn("generation=%u", self.gl4es_targeted)

    def test_openmw_records_projection_content_clear_and_targeted_shader_state(self) -> None:
        for family in ("r1.state.targeted", "r2.projection", "r2.content", "r2.clear"):
            self.assertIn(f'"{family}"', self.openmw_targeted)
        for token in (
            "camera_near=", "camera_far=", "terrain_cull=", "active_grid=",
            "clear_depth=", "sky_blending=", "alpha_to_coverage=", "adjust_coverage=",
        ):
            self.assertIn(token, self.openmw_targeted)
        self.assertIn("openmw_ios_renderer_diag_arm_exterior_fog", self.openmw_targeted)

    def test_targeted_diagnostics_do_not_mutate_renderer_state(self) -> None:
        additions = "\n".join(
            line[1:] for line in (self.gl4es_targeted + self.openmw_targeted).splitlines()
            if line.startswith("+") and not line.startswith("+++")
        )
        for token in (
            "gl4es_glEnable(", "gl4es_glDisable(", "gl4es_glBlendFunc(",
            "gl4es_glAlphaFunc(", "gles_gl", "glBindFramebuffer(", "glClear(", "glViewport(",
        ):
            self.assertNotIn(token, additions)

    def test_ios_osg_core_blend_state_uses_the_same_gl4es_owner_as_draws(self) -> None:
        self.assertIn("diff --git a/include/osg/State b/include/osg/State", self.osg_route)
        self.assertIn("extern \"C\" void gl4es_glEnable(GLenum cap);", self.osg_route)
        self.assertIn("extern \"C\" void gl4es_glDisable(GLenum cap);", self.osg_route)
        self.assertEqual(2, self.osg_route.count("if (enabled) gl4es_glEnable(mode);"))
        self.assertEqual(2, self.osg_route.count("else gl4es_glDisable(mode);"))
        self.assertIn("extern \"C\" void gl4es_glBlendFunc(GLenum sfactor, GLenum dfactor);", self.osg_route)
        self.assertIn("gl4es_glBlendFunc( _source_factor, _destination_factor );", self.osg_route)
        self.assertIn("+#else\n                 if (enabled) glEnable(mode);", self.osg_route)
        self.assertIn("+#else\n     glBlendFunc( _source_factor, _destination_factor );", self.osg_route)

    def test_gl4es_fixture_proves_target_and_two_generation_gates(self) -> None:
        compiler = os.environ.get("CC") or shutil.which("cc") or shutil.which("clang") or shutil.which("gcc")
        if not compiler:
            self.skipTest("C compiler unavailable")

        source = extract_added_file(self.gl4es_base, "src/gl/ios_renderer_diag.c")
        header = extract_added_file(self.gl4es_base, "src/gl/ios_renderer_diag.h")
        for patch in (self.gl4es_observability, self.gl4es_targeted):
            source = apply_file_patch(source, patch, "src/gl/ios_renderer_diag.c")
            header = apply_file_patch(header, patch, "src/gl/ios_renderer_diag.h")

        with tempfile.TemporaryDirectory() as directory:
            temp = pathlib.Path(directory)
            (temp / "ios_renderer_diag.c").write_text(source, encoding="utf-8")
            (temp / "ios_renderer_diag.h").write_text(header, encoding="utf-8")
            executable = temp / ("wo32-fixture.exe" if os.name == "nt" else "wo32-fixture")
            compiler_name = pathlib.Path(compiler).name.lower()
            if compiler_name in {"cl", "cl.exe"}:
                command = [compiler, "/nologo", "/TC", "/DWO31_DIAGNOSTIC_TEST_BRIDGE=1",
                    f"/I{temp}", str(temp / "ios_renderer_diag.c"), str(FIXTURE), f"/Fe:{executable}"]
            else:
                command = [compiler, "-std=c11", "-DWO31_DIAGNOSTIC_TEST_BRIDGE=1", f"-I{temp}",
                    str(temp / "ios_renderer_diag.c"), str(FIXTURE), "-lm", "-o", str(executable)]
            subprocess.run(command, check=True, capture_output=True, text=True)
            result = subprocess.run([str(executable)], check=True, capture_output=True, text=True)

        records = [json.loads(line) for line in result.stdout.splitlines()]
        targeted = [record for record in records if record["family"] == "r1.draw.targeted"]
        self.assertEqual({"1", "2", "3"}, {
            re.search(r"(?:^|;)target=(\d+)", record["detail"]).group(1) for record in targeted
        })
        self.assertLessEqual(sum("target=1" in record["detail"] for record in targeted), 4)
        self.assertFalse(any("texture=44" in record["detail"] for record in targeted))
        applied = [record for record in records if record["family"] == "r2.applied.targeted"]
        self.assertEqual(2, len(applied))
        self.assertTrue(any("generation=1" in record["detail"] for record in applied))
        self.assertTrue(any("generation=2" in record["detail"] for record in applied))


if __name__ == "__main__":
    unittest.main()
