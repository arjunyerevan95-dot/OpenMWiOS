import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
PATCHED_HEADER = ROOT / "deps" / "openmw" / "files" / "shaders" / "lib" / "core" / "vertex.h.glsl"
BASELINE_LIBRARY = ROOT / "deps" / "openmw" / "files" / "shaders" / "lib" / "core" / "vertex.glsl"
DEBUG_VERTEX = ROOT / "deps" / "openmw" / "files" / "shaders" / "compatibility" / "debug.vert"

BASELINE_HEADER = """\
@link "lib/core/vertex.glsl" if !@useOVR_multiview
@link "lib/core/vertex_multiview.glsl" if @useOVR_multiview

vec4 modelToClip(vec4 pos);
vec4 modelToView(vec4 pos);
vec4 viewToClip(vec4 pos);
"""


def is_self_contained_vertex_header(source: str) -> bool:
    return (
        "@link" not in source
        and source.count("vec4 modelToClip(vec4 pos)\n{") == 1
        and source.count("vec4 modelToView(vec4 pos)\n{") == 1
        and source.count("vec4 viewToClip(vec4 pos)\n{") == 1
        and "uniform mat4 projectionMatrix;" in source
    )


class OpenMWModelToClipLinkageTests(unittest.TestCase):
    def test_baseline_header_requires_a_separate_vertex_library_unit(self) -> None:
        self.assertFalse(is_self_contained_vertex_header(BASELINE_HEADER))
        self.assertIn('@link "lib/core/vertex.glsl"', BASELINE_HEADER)
        self.assertIn("vec4 modelToClip(vec4 pos);", BASELINE_HEADER)

    def test_ios_header_is_self_contained_after_android_proven_adaptation(self) -> None:
        source = PATCHED_HEADER.read_text(encoding="utf-8")
        self.assertTrue(is_self_contained_vertex_header(source))

    def test_expanded_debug_unit_has_one_definition_before_main(self) -> None:
        header = PATCHED_HEADER.read_text(encoding="utf-8")
        entry = DEBUG_VERTEX.read_text(encoding="utf-8")
        include = '#include "lib/core/vertex.h.glsl"'
        self.assertIn(include, entry)
        expanded = entry.replace(include, header)
        definition = expanded.index("vec4 modelToClip(vec4 pos)\n{")
        main = expanded.index("void main()")
        first_reference = expanded.index("modelToClip( vec4", main)
        self.assertLess(definition, main)
        self.assertLess(main, first_reference)
        self.assertEqual(expanded.count("vec4 modelToClip(vec4 pos)\n{"), 1)
        self.assertNotIn("@link", expanded)

    def test_inlined_transform_math_matches_the_original_library(self) -> None:
        header = PATCHED_HEADER.read_text(encoding="utf-8")
        library = BASELINE_LIBRARY.read_text(encoding="utf-8")
        for body in (
            "return gl_ModelViewMatrix * pos;",
            "return projectionMatrix * modelToView(pos);",
            "return projectionMatrix * pos;",
        ):
            self.assertIn(body, library)
            self.assertIn(body, header)


if __name__ == "__main__":
    unittest.main()
