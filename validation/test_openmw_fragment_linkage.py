import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
HEADER = ROOT / "deps" / "openmw" / "files" / "shaders" / "lib" / "core" / "fragment.h.glsl"
LIBRARY = ROOT / "deps" / "openmw" / "files" / "shaders" / "lib" / "core" / "fragment.glsl"
FULLSCREEN = ROOT / "deps" / "openmw" / "files" / "shaders" / "compatibility" / "fullscreen_tri.frag"
OBJECTS = ROOT / "deps" / "openmw" / "files" / "shaders" / "compatibility" / "objects.frag"
RUNTIME_PATCH = ROOT / "patches" / "openmw" / "0009-ios-inline-core-fragment-helpers.patch"

# Provenance for the known-working architecture compared during Work Order 23:
# repository: https://gitlab.com/modding-openmw/openmw-android-docker
# release: 2.7.4; commit: 5b02e847dc646c9f10cd66001e4d65c5274dde49
# source path: patches/openmw/ng-gl4es.patch
ANDROID_REFERENCE = "openmw-android-docker/2.7.4@5b02e847:patches/openmw/ng-gl4es.patch"

BASELINE_HEADER = """\
#ifndef OPENMW_FRAGMENT_H_GLSL
#define OPENMW_FRAGMENT_H_GLSL

@link "lib/core/fragment.glsl" if !@useOVR_multiview
@link "lib/core/fragment_multiview.glsl" if @useOVR_multiview

vec4 samplerLastShader(vec2 uv);
#endif
"""


def expand_entry(entry: str, header: str) -> str:
    include = '#include "lib/core/fragment.h.glsl"'
    if include not in entry:
        raise AssertionError("entry shader does not include the core fragment header")
    return entry.replace(include, header)


class OpenMWFragmentLinkageTests(unittest.TestCase):
    def test_baseline_requires_a_separate_fragment_library_unit(self) -> None:
        self.assertIn('@link "lib/core/fragment.glsl"', BASELINE_HEADER)
        self.assertIn("vec4 samplerLastShader(vec2 uv);", BASELINE_HEADER)
        self.assertNotIn("vec4 samplerLastShader(vec2 uv)\n{", BASELINE_HEADER)

    def test_ios_header_is_self_contained(self) -> None:
        source = HEADER.read_text(encoding="utf-8")
        self.assertNotIn("@link", source)
        for signature in (
            "vec4 sampleReflectionMap(vec2 uv)\n{",
            "vec4 sampleRefractionMap(vec2 uv)\n{",
            "float sampleRefractionDepthMap(vec2 uv)\n{",
            "vec4 samplerLastShader(vec2 uv)\n{",
            "vec3 sampleSkyColor(vec2 uv)\n{",
            "vec4 sampleOpaqueDepthTex(vec2 uv)\n{",
        ):
            self.assertEqual(source.count(signature), 1)

    def test_fullscreen_entry_owns_main_and_sampler_definition(self) -> None:
        header = HEADER.read_text(encoding="utf-8")
        expanded = expand_entry(FULLSCREEN.read_text(encoding="utf-8"), header)
        definition = expanded.index("vec4 samplerLastShader(vec2 uv)\n{")
        main = expanded.index("void main()")
        reference = expanded.index("samplerLastShader(uv)", main)
        self.assertLess(definition, main)
        self.assertLess(main, reference)
        self.assertNotIn("@link", expanded)

    def test_object_entry_is_self_contained_and_keeps_main(self) -> None:
        header = HEADER.read_text(encoding="utf-8")
        expanded = expand_entry(OBJECTS.read_text(encoding="utf-8"), header)
        self.assertEqual(expanded.count("void main()"), 1)
        self.assertNotIn("@link", expanded)

    def test_inlined_sampling_semantics_match_original_library(self) -> None:
        header = HEADER.read_text(encoding="utf-8")
        library = LIBRARY.read_text(encoding="utf-8")
        for statement in (
            "return texture2D(reflectionMap, uv);",
            "return texture2D(refractionMap, uv);",
            "return texture2D(refractionDepthMap, uv).x;",
            "return texture2D(lastShader, uv);",
            "return texture2D(sky, uv).xyz;",
            "return texture2D(opaqueDepthTex, uv);",
        ):
            self.assertIn(statement, library)
            self.assertIn(statement, header)

    def test_runtime_patch_preserves_documented_android_fix_architecture(self) -> None:
        patch = RUNTIME_PATCH.read_text(encoding="utf-8")
        self.assertEqual(
            ANDROID_REFERENCE,
            "openmw-android-docker/2.7.4@5b02e847:patches/openmw/ng-gl4es.patch",
        )
        self.assertIn('-@link "lib/core/fragment.glsl"', patch)
        self.assertIn("+vec4 samplerLastShader(vec2 uv)", patch)
        self.assertIn("+    return texture2D(lastShader, uv);", patch)


if __name__ == "__main__":
    unittest.main()
