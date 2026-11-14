"""Narrow editor/layout contract for pinch-only native changes."""
import os, pathlib, shutil, subprocess, tempfile
root = pathlib.Path(__file__).resolve().parents[2]
compiler = os.environ.get("CXX") or shutil.which("clang++") or shutil.which("g++")
assert compiler
with tempfile.TemporaryDirectory() as d:
    for source in ("validation/current-frame/editor_pinch.cpp", "validation/parry-gesture/spacing.cpp"):
        exe = pathlib.Path(d) / "test"
        subprocess.run([compiler, "-std=c++17", "-Wall", "-Wextra", "-Werror", str(root/source), "-o", str(exe)], check=True)
        subprocess.run([str(exe)], check=True)
adapter = (root/"apps/openmw/ios/openmw_ios_touch_controls.mm").read_text()
for contract in ("_pinchRecognizer.enabled = NO", "_pinchRecognizer.enabled = YES", "event.allTouches.count > 1", "UIGestureRecognizerStateCancelled", "cancelsTouchesInView = YES", "OpenMWIOSTouchProfileV1", "safeAreaInsetsDidChange"):
    assert contract in adapter, contract
print("PASS targeted pinch bounds/cancel, saved profiles, layout, edit-only routing; device validation pending")
