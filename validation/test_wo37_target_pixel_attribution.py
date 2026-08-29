import hashlib
import pathlib
import re
import subprocess
import tempfile
import unittest
import zipfile


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
PINNED_GL4ES_PATCH_INPUTS = (
    ROOT / "validation" / "fixtures" / "gl4es-c9895df-wo33-patch-inputs.zip"
)
PINNED_GL4ES_PATCH_INPUTS_SHA256 = (
    "1601090e10fda84c4e9b8343219deea1ad5c4398638005f22977e8f7e5c6bda6"
)


def patch_file_block(patch: str, path: str) -> str:
    marker = f"diff --git a/{path} b/{path}"
    start = patch.index(marker)
    end = patch.find("\ndiff --git ", start + len(marker))
    return patch[start:] if end < 0 else patch[start:end]


OSG_RENDER_LEAF_PATCH = patch_file_block(OSG_PATCH, "src/osgUtil/RenderLeaf.cpp")
OSG_RENDER_LEAF_FIXTURE = ROOT / "validation" / "fixtures" / "osg-01cc2b5-RenderLeaf.cpp"


class WO37TargetPixelAttributionTests(unittest.TestCase):
    def test_capture_is_first_exterior_gated_and_bounded(self) -> None:
        self.assertIn('renderer-target-request.txt', BRIDGE)
        self.assertIn('request.length <= 80', BRIDGE)
        self.assertIn('MaxFileBytes = 256 * 1024', BRIDGE)
        self.assertIn('TargetDrawBudget = 96', BRIDGE)
        self.assertIn('AutoFirstExteriorRequest = "wo37-auto-first-exterior"', BRIDGE)
        self.assertIn('sTargetCaptureArmed && !sTargetCaptureComplete', BRIDGE)

    def test_valid_explicit_request_remains_authoritative(self) -> None:
        explicit = BRIDGE.index('sTargetRequest = request.UTF8String;')
        explicit_source = BRIDGE.index('sTargetActivation = "explicit-request";', explicit)
        fallback_guard = BRIDGE.index('if (sTargetRequest.empty())', explicit_source)
        fallback_value = BRIDGE.index('sTargetRequest = AutoFirstExteriorRequest;', fallback_guard)
        self.assertLess(explicit, explicit_source)
        self.assertLess(explicit_source, fallback_guard)
        self.assertLess(fallback_guard, fallback_value)

    def test_missing_unreadable_empty_or_invalid_request_uses_fixed_fallback(self) -> None:
        self.assertIn('if (request && !requestError)', BRIDGE)
        self.assertIn('request.length > 0 && request.length <= 80', BRIDGE)
        self.assertRegex(
            BRIDGE,
            r'if \(sTargetRequest\.empty\(\)\)\s*\{\s*'
            r'sTargetRequest = AutoFirstExteriorRequest;\s*'
            r'sTargetActivation = "auto-first-exterior";',
        )
        self.assertIn('target_activation=%@', BRIDGE)
        self.assertIn('activation=%s;generation=%u;target_ndc=0,0', BRIDGE)

    def test_fallback_arms_only_first_eligible_exterior_and_completes_once(self) -> None:
        arm_function = re.search(
            r'openmw_ios_renderer_diag_arm_exterior_fog\(.*?\n\}',
            BRIDGE,
            flags=re.DOTALL,
        )
        self.assertIsNotNone(arm_function)
        arm_source = arm_function.group(0)
        self.assertIn('if (!changed)', arm_source)
        self.assertIn('return;', arm_source)
        self.assertIn('!sTargetCaptureComplete && !sTargetCaptureArmed', arm_source)
        self.assertEqual(1, arm_source.count('sTargetCaptureArmed = true;'))
        self.assertIsNotNone(re.search(
            r'openmw_ios_renderer_diag_present_sample\(.*?'
            r'sTargetCaptureComplete = true;.*?sTargetCaptureArmed = false;',
            BRIDGE,
            flags=re.DOTALL,
        ))

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

    def test_gl4es_readback_uses_the_native_loader_contract(self) -> None:
        self.assertIn('LOAD_GLES(glReadPixels);', GL4ES_PATCH)
        self.assertNotIn('LOAD_GLES_FPE(glReadPixels)', GL4ES_PATCH)
        self.assertNotIn('fpe_glReadPixels', GL4ES_PATCH)

    def test_complete_gl4es_patch_stack_applies_to_pristine_pinned_snapshot(self) -> None:
        self.assertEqual(
            PINNED_GL4ES_PATCH_INPUTS_SHA256,
            hashlib.sha256(PINNED_GL4ES_PATCH_INPUTS.read_bytes()).hexdigest(),
        )
        patches = sorted((ROOT / "patches" / "gl4es").glob("*.patch"))
        self.assertEqual(
            [f"{index:04d}" for index in range(1, 11)],
            [patch.name.split("-", 1)[0] for patch in patches],
        )
        with tempfile.TemporaryDirectory() as directory:
            snapshot = pathlib.Path(directory)
            with zipfile.ZipFile(PINNED_GL4ES_PATCH_INPUTS) as archive:
                archive.extractall(snapshot)
            for source in snapshot.rglob("*"):
                if source.is_file():
                    source.write_bytes(source.read_bytes().replace(b"\r\n", b"\n"))
            subprocess.run(["git", "init", "-q"], cwd=snapshot, check=True)
            subprocess.run(["git", "config", "core.autocrlf", "false"], cwd=snapshot, check=True)
            subprocess.run(["git", "add", "-A"], cwd=snapshot, check=True)
            subprocess.run(
                ["git", "-c", "user.name=WO37", "-c", "user.email=wo37@example.invalid",
                 "commit", "-q", "-m", "pinned-c9895df-patch-inputs"],
                cwd=snapshot,
                check=True,
            )
            for patch in patches:
                normalized_patch = snapshot / f".wo37-{patch.name}"
                normalized_patch.write_text(
                    patch.read_text(encoding="utf-8"),
                    encoding="utf-8",
                    newline="\n",
                )
                check = subprocess.run(
                    ["git", "apply", "--check", str(normalized_patch)],
                    cwd=snapshot,
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(
                    0,
                    check.returncode,
                    f"{patch.name} failed clean-tree validation:\n{check.stderr}",
                )
                subprocess.run(
                    ["git", "apply", str(normalized_patch)],
                    cwd=snapshot,
                    check=True,
                    capture_output=True,
                    text=True,
                )
            subprocess.run(
                ["git", "diff", "--check"],
                cwd=snapshot,
                check=True,
                capture_output=True,
                text=True,
            )
            drawing = (snapshot / "src" / "gl" / "drawing.c").read_text(encoding="utf-8")
        self.assertIn('LOAD_GLES(glReadPixels);', drawing)
        self.assertNotIn('LOAD_GLES_FPE(glReadPixels)', drawing)
        self.assertNotIn('fpe_glReadPixels', drawing)

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
