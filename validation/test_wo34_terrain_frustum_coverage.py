import math
import pathlib
import re
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
PATCH_PATH = ROOT / "patches" / "openmw" / "0016-ios-cover-perspective-frustum-terrain.patch"


def terrain_view_distance(view_distance: float, vertical_fov_degrees: float, aspect: float) -> float:
    half_fov = math.radians(min(vertical_fov_degrees, 140.0)) / 2.0
    tangent = math.tan(half_fov)
    return view_distance * math.sqrt(1.0 + tangent * tangent * (1.0 + aspect * aspect))


def old_vertical_only_distance(view_distance: float, vertical_fov_degrees: float) -> float:
    half_fov = math.radians(min(vertical_fov_degrees, 140.0)) / 2.0
    return view_distance / math.cos(half_fov)


class WorkOrder34TerrainFrustumCoverageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.patch = PATCH_PATH.read_text(encoding="utf-8")

    def test_captured_landscape_projection_requires_full_corner_coverage(self) -> None:
        view_distance = 7168.0
        aspect = 2868.0 / 1320.0
        corrected = terrain_view_distance(view_distance, 60.0, aspect)
        self.assertAlmostEqual(old_vertical_only_distance(view_distance, 60.0), 8276.893459, places=5)
        self.assertAlmostEqual(corrected, 12221.207932, places=5)
        self.assertGreater(corrected, old_vertical_only_distance(view_distance, 60.0))

    def test_formula_covers_square_portrait_and_landscape_frustum_corners(self) -> None:
        for aspect in (3.0 / 4.0, 1.0, 4.0 / 3.0, 16.0 / 9.0, 2868.0 / 1320.0):
            with self.subTest(aspect=aspect):
                view_distance = 4096.0
                half_fov_tangent = math.tan(math.radians(60.0) / 2.0)
                far_half_height = view_distance * half_fov_tangent
                far_half_width = far_half_height * aspect
                corner_distance = math.sqrt(
                    view_distance * view_distance
                    + far_half_height * far_half_height
                    + far_half_width * far_half_width
                )
                self.assertAlmostEqual(
                    terrain_view_distance(view_distance, 60.0, aspect), corner_distance, places=9
                )

    def test_supported_fov_and_aspect_inputs_are_finite_monotonic_and_bounded(self) -> None:
        aspects = (0.5, 0.75, 1.0, 4.0 / 3.0, 16.0 / 9.0, 2868.0 / 1320.0, 4.0)
        previous = 0.0
        for aspect in aspects:
            distance = terrain_view_distance(7168.0, 60.0, aspect)
            self.assertTrue(math.isfinite(distance))
            self.assertGreaterEqual(distance, previous)
            previous = distance

        cap_bound = terrain_view_distance(7168.0, 140.0, max(aspects))
        for fov in (1.0, 30.0, 60.0, 90.0, 120.0, 140.0, 170.0):
            for aspect in aspects:
                with self.subTest(fov=fov, aspect=aspect):
                    distance = terrain_view_distance(7168.0, fov, aspect)
                    self.assertTrue(math.isfinite(distance))
                    self.assertGreaterEqual(distance, 7168.0)
                    self.assertLessEqual(distance, cap_bound)

    def test_patch_uses_one_runtime_formula_for_update_and_initialization(self) -> None:
        self.assertIn("float terrainViewDistanceForProjection(", self.patch)
        self.assertEqual(self.patch.count("terrainViewDistanceForProjection("), 3)
        self.assertIn(
            "terrainViewDistanceForProjection(mViewDistance, fov, aspect)", self.patch
        )
        self.assertIn("mFieldOfViewOverridden ? mFieldOfViewOverride : mFieldOfView", self.patch)
        self.assertIn("static_cast<double>(width) / height", self.patch)

    def test_patch_changes_only_rendering_manager_and_preserves_projection_fog_and_grid(self) -> None:
        changed_paths = re.findall(r"^diff --git a/(\S+) b/(\S+)$", self.patch, re.MULTILINE)
        self.assertEqual(
            changed_paths,
            [("apps/openmw/mwrender/renderingmanager.cpp", "apps/openmw/mwrender/renderingmanager.cpp")],
        )
        additions = "\n".join(
            line[1:]
            for line in self.patch.splitlines()
            if line.startswith("+") and not line.startswith("+++")
        )
        for forbidden in (
            "setFogStart",
            "setFogEnd",
            "setFogColor",
            "setClearColor",
            "setActiveGrid",
            "setProjectionMatrix",
            "mViewDistance =",
            "2868",
            "1320",
            "2.1727",
        ):
            self.assertNotIn(forbidden, additions)


if __name__ == "__main__":
    unittest.main()
