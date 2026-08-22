import base64
import json
import math
import pathlib
import re
import shutil
import struct
import subprocess
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
MODEL = ROOT / "ios" / "openmw_ios_touch_model.hpp"
ADAPTER = ROOT / "ios" / "openmw_ios_touch_controls.mm"
ICONS = ROOT / "ios" / "openmw_ios_touch_icons.hpp"
PATCH = ROOT / "patches" / "openmw" / "0012-ios-android-derived-touch-controls.patch"
REFERENCE = ROOT / "validation" / "fixtures" / "android-touch-2.7.4-reference.json"


def clamp(value: float, minimum: float, maximum: float) -> float:
    return max(minimum, min(value, maximum))


def make_layout(width: float, height: float, safe=(0.0, 0.0, 0.0, 0.0)):
    top, left, bottom, right_inset = safe
    short_side = min(width, height)
    stick_radius = clamp(short_side * 0.15, 48.0, 92.0)
    content_width = max(width - left - right_inset, 1.0)
    content_height = max(height - top - bottom, 1.0)

    def android_center(x, y, size):
        radius = clamp(size * content_width / 2048.0, 22.0, 72.0)
        return (clamp(left + x * content_width / 1024.0 + radius,
                      left + radius, width - right_inset - radius),
                clamp(top + y * content_height / 768.0 + radius,
                      top + radius, height - bottom - radius), radius)

    definitions = (
        ("Activate", 330.0, 630.0, 70.0),
        ("Attack", 800.0, 315.0, 120.0),
        ("Jump", 624.0, 630.0, 70.0),
        ("ReadyWeapon", 940.0, 560.0, 70.0),
        ("ReadyMagic", 940.0, 450.0, 70.0),
        ("Inventory", 940.0, 95.0, 70.0),
        ("Pause", 940.0, 0.0, 70.0),
        ("Sneak", 850.0, 0.0, 70.0),
        ("Journal", 270.0, 0.0, 70.0),
        ("TogglePOV", 90.0, 0.0, 70.0),
        ("QuickSave", 180.0, 0.0, 70.0),
        ("Wait", 360.0, 0.0, 70.0),
    )
    buttons = tuple((name, *android_center(x, y, size)) for name, x, y, size in definitions)
    return {"movement_radius": stick_radius,
            "movement_boundary": left + content_width * 0.36,
            "look_boundary": left + content_width * 0.36,
            "buttons": buttons,
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
        circles = tuple(button[1:] for button in layout["buttons"])
        for x, y, radius in circles:
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
        self.assertEqual(reference["ui_config_path"], "payload/app/ui/UI.cfg")
        self.assertEqual(reference["archived_osc_layout_reference"]["commit"],
                         "bfd613230ebe57170cbe4966aa8938d54afa6efa")
        self.assertEqual(reference["archived_osc_layout_reference"]["virtual_size"], [1024, 768])
        self.assertEqual(reference["archived_utility_icon_provenance"]["commit"],
                         "bfd613230ebe57170cbe4966aa8938d54afa6efa")

    def test_iphone_landscape_layout_respects_safe_area(self):
        self.assert_layout_inside_safe_area(956, 440, (0, 62, 21, 62))

    def test_ipad_landscape_layout_respects_safe_area(self):
        self.assert_layout_inside_safe_area(1366, 1024, (24, 0, 20, 0))

    def test_arbitrary_landscape_layout_respects_safe_area(self):
        self.assert_layout_inside_safe_area(1180, 820, (13, 37, 29, 11))

    def test_layout_recomputes_for_orientation_and_size(self):
        landscape = make_layout(1180, 820, (13, 37, 29, 11))
        alternate = make_layout(820, 1180, (37, 13, 11, 29))
        self.assertEqual(landscape["movement_radius"], alternate["movement_radius"])
        self.assertNotEqual(landscape["look_boundary"], alternate["look_boundary"])
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

    def test_gui_mode_keeps_semantic_menu_buttons_and_other_touches_passthrough(self):
        adapter = ADAPTER.read_text(encoding="utf-8")
        model = MODEL.read_text(encoding="utf-8")
        self.assertIn("visibleInMode", model)
        self.assertIn("Action::Inventory || action == Action::Pause || action == Action::Journal", model)
        self.assertIn("button.bounds.contains(touchPoint, 1.15f)", adapter)
        self.assertIn("return NO;", adapter)
        self.assertIn("SDL_ShowCursor(SDL_QUERY) == SDL_DISABLE", adapter)
        self.assertIn("[self releaseAllInputs]", adapter)
        self.assertIn('mode=gui;controls=inv,journal,menu;other_touches=passthrough', adapter)

    def test_public_sdl_paths_preserve_external_input_architecture(self):
        adapter = ADAPTER.read_text(encoding="utf-8")
        self.assertIn("SDL_JoystickAttachVirtualEx", adapter)
        self.assertIn("SDL_JoystickSetVirtualAxis", adapter)
        self.assertIn("SDL_JoystickSetVirtualButton", adapter)
        self.assertIn("SDL_PushEvent", adapter)
        self.assertNotIn("SDL_SendMouseMotion", adapter)
        self.assertNotIn("SDL_SendKeyboardKey", adapter)

    def test_android_actions_use_openmw_semantic_controller_bindings(self):
        adapter = ADAPTER.read_text(encoding="utf-8")
        mappings = {
            "Activate": "SDL_CONTROLLER_BUTTON_A",
            "ReadyWeapon": "SDL_CONTROLLER_BUTTON_X",
            "ReadyMagic": "SDL_CONTROLLER_BUTTON_Y",
            "Inventory": "SDL_CONTROLLER_BUTTON_B",
            "Pause": "SDL_CONTROLLER_BUTTON_START",
            "Sneak": "SDL_CONTROLLER_BUTTON_LEFTSTICK",
            "Journal": "SDL_CONTROLLER_BUTTON_LEFTSHOULDER",
        }
        for action, binding in mappings.items():
            self.assertRegex(adapter, rf"case Action::{action}:\s+return {binding};")
        self.assertRegex(adapter, r"case Action::Attack:\s+return SDL_CONTROLLER_AXIS_TRIGGERRIGHT;")
        self.assertRegex(adapter, r"case Action::Jump:\s+return SDL_CONTROLLER_AXIS_TRIGGERLEFT;")
        self.assertNotRegex(adapter, r"case Action::Inventory:\s+return SDL_SCANCODE_B;")
        self.assertIn("pushMouseButton(SDL_BUTTON_RIGHT, pressed)", adapter)

    def test_android_osc_control_grouping_and_utility_actions_are_present(self):
        model = MODEL.read_text(encoding="utf-8")
        adapter = ADAPTER.read_text(encoding="utf-8")
        layout = make_layout(956, 440, (0, 62, 21, 62))
        actions = {button[0] for button in layout["buttons"]}
        self.assertEqual(actions, {"Activate", "Attack", "Jump", "ReadyWeapon", "ReadyMagic",
                                   "Inventory", "Pause", "Sneak", "Journal", "TogglePOV",
                                   "QuickSave", "Wait"})
        self.assertIn("1024x768 virtual coordinate system", model)
        self.assertIn("Action::Activate, 330.f, 630.f, 70.f", model)
        self.assertIn("Action::Attack, 800.f, 315.f, 120.f", model)
        self.assertIn("Action::Pause, 940.f, 0.f, 70.f", model)
        utility_scancodes = {
            "TogglePOV": "SDL_SCANCODE_TAB",
            "QuickSave": "SDL_SCANCODE_F5",
            "Wait": "SDL_SCANCODE_T",
        }
        for action, scancode in utility_scancodes.items():
            self.assertRegex(adapter, rf"case Action::{action}:\s+return {scancode};")
        self.assertIn("BOOL dispatched = NO", adapter)
        self.assertIn("if (!dispatched)", adapter)

    def test_movement_is_floating_and_look_is_an_invisible_free_drag_region(self):
        model = MODEL.read_text(encoding="utf-8")
        adapter = ADAPTER.read_text(encoding="utf-8")
        self.assertIn("Point startPoint", model)
        self.assertIn("point.x <= layout.movementBoundaryX", model)
        self.assertIn("point.x >= layout.lookBoundaryX", model)
        self.assertIn("binding.startPoint, _layout.movementRadius", adapter)
        self.assertNotIn("drawCircle(_layout.look", adapter)
        self.assertNotIn("layout.look.contains", model)

    def test_android_icons_are_embedded_with_pinned_provenance(self):
        icons = ICONS.read_text(encoding="utf-8")
        adapter = ADAPTER.read_text(encoding="utf-8")
        self.assertIn("5b02e847dc646c9f10cd66001e4d65c5274dde49", icons)
        for number in (1, 2, 3, 4, 6, 7, 8, 9):
            self.assertIn(f"icon{number}[]", icons)
        for name in ("thirdPersonIcon", "saveIcon", "journalIcon", "waitIcon"):
            self.assertIn(f"{name}[]", icons)
        self.assertIn("imageForAction", adapter)
        self.assertIn("imageWithTintColor:UIColor.whiteColor", adapter)

    def test_process_lifetime_icon_cache_owns_images_under_non_arc(self):
        adapter = ADAPTER.read_text(encoding="utf-8")
        self.assertIn("UIImage* image = [[UIImage alloc] initWithData:data];", adapter)
        self.assertIn("[data release];", adapter)
        self.assertNotIn("return [UIImage imageWithData:data];", adapter)

    def test_all_embedded_android_icons_are_valid_128px_pngs(self):
        icons = ICONS.read_text(encoding="utf-8")
        names = ("icon1", "icon2", "icon3", "icon4", "icon6", "icon7", "icon8", "icon9",
                 "thirdPersonIcon", "saveIcon", "journalIcon", "waitIcon")
        for name in names:
            match = re.search(rf"{name}\[\]\s*=\s*R\"OMWICON\((.*?)\)OMWICON\";", icons, re.S)
            self.assertIsNotNone(match, name)
            data = base64.b64decode(re.sub(r"\s+", "", match.group(1)), validate=True)
            self.assertEqual(data[:8], b"\x89PNG\r\n\x1a\n", name)
            self.assertEqual(struct.unpack(">II", data[16:24]), (128, 128), name)

    def test_inventory_press_and_release_are_not_keyboard_b(self):
        adapter = ADAPTER.read_text(encoding="utf-8")
        self.assertIn("SDL_JoystickSetVirtualButton", adapter)
        self.assertIn("pressed ? SDL_PRESSED : SDL_RELEASED", adapter)
        self.assertNotIn("These preserve the current Android 2.7.4 UI.cfg semantics", adapter)

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
    Point movementPoint{layout.safeArea.left + 20.f, 220.f};
    Point lookPoint{layout.width * 0.55f, 220.f};
    auto movement = ownership.begin(1, movementPoint, layout);
    auto look = ownership.begin(2, lookPoint, layout);
    auto button = ownership.begin(3, layout.buttons[0].bounds.center, layout);
    assert(movement && movement->role == Role::Movement);
    assert(look && look->role == Role::Look);
    assert(button && button->role == Role::Button);
    assert(ownership.bindings().size() == 3);
    Ownership guiOwnership;
    auto guiInventory = guiOwnership.begin(4, layout.buttons[5].bounds.center, layout, false);
    auto guiMovement = guiOwnership.begin(5, movementPoint, layout, false);
    assert(guiInventory && guiInventory->role == Role::Button);
    assert(!guiMovement);
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
