import pathlib
import shutil
import subprocess
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
MODEL = ROOT / "ios" / "openmw_ios_touch_model.hpp"
ADAPTER = ROOT / "ios" / "openmw_ios_touch_controls.mm"


class PauseShortTapTests(unittest.TestCase):
    def test_adapter_places_an_sdl_observation_between_pause_states(self):
        adapter = ADAPTER.read_text(encoding="utf-8")
        short_tap = adapter[adapter.index("if (identifier == _pendingMenuTouchId)") :]
        short_tap = short_tap[: short_tap.index("const auto binding")]

        self.assertIn("dispatchPauseShortTap", short_tap)
        self.assertIn("SDL_JoystickUpdate();", short_tap)
        self.assertNotIn("pressed:true];\n                [self setAction:Action::Pause pressed:false", short_tap)

    def test_pause_pulse_sequence_and_suppression_are_executable(self):
        compiler = shutil.which("clang++") or shutil.which("g++") or shutil.which("cl")
        if not compiler:
            self.skipTest("No C++17 compiler is available")

        fixture = r'''
#include "ios/openmw_ios_touch_model.hpp"

#include <cassert>
#include <string>

int main()
{
    using OpenMWIOS::Touch::dispatchPauseShortTap;
    std::string events;
    bool pressed = false;
    int pressCount = 0;
    int releaseCount = 0;
    int observationCount = 0;

    auto setPressed = [&](bool value) {
        pressed = value;
        events += value ? 'P' : 'R';
        value ? ++pressCount : ++releaseCount;
    };
    auto observe = [&] {
        assert(pressed);
        events += 'U';
        ++observationCount;
    };

    assert(dispatchPauseShortTap(false, false, setPressed, observe));
    assert(events == "PUR");
    assert(!pressed);
    assert(pressCount == 1 && releaseCount == 1 && observationCount == 1);

    events.clear();
    assert(!dispatchPauseShortTap(true, false, setPressed, observe));
    assert(events.empty());
    assert(!dispatchPauseShortTap(false, true, setPressed, observe));
    assert(events.empty());

    assert(dispatchPauseShortTap(false, false, setPressed, observe));
    assert(events == "PUR");
    assert(!pressed);
    assert(pressCount == 2 && releaseCount == 2 && observationCount == 2);
    return 0;
}
'''
        with tempfile.TemporaryDirectory() as directory:
            source = pathlib.Path(directory) / "pause_short_tap.cpp"
            is_msvc = pathlib.Path(compiler).name.lower() in {"cl", "cl.exe"}
            executable = pathlib.Path(directory) / ("pause_short_tap.exe" if is_msvc else "pause_short_tap")
            source.write_text(fixture, encoding="utf-8")
            command = (
                [compiler, "/nologo", "/std:c++17", "/EHsc", f"/I{ROOT}", str(source),
                 f"/Fo:{pathlib.Path(directory) / 'pause_short_tap.obj'}", f"/Fe:{executable}"]
                if is_msvc
                else [compiler, "-std=c++17", "-I", str(ROOT), str(source), "-o", str(executable)]
            )
            subprocess.run(
                command,
                check=True,
                capture_output=True,
                text=True,
            )
            subprocess.run([str(executable)], check=True, capture_output=True, text=True)


if __name__ == "__main__":
    unittest.main()
