"""Focused WO40 executable contract plus narrow wiring/identity guards."""
import os
import pathlib
import shutil
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
compiler = os.environ.get("CXX") or shutil.which("clang++") or shutil.which("g++") or shutil.which("cl")
if not compiler:
    raise SystemExit("C++17 compiler required; use a VS x64 Native Tools prompt or CXX=clang++.")
with tempfile.TemporaryDirectory(prefix="wo40-touch-") as directory:
    d = pathlib.Path(directory)
    msvc = pathlib.Path(compiler).name.lower() in ("cl", "cl.exe")
    exe = d / ("touch-contract.exe" if os.name == "nt" else "touch-contract")
    source = ROOT / "validation/wo40/touch_contract.cpp"
    args = ([compiler, "/nologo", "/std:c++17", "/EHsc", "/W4", f"/I{ROOT}", str(source),
             f"/Fo{d / 'touch-contract.obj'}", f"/Fe{exe}"] if msvc else
            [compiler, "-std=c++17", "-Wall", "-Wextra", "-pedantic", "-I", str(ROOT), str(source), "-o", str(exe)])
    subprocess.run(args, cwd=d, check=True)
    subprocess.run([str(exe)], cwd=d, check=True)

adapter = (ROOT / "apps/openmw/ios/openmw_ios_touch_controls.mm").read_text()
platform = (ROOT / "apps/openmw/ios/platform.mm").read_text()
input_manager = (ROOT / "apps/openmw/mwinput/inputmanagerimp.cpp").read_text()
assert "GCVirtualController" not in platform and "addTwoFingerTap" not in platform
assert "SDL_GetWindowWMInfo" in adapter and "keyWindow" not in adapter
assert "SDL_ShowCursor" not in adapter and "openmw_ios_set_gameplay_mode(!guiMode)" in input_manager
assert "UIApplicationWillResignActiveNotification" in adapter and "[super dealloc]" in adapter
assert "[[UIImage alloc] initWithData:data]" in adapter and "validProfile(candidate)" in adapter
assert "SDL_JOYSTICK_AXIS_MIN" in adapter and "MenuGesture _menu" in adapter
assert "dispatch_after" not in adapter  # no stale long-press timer with reused touch address
subprocess.run(["python3", str(ROOT / "validation/current-frame/check_scope.py")], cwd=ROOT, check=True)
print("PASS unchanged touch contract and separate diagnostic scope guard")
