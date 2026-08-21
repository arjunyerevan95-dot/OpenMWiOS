import json
import math
import pathlib
import re
import shutil
import subprocess
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
MODEL = ROOT / "ios" / "openmw_ios_touch_model.hpp"
ADAPTER = ROOT / "ios" / "openmw_ios_touch_controls.mm"
PATCH = ROOT / "patches" / "openmw" / "0012-ios-android-derived-touch-controls.patch"
REFERENCE = ROOT / "validation" / "fixtures" / "android-touch-2.7.4-reference.json"


def clamp(value: float, minimum: float, maximum: float) -> float:
    return max(minimum, min(value, maximum))


def make_layout(width: float, height: float, safe=(0.0, 0.0, 0.0, 0.0)):
    top, left, bottom, right_inset = safe
    short_side = min(width, height)
    edge = clamp(short_side * 0.035, 12.0, 28.0)
    stick_radius = clamp(short_side * 0.17, 54.0, 96.0)
    button_radius = clamp(short_side * 0.075, 24.0, 42.0)
    step = button_radius * 2.0 + clamp(short_side * 0.025, 8.0, 18.0)
    movement = (left + edge + stick_radius, height - bottom - edge - stick_radius, stick_radius)
    right = width - right_inset - edge - button_radius
    lower = height - bottom - edge - button_radius
    offsets = ((0, 0), (-step, 0), (0, -step), (-step, -step), (-2 * step, -step),
               (0, -2 * step), (-step, -2 * step), (-2 * step, -2 * step))
    buttons = tuple((right + dx, lower + dy, button_radius) for dx, dy in offsets)
    return {"movement": movement, "buttons": buttons, "look_boundary": width * 0.38,
            "safe": (top, left, bottom, right_inset)}


def movement_vector(radius: float, dx: float, dy: float, dead_zone: float = 0.2):
    raw_x, raw_y = dx / radius, dy / radius
    raw_magnitude = math.hypot(raw_x, raw_y)
    if raw_magnitude <= dead_zone:
        return 0.0, 0.0, 0.0
    magnitude = clamp((raw_magnitude - dead_zone) / (1.0 - dead_zone), 0.0, 1.0)
    return raw_x / raw_magnitude * magnitude, raw_y / raw_magnitude * magnitude, magnitude


