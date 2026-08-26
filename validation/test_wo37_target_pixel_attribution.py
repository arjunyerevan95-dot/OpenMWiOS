import pathlib
import re
import subprocess
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
BRIDGE = (ROOT / "ios" / "openmw_ios_renderer_diagnostics.mm").read_text(encoding="utf-8")
HEADER = (ROOT / "ios" / "openmw_ios_renderer_diagnostics.h").read_text(encoding="utf-8")
OSG_PATCH = (ROOT / "ios" / "patches" / "osg-route-gl-entry-points-through-gl4es.patch").read_text(
    encoding="utf-8"
)
GL4ES_PATCH = (ROOT / "patches" / "gl4es" / "0010-ios-target-pixel-attribution.patch").read_text(
    encoding="utf-8"
)
OPENMW_PATCH = (ROOT / "patches" / "openmw" / "0016-ios-renderer-diagnostics-target-pixel-present.patch").read_text(
    encoding="utf-8"
)


def patch_file_block(patch: str, path: str) -> str:
    marker = f"diff --git a/{path} b/{path}"
    start = patch.index(marker)
    end = patch.find("\ndiff --git ", start + len(marker))
    return patch[start:] if end < 0 else patch[start:end]


OSG_RENDER_LEAF_PATCH = patch_file_block(OSG_PATCH, "src/osgUtil/RenderLeaf.cpp")
OSG_RENDER_LEAF_FIXTURE = ROOT / "validation" / "fixtures" / "osg-01cc2b5-RenderLeaf.cpp"


class WO37TargetPixelAttributionTests(unittest.TestCase):
    def test_capture_is_request_gated_and_bounded(self) -> None:
        self.assertIn('renderer-target-request.txt', BRIDGE)
        self.assertIn('request.length <= 80', BRIDGE)
        self.assertIn('MaxFileBytes = 256 * 1024', BRIDGE)
        self.assertIn('TargetDrawBudget = 96', BRIDGE)
        self.assertIn('!sTargetRequest.empty()', BRIDGE)
        self.assertIn('sTargetCaptureArmed && !sTargetCaptureComplete', BRIDGE)

    def test_no_coverage_still_reaches_present_classification(self) -> None:
        self.assertIn('coverage-composition-candidate-no-osg-center-coverage', BRIDGE)
        self.assertIn('drawn-pixel-candidate', BRIDGE)
        self.assertIn('ambiguous-candidates-no-color-change', BRIDGE)
        self.assertIsNotNone(re.search(
            r'openmw_ios_renderer_diag_target_capture_active\(void\).*?sTargetCaptureArmed',
            BRIDGE,
            flags=re.DOTALL,
        ))
        self.assertIn('depth_sample=unsupported-gles2', BRIDGE)
        self.assertIn('sky_rtt_sample=not-observed-observer-only', BRIDGE)

    def test_osg_candidate_projection_and_cross_layer_correlation_exist(self) -> None:
        for token in (
            'src/osgUtil/RenderLeaf.cpp',
            'openmw_ios_renderer_diag_osg_draw_begin',
            'openmw_ios_renderer_diag_osg_draw_end',
            'minX > 0.0 || maxX < 0.0',
            'minY > 0.0 || maxY < 0.0',
            'drawable->getBoundingBox()',
            'leaf._projection',
            'leaf._modelview',
        ):
            self.assertIn(token, OSG_PATCH)
        self.assertIn('thread_local uint64_t sCurrentTargetDraw', BRIDGE)
        self.assertIn('openmw_ios_renderer_diag_current_osg_draw', HEADER)

    def test_gl4es_reads_only_one_target_pixel_before_and_after_direct_draw(self) -> None:
        reads = re.findall(r'gles_glReadPixels\([^;]+?\);', GL4ES_PATCH, flags=re.DOTALL)
        self.assertEqual(2, len(reads), reads)
        for read in reads:
            self.assertRegex(read, r',\s*1,\s*1,\s*GL_RGBA,\s*GL_UNSIGNED_BYTE')
        self.assertIn('wo37_diag_current_draw()', GL4ES_PATCH)
        self.assertIn('wo37_diag_draw_sample(wo37_draw, 0', GL4ES_PATCH)
        self.assertIn('wo37_diag_draw_sample(wo37_draw, 1', GL4ES_PATCH)
        self.assertNotIn('glReadPixels(0, 0, wo37_viewport[2]', GL4ES_PATCH)

    def test_osg_render_leaf_patch_applies_to_pristine_pinned_source(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            snapshot = pathlib.Path(directory)
            source = snapshot / "src" / "osgUtil" / "RenderLeaf.cpp"
            source.parent.mkdir(parents=True)
            source.write_bytes(OSG_RENDER_LEAF_FIXTURE.read_bytes())
            patch = snapshot / "wo37-render-leaf.patch"
            patch.write_text(OSG_RENDER_LEAF_PATCH, encoding="utf-8", newline="\n")
            subprocess.run(["git", "init", "-q"], cwd=snapshot, check=True)
            subprocess.run(["git", "config", "core.autocrlf", "false"], cwd=snapshot, check=True)
            subprocess.run(["git", "add", "-A"], cwd=snapshot, check=True)
            subprocess.run(
                ["git", "-c", "user.name=WO37", "-c", "user.email=wo37@example.invalid",
                 "commit", "-q", "-m", "pinned-render-leaf"],
                cwd=snapshot,
                check=True,
            )
            check = subprocess.run(
                ["git", "apply", "--check", str(patch)], cwd=snapshot,
                capture_output=True, text=True,
            )
            self.assertEqual(0, check.returncode, check.stderr)
            subprocess.run(["git", "apply", str(patch)], cwd=snapshot, check=True)
            materialized = source.read_text(encoding="utf-8")
        self.assertIn("beginTargetPixelDraw(*this, renderInfo)", materialized)
        self.assertEqual(2, materialized.count("endTargetPixelDraw(targetPixelDraw)"))

    def test_present_sample_is_after_pre_swap_and_is_one_pixel(self) -> None:
        pre_swap = OPENMW_PATCH.index('gl4es_pre_swap();')
        present = OPENMW_PATCH.index('openmw_ios_renderer_diag_present_sample')
        self.assertLess(pre_swap, present)
        self.assertRegex(
            OPENMW_PATCH,
            r'gNativeReadPixels\([^;]+?\n\+\s*1, 1, GL_RGBA, GL_UNSIGNED_BYTE, center\);',
        )

    def test_diagnostic_does_not_mutate_render_state(self) -> None:
        diagnostic_additions = '\n'.join(
            line[1:] for line in (OSG_RENDER_LEAF_PATCH + GL4ES_PATCH + OPENMW_PATCH).splitlines()
            if line.startswith('+') and not line.startswith('+++')
        )
        forbidden = (
            'glEnable(', 'glDisable(', 'glBlendFunc(', 'glDepthFunc(', 'glDepthMask(',
            'glCullFace(', 'glUseProgram(', 'glBindTexture(', 'glBindFramebuffer(', 'glClear(',
        )
        for token in forbidden:
            self.assertNotIn(token, diagnostic_additions)

    def test_render_list_without_osg_tls_remains_unattributed(self) -> None:
        self.assertIn('const uint64_t wo37_draw = wo37_diag_current_draw();', GL4ES_PATCH)
        self.assertIn('if (wo37_draw && wo37_diag_target_active()', GL4ES_PATCH)
        self.assertNotIn('diff --git a/src/gl/listdraw.c', GL4ES_PATCH)


if __name__ == "__main__":
    unittest.main()
