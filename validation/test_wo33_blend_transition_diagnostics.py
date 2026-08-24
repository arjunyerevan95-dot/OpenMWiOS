import hashlib
import os
import pathlib
import re
import shutil
import subprocess
import tempfile
import unittest
import zipfile


ROOT = pathlib.Path(__file__).resolve().parents[1]
BRIDGE = ROOT / "ios" / "openmw_ios_renderer_diagnostics.mm"
HEADER = ROOT / "ios" / "openmw_ios_renderer_diagnostics.h"
OSG_ROUTE = ROOT / "ios" / "patches" / "osg-route-gl-entry-points-through-gl4es.patch"
OSG_PATCH_DRIVER = ROOT / "ios" / "cmake" / "apply-osg-patch.cmake"
GL4ES_BASE = ROOT / "patches" / "gl4es" / "0006-ios-file-backed-renderer-diagnostics.patch"
GL4ES_OBSERVABILITY = ROOT / "patches" / "gl4es" / "0007-ios-renderer-diagnostics-observable-paths.patch"
GL4ES_TARGETED = ROOT / "patches" / "gl4es" / "0008-ios-renderer-diagnostics-targeted-boundaries.patch"
GL4ES_TRANSITIONS = ROOT / "patches" / "gl4es" / "0009-ios-blend-transition-diagnostics.patch"
TRANSITION_FIXTURE = ROOT / "validation" / "fixtures" / "wo33_blend_transition_fixture.c"
PINNED_PATCH_INPUTS = (
    ROOT / "validation" / "fixtures" / "gl4es-c9895df-wo33-patch-inputs.zip"
)
PINNED_PATCH_INPUTS_SHA256 = "1601090e10fda84c4e9b8343219deea1ad5c4398638005f22977e8f7e5c6bda6"
OSG_PINNED_REVISION = "01cc2b585c8456a4ff843066b7e1a8715558289f"
OSG_PINNED_PATCH_INPUTS = (
    ROOT / "validation" / "fixtures" / "osg-01cc2b5-wo33-patch-inputs.zip"
)
OSG_PINNED_PATCH_INPUTS_SHA256 = (
    "91f3e31c4bd6999162f91c0ed1acdebfe889902d7e79d16cecf505392020409e"
)
OSG_PATCHED_FILE_SHA256 = {
    "include/osg/State": "92a5051cb05c3b773c1e54f1baaa4cdc5be96f80b75910bb17d20aa4ba49e602",
    "src/osg/GLExtensions.cpp": "47cbf5fe3c077e92dca7b2dbfec1c8f3bafe1d43ec5cc1837aee4ceeab6dfee1",
    "src/osg/BlendFunc.cpp": "4d79247a631be73f7c859cd6038ff3199ef5f0ef4a2fd0bfaffa7f80b7f8b7e8",
    "src/osg/Texture2D.cpp": "678460b5e6b097b26cccab1d7f478d9de3b27eb3edf6bae01c770c1dff495229",
}


def extract_added_file(patch: str, path: str) -> str:
    marker = f"diff --git a/{path} b/{path}"
    block = patch.split(marker, 1)[1].split("\ndiff --git ", 1)[0]
    return "\n".join(
        line[1:] for line in block.splitlines() if line.startswith("+") and not line.startswith("+++")
    ) + "\n"


# GL4ES-only source reconstruction helper. It is deliberately not an OSG patch
# parser; the pristine-input real-parser test below is authoritative for OSG.
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


def classify_transition(events):
    osg_enable = next((event for event in events if event[0] == "osg" and event[1] == 1), None)
    gl_enable = next((event for event in events if event[0] == "gl4es" and event[1] == 1), None)
    common = next((event for event in events if event[0] == "common"), None)
    if osg_enable and not gl_enable:
        return "route-not-exercised"
    if gl_enable and common and gl_enable[2] != common[2]:
        return "different-context"
    if gl_enable and common and gl_enable[1] == 1 and common[1] == 0:
        if any(event[0] == "replay" for event in events):
            return "render-list-replay"
        return "later-disable"
    return "consistent"


class WorkOrder33BlendTransitionDiagnosticTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.bridge = BRIDGE.read_text(encoding="utf-8")
        cls.header = HEADER.read_text(encoding="utf-8")
        cls.osg = OSG_ROUTE.read_text(encoding="utf-8")
        cls.base = GL4ES_BASE.read_text(encoding="utf-8")
        cls.observable = GL4ES_OBSERVABILITY.read_text(encoding="utf-8")
        cls.targeted = GL4ES_TARGETED.read_text(encoding="utf-8")
        cls.transitions = GL4ES_TRANSITIONS.read_text(encoding="utf-8")

    def test_bridge_is_dynamically_armed_and_hard_bounded(self) -> None:
        self.assertIn("sTargetArmed[OPENMW_IOS_RENDERER_TARGET_CHIMNEY_SMOKE]", self.bridge)
        self.assertIn("BlendRingCapacity = 48", self.bridge)
        self.assertIn("sBlendRing.size() > BlendRingCapacity", self.bridge)
        self.assertIn('safeSite == "glDrawElementsCommon"', self.bridge)
        self.assertIn('safeSite == "draw_renderlist.native-draw"', self.bridge)
        self.assertIn('family == "r1.blend.transition"', self.bridge)
        self.assertRegex(self.bridge, r'family == "r1\.blend\.transition"\)\s*return 128;')
        self.assertIn("MaxFileBytes = 256 * 1024", self.bridge)

    def test_bridge_adds_total_order_and_thread_identity(self) -> None:
        for token in ("sBlendSequence", "std::this_thread::get_id()", "sequence=%llu", "thread=%llu"):
            self.assertIn(token, self.bridge)
        self.assertIn("openmw_ios_renderer_diag_blend_event", self.header)

    def test_osg_records_cache_decision_context_site_and_route(self) -> None:
        for token in (
            "State::applyMode", "State::applyModeOnTexUnit", "requested=%d", "valid=%d",
            "last=%d", "issued=%d", "state=%p", "context=%u", "route=manual-gl4es",
        ):
            self.assertIn(token, self.osg)
        self.assertEqual(2, self.osg.count("if (enabled) gl4es_glEnable(mode);"))
        self.assertEqual(2, self.osg.count("else gl4es_glDisable(mode);"))

    def test_osg_blend_func_records_factors_and_uses_manual_route(self) -> None:
        self.assertIn("BlendFunc::apply", self.osg)
        self.assertIn("src_rgb=%u;dst_rgb=%u;src_alpha=%u;dst_alpha=%u", self.osg)
        self.assertIn("gl4es_glBlendFunc( _source_factor, _destination_factor );", self.osg)

    def test_gl4es_ingress_records_previous_new_context_list_and_forwarding(self) -> None:
        for token in (
            "proxy_glEnable(GL_BLEND)", "requested=%d", "previous=%d", "current=%d",
            "changed=%d", "glstate=%p", "active_list=%p", "list_pending=%d",
            "fpe_state=%p", "shaderblend=%d", "native_forwarded=%d",
        ):
            self.assertIn(token, self.transitions)

    def test_draw_path_distinguishes_intake_capture_intercept_common_and_replay(self) -> None:
        for site in (
            "glDrawElements.intake", "glDrawElements.capture", "glDrawElements.intercept",
            "glDrawArrays.intake", "glDrawArrays.capture", "glDrawArrays.intercept",
            "glDrawElementsCommon", "draw_renderlist.native-draw",
        ):
            self.assertIn(site, self.transitions)
        self.assertIn("replay_list=%p", self.transitions)

    def test_draw_phase_is_bound_to_runtime_discovered_smoke_target(self) -> None:
        self.assertIn("wo32_diag_texture_target_for_name(texture->texture) == 2", self.transitions)
        self.assertNotIn("texture == 2", self.transitions)
        self.assertNotRegex(self.transitions, r"texture->texture\s*==\s*\d+")

    def test_diagnostics_preserve_original_gl4es_blend_transition_semantics(self) -> None:
        self.assertEqual(1, self.transitions.count("+                glstate->enable.blend = enable;"))
        self.assertIn("if(changed) {", self.transitions)
        self.assertIn("if(glstate->fpe_state && globals4es.shaderblend)", self.transitions)
        self.assertIn("} else next(cap);", self.transitions)
        for forbidden in ("gl4es_glBlendFunc(", "gl4es_glAlphaFunc(", "glClear(", "glViewport("):
            self.assertNotIn(forbidden, self.transitions)

    def test_transition_model_separates_all_ordered_alternatives(self) -> None:
        self.assertEqual("route-not-exercised", classify_transition([
            ("osg", 1, "A"), ("common", 0, "A")]))
        self.assertEqual("later-disable", classify_transition([
            ("osg", 1, "A"), ("gl4es", 1, "A"), ("common", 0, "A")]))
        self.assertEqual("different-context", classify_transition([
            ("osg", 1, "A"), ("gl4es", 1, "A"), ("common", 0, "B")]))
        self.assertEqual("render-list-replay", classify_transition([
            ("osg", 1, "A"), ("gl4es", 1, "A"), ("replay", 0, "A"), ("common", 0, "A")]))
        self.assertEqual("consistent", classify_transition([
            ("osg", 1, "A"), ("gl4es", 1, "A"), ("common", 1, "A")]))

    def test_complete_gl4es_patch_stack_applies_to_pristine_pinned_snapshot(self) -> None:
        self.assertEqual(
            PINNED_PATCH_INPUTS_SHA256,
            hashlib.sha256(PINNED_PATCH_INPUTS.read_bytes()).hexdigest(),
        )
        patches = sorted((ROOT / "patches" / "gl4es").glob("*.patch"))
        self.assertEqual(
            [f"{index:04d}" for index in range(1, 10)],
            [patch.name.split("-", 1)[0] for patch in patches],
        )
        with tempfile.TemporaryDirectory() as directory:
            snapshot = pathlib.Path(directory)
            with zipfile.ZipFile(PINNED_PATCH_INPUTS) as archive:
                archive.extractall(snapshot)
            for source in snapshot.rglob("*"):
                if source.is_file():
                    source.write_bytes(source.read_bytes().replace(b"\r\n", b"\n"))
            subprocess.run(["git", "init", "-q"], cwd=snapshot, check=True)
            subprocess.run(["git", "config", "core.autocrlf", "false"], cwd=snapshot, check=True)
            subprocess.run(["git", "add", "-A"], cwd=snapshot, check=True)
            subprocess.run(
                ["git", "-c", "user.name=WO33", "-c", "user.email=wo33@example.invalid",
                    "commit", "-q", "-m", "pinned-c9895df-patch-inputs"],
                cwd=snapshot,
                check=True,
            )
            for patch in patches:
                normalized_patch = snapshot / f".wo33-{patch.name}"
                normalized_patch.write_text(
                    patch.read_text(encoding="utf-8"),
                    encoding="utf-8",
                    newline="\n",
                )
                check_result = subprocess.run(
                    ["git", "apply", "--check", str(normalized_patch)],
                    cwd=snapshot,
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(
                    0,
                    check_result.returncode,
                    f"{patch.name} failed clean-tree validation:\n{check_result.stderr}",
                )
                subprocess.run(
                    ["git", "apply", str(normalized_patch)],
                    cwd=snapshot,
                    check=True,
                    capture_output=True,
                    text=True,
                )
            subprocess.run(
                ["git", "diff", "--check"], cwd=snapshot, check=True, capture_output=True, text=True
            )
            drawing = (snapshot / "src" / "gl" / "drawing.c").read_text(encoding="utf-8")
            enable = (snapshot / "src" / "gl" / "enable.c").read_text(encoding="utf-8")
            replay = (snapshot / "src" / "gl" / "listdraw.c").read_text(encoding="utf-8")
        self.assertIn('wo33_diag_draw_phase("glDrawElementsCommon", mode, count);', drawing)
        self.assertIn('wo33_diag_blend_event("proxy_glEnable(GL_BLEND)", wo33_detail);', enable)
        self.assertIn('wo33_diag_replay_phase("draw_renderlist.native-draw", list, mode,', replay)

    def test_osg_patch_materializes_with_real_parsers_on_pristine_pinned_inputs(self) -> None:
        """The custom GL4ES source reconstructor is not authoritative for this OSG patch."""
        self.assertEqual(
            OSG_PINNED_PATCH_INPUTS_SHA256,
            hashlib.sha256(OSG_PINNED_PATCH_INPUTS.read_bytes()).hexdigest(),
        )
        self.assertNotIn(b"\r", OSG_ROUTE.read_bytes())
        patch_driver = OSG_PATCH_DRIVER.read_text(encoding="utf-8")
        for token in ("/usr/bin/patch", "-N", "-f", "-p1", "-i"):
            self.assertIn(token, patch_driver)

        with tempfile.TemporaryDirectory() as directory:
            snapshot = pathlib.Path(directory)
            with zipfile.ZipFile(OSG_PINNED_PATCH_INPUTS) as archive:
                archive.extractall(snapshot)
            subprocess.run(["git", "init", "-q"], cwd=snapshot, check=True)
            subprocess.run(["git", "config", "core.autocrlf", "false"], cwd=snapshot, check=True)
            subprocess.run(["git", "add", "-A"], cwd=snapshot, check=True)
            subprocess.run(
                ["git", "-c", "user.name=WO33", "-c", "user.email=wo33@example.invalid",
                    "commit", "-q", "-m", f"pinned-osg-{OSG_PINNED_REVISION}"],
                cwd=snapshot,
                check=True,
            )

            parse_result = subprocess.run(
                ["git", "apply", "--check", str(OSG_ROUTE)],
                cwd=snapshot,
                capture_output=True,
                text=True,
            )
            self.assertEqual(0, parse_result.returncode, parse_result.stderr)

            production_patch = pathlib.Path("/usr/bin/patch")
            if production_patch.is_file():
                materialize_command = [
                    str(production_patch), "-N", "-f", "-p1", "-i", str(OSG_ROUTE)
                ]
            else:
                # Windows developer hosts lack /usr/bin/patch. Git applies the already-checked
                # blob locally; macOS CI must and does exercise the exact production command.
                self.assertNotEqual("macOS", os.environ.get("RUNNER_OS"))
                materialize_command = ["git", "apply", str(OSG_ROUTE)]
            materialize_result = subprocess.run(
                materialize_command,
                cwd=snapshot,
                capture_output=True,
                text=True,
            )
            self.assertEqual(0, materialize_result.returncode, materialize_result.stderr)

            actual_hashes = {
                path: hashlib.sha256((snapshot / path).read_bytes()).hexdigest()
                for path in OSG_PATCHED_FILE_SHA256
            }
            self.assertEqual(OSG_PATCHED_FILE_SHA256, actual_hashes)

            status = subprocess.run(
                ["git", "status", "--short"], cwd=snapshot, check=True,
                capture_output=True, text=True
            ).stdout.splitlines()
            self.assertEqual(4, len(status), status)
            self.assertTrue(all(line.startswith(" M ") for line in status), status)

    def test_compiled_transition_fixture_covers_ordered_alternatives(self) -> None:
        compiler = os.environ.get("CC") or shutil.which("cc") or shutil.which("clang") or shutil.which("gcc")
        if not compiler:
            self.skipTest("C compiler unavailable")
        with tempfile.TemporaryDirectory() as directory:
            executable = pathlib.Path(directory) / ("wo33-model.exe" if os.name == "nt" else "wo33-model")
            compiler_name = pathlib.Path(compiler).name.lower()
            if compiler_name in {"cl", "cl.exe"}:
                command = [compiler, "/nologo", "/TC", str(TRANSITION_FIXTURE), f"/Fe:{executable}"]
            else:
                command = [compiler, "-std=c11", str(TRANSITION_FIXTURE), "-o", str(executable)]
            subprocess.run(command, check=True, capture_output=True, text=True)
            result = subprocess.run([str(executable)], check=True, capture_output=True, text=True)
        self.assertEqual([
            "enable-only=consistent",
            "enable-disable=later-disable",
            "different-context=different-context",
            "render-list=render-list-replay",
            "missing-route=route-not-exercised",
        ], result.stdout.splitlines())

    def test_gl4es_bridge_symbol_is_linked_and_invoked(self) -> None:
        compiler = os.environ.get("CC") or shutil.which("cc") or shutil.which("clang") or shutil.which("gcc")
        if not compiler:
            self.skipTest("C compiler unavailable")

        source = extract_added_file(self.base, "src/gl/ios_renderer_diag.c")
        header = extract_added_file(self.base, "src/gl/ios_renderer_diag.h")
        for patch in (self.observable, self.targeted, self.transitions):
            source = apply_file_patch(source, patch, "src/gl/ios_renderer_diag.c")
            header = apply_file_patch(header, patch, "src/gl/ios_renderer_diag.h")
        fixture = r'''
#include <stdint.h>
#include <stdio.h>
#include "ios_renderer_diag.h"
int openmw_ios_renderer_diag_enabled(void) { return 1; }
unsigned int openmw_ios_renderer_diag_record(const char*a,const char*b,const char*c,const char*d)
{ (void)a; (void)b; (void)c; (void)d; return 1; }
int openmw_ios_renderer_diag_texture_category(uint64_t h) { return h ? 1 : 0; }
int openmw_ios_renderer_diag_texture_category_for_gl_name(unsigned int t) { return t ? 1 : 0; }
int openmw_ios_renderer_diag_target_for_gl_name(unsigned int t) { return t ? 2 : 0; }
unsigned int openmw_ios_renderer_diag_matching_exterior_fog_generation(float a,float b,const float*c)
{ (void)a; (void)b; (void)c; return 0; }
uint64_t openmw_ios_renderer_diag_hash(const void* p, size_t n) { (void)p; return n; }
void openmw_ios_renderer_diag_blend_event(const char* source,const char* site,const char* detail)
{ printf("%s|%s|%s\n", source, site, detail); }
int main(void) { wo33_diag_blend_event("fixture", "current=1"); return 0; }
'''
        with tempfile.TemporaryDirectory() as directory:
            temp = pathlib.Path(directory)
            (temp / "ios_renderer_diag.c").write_text(source, encoding="utf-8")
            (temp / "ios_renderer_diag.h").write_text(header, encoding="utf-8")
            (temp / "fixture.c").write_text(fixture, encoding="utf-8")
            executable = temp / ("wo33-fixture.exe" if os.name == "nt" else "wo33-fixture")
            compiler_name = pathlib.Path(compiler).name.lower()
            if compiler_name in {"cl", "cl.exe"}:
                command = [compiler, "/nologo", "/TC", "/DWO31_DIAGNOSTIC_TEST_BRIDGE=1",
                    f"/I{temp}", str(temp / "ios_renderer_diag.c"), str(temp / "fixture.c"), f"/Fe:{executable}"]
            else:
                command = [compiler, "-std=c11", "-DWO31_DIAGNOSTIC_TEST_BRIDGE=1", f"-I{temp}",
                    str(temp / "ios_renderer_diag.c"), str(temp / "fixture.c"), "-o", str(executable)]
            subprocess.run(command, check=True, capture_output=True, text=True)
            result = subprocess.run([str(executable)], check=True, capture_output=True, text=True)
        self.assertEqual("gl4es|fixture|current=1", result.stdout.strip())


if __name__ == "__main__":
    unittest.main()
