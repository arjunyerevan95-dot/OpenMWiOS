import pathlib
import re
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
OPENMW = ROOT / "deps" / "openmw"


class IosFullscreenScalingTests(unittest.TestCase):
    def test_fullscreen_scaling_uniform_uses_runtime_assignment(self) -> None:
        fullscreen_vertex = (
            OPENMW / "files" / "shaders" / "compatibility" / "fullscreen_tri.vert"
        ).read_text(encoding="utf-8")
        self.assertIn("uniform vec2 scaling;", fullscreen_vertex)
        self.assertNotRegex(
            fullscreen_vertex,
            re.compile(r"uniform\s+vec2\s+scaling\s*="),
        )

        pingpong = (
            OPENMW / "apps" / "openmw" / "mwrender" / "pingpongcanvas.cpp"
        ).read_text(encoding="utf-8")
        luminance = (
            OPENMW / "apps" / "openmw" / "mwrender" / "luminancecalculator.cpp"
        ).read_text(encoding="utf-8")
        self.assertIn('new osg::Uniform("scaling", osg::Vec2f(1, 1))', pingpong)
        self.assertIn('new osg::Uniform("scaling", mScale)', luminance)


if __name__ == "__main__":
    unittest.main()