class IosTouchControlTests(unittest.TestCase):
    def assert_layout_inside_safe_area(self, width, height, safe):
        layout = make_layout(width, height, safe)
        top, left, bottom, right = safe
        for x, y, radius in (layout["movement"], *layout["buttons"]):
            self.assertGreaterEqual(x - radius, left - 0.01)
            self.assertLessEqual(x + radius, width - right + 0.01)
            self.assertGreaterEqual(y - radius, top - 0.01)
            self.assertLessEqual(y + radius, height - bottom + 0.01)

    def test_android_reference_is_pinned_and_minimal(self):
        reference = json.loads(REFERENCE.read_text(encoding="utf-8"))
        self.assertEqual(reference["tag"], "2.7.4")
        self.assertEqual(reference["commit"], "5b02e847dc646c9f10cd66001e4d65c5274dde49")
        self.assertEqual(reference["native_bridge_path"], "patches/openmw/androidmain.cpp")
        self.assertEqual(reference["default_android_keycodes"]["inventory"], 30)

    def test_iphone_landscape_layout_respects_safe_area(self):
        self.assert_layout_inside_safe_area(956, 440, (0, 62, 21, 62))

    def test_ipad_landscape_layout_respects_safe_area(self):
        self.assert_layout_inside_safe_area(1366, 1024, (24, 0, 20, 0))

    def test_arbitrary_landscape_layout_respects_safe_area(self):
        self.assert_layout_inside_safe_area(1180, 820, (13, 37, 29, 11))

    def test_layout_recomputes_for_orientation_and_size(self):
        landscape = make_layout(1180, 820, (13, 37, 29, 11))
        alternate = make_layout(820, 1180, (37, 13, 11, 29))
        self.assertNotEqual(landscape["movement"], alternate["movement"])
        self.assertNotEqual(landscape["buttons"], alternate["buttons"])

    def test_dead_zone_analog_magnitude_and_clamp(self):
        self.assertEqual(movement_vector(80, 8, 8), (0.0, 0.0, 0.0))
        x, y, magnitude = movement_vector(80, 40, 0)
        self.assertAlmostEqual(x, 0.375)
        self.assertAlmostEqual(y, 0.0)
        self.assertAlmostEqual(magnitude, 0.375)
        x, y, magnitude = movement_vector(80, 400, 0)
        self.assertEqual((x, y, magnitude), (1.0, 0.0, 1.0))

    def test_touch_ids_have_sticky_independent_ownership(self):
        model = MODEL.read_text(encoding="utf-8")
        self.assertIn("std::unordered_map<std::uintptr_t, Binding>", model)
        self.assertIn("Role::Movement", model)
        self.assertIn("Role::Look", model)
        self.assertIn("Role::Button", model)
        self.assertIn("found->second.lastPoint = point", model)
        self.assertNotIn("mBindings.clear();\n            return add", model)

    def test_gui_mode_is_true_passthrough_and_cleanup_is_explicit(self):
        adapter = ADAPTER.read_text(encoding="utf-8")
        self.assertIn("return _gameplayMode;", adapter)
        self.assertIn("SDL_ShowCursor(SDL_QUERY) == SDL_DISABLE", adapter)
        self.assertIn("[self releaseAllInputs]", adapter)
        self.assertIn('mode=gui;controls=passthrough', adapter)

    def test_public_sdl_paths_preserve_external_input_architecture(self):
        adapter = ADAPTER.read_text(encoding="utf-8")
        self.assertIn("SDL_JoystickAttachVirtualEx", adapter)
        self.assertIn("SDL_JoystickSetVirtualAxis", adapter)
        self.assertIn("SDL_PushEvent", adapter)
        self.assertNotIn("SDL_SendMouseMotion", adapter)
        self.assertNotIn("SDL_SendKeyboardKey", adapter)

    def test_android_action_semantics_are_preserved(self):
        adapter = ADAPTER.read_text(encoding="utf-8")
        mappings = {
            "Activate": "SDL_SCANCODE_SPACE",
            "Attack": "SDL_SCANCODE_Z",
            "Jump": "SDL_SCANCODE_E",
            "ReadyWeapon": "SDL_SCANCODE_F",
            "ReadyMagic": "SDL_SCANCODE_R",
            "Inventory": "SDL_SCANCODE_B",
            "Pause": "SDL_SCANCODE_ESCAPE",
            "Sneak": "SDL_SCANCODE_LCTRL",
        }
        for action, scancode in mappings.items():
            self.assertRegex(adapter, rf"case Action::{action}:\s+return {scancode};")

    def test_layout_and_adapter_have_no_current_device_dimensions(self):
        source = MODEL.read_text(encoding="utf-8") + ADAPTER.read_text(encoding="utf-8")
        self.assertNotRegex(source, re.compile(r"\b(?:956|440|2868|1320)\b"))
        self.assertIn("self.safeAreaInsets", source)
        self.assertIn("UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight", source)

    def test_diagnostics_are_bounded(self):
        adapter = ADAPTER.read_text(encoding="utf-8")
        self.assertIn("constexpr int DiagnosticBudget = 48", adapter)
        self.assertIn("if (_diagnosticBudget <= 0)", adapter)
        self.assertNotIn("openmw_ios_log(\"touch_move\"", adapter)

    def test_openmw_patch_integrates_only_ios_touch_adapter(self):
        patch = PATCH.read_text(encoding="utf-8")
        self.assertIn("openmw_ios_touch_controls.mm", patch)
        self.assertIn("openmw_ios_install_touch_controls();", patch)
        self.assertNotIn("GL4ES", patch)
        self.assertNotIn("renderWidth", patch)
        self.assertNotIn("mResolution", patch)

    def test_header_compiles_and_multitouch_roles_are_independent_when_compiler_available(self):
        compiler = shutil.which("clang++") or shutil.which("g++")
        if not compiler:
            self.skipTest("No local C++ compiler; production AppleClang compilation is the CI gate")
        fixture = r'''
#include "ios/openmw_ios_touch_model.hpp"
#include <cassert>
int main() {
    using namespace OpenMWIOS::Touch;
    auto layout = makeLayout(956.f, 440.f, {0.f, 62.f, 21.f, 62.f});
    Ownership ownership;
    auto movement = ownership.begin(1, layout.movement.center, layout);
    auto look = ownership.begin(2, {layout.lookBoundaryX + 10.f, 50.f}, layout);
    auto button = ownership.begin(3, layout.buttons[0].bounds.center, layout);
    assert(movement && movement->role == Role::Movement);
    assert(look && look->role == Role::Look);
    assert(button && button->role == Role::Button);
    assert(ownership.bindings().size() == 3);
    ownership.end(2);
    assert(ownership.bindings().size() == 2);
    return 0;
}
'''
        with tempfile.TemporaryDirectory() as directory:
            source = pathlib.Path(directory) / "touch_fixture.cpp"
            executable = pathlib.Path(directory) / "touch_fixture"
            source.write_text(fixture, encoding="utf-8")
            subprocess.run([compiler, "-std=c++17", "-I", str(ROOT), str(source), "-o", str(executable)],
                           check=True, capture_output=True, text=True)
            subprocess.run([str(executable)], check=True, capture_output=True, text=True)


if __name__ == "__main__":
    unittest.main()
