"""Performance-only follow-up to corrected map/HUD source; preserve platform inputs."""
import subprocess
from pathlib import Path
BASE = "3fd0d3bc2da789049f32b2ee0333776d61aed028"
allowed = {
    "components/nifosg/controller.cpp", "components/nifosg/controller.hpp",
    "components/shader/shadervisitor.cpp", "components/shader/sampleruniform.hpp",
    "apps/components_tests/CMakeLists.txt",
    "apps/components_tests/nifosg/testmaterialcolorcontroller.cpp",
    "apps/components_tests/shader/testsampleruniform.cpp",
    ".github/workflows/material-performance-ios.yml", ".github/workflows/push.yml",
}
subprocess.run(["git", "merge-base", "--is-ancestor", BASE, "HEAD"], check=True)
changed = subprocess.check_output(["git", "diff", "--name-only", BASE], text=True).splitlines()
assert all(p in allowed or p.startswith("validation/material-performance/") for p in changed), changed
subprocess.run(["git", "diff", "--exit-code", BASE, "--", "ios-deps", "ios", "build-ios.sh",
    "apps/openmw", "files", ".github/workflows/current-frame-ios.yml"], check=True)
print("PASS performance-only scope; map/HUD, settings, assets, platform and dependency inputs unchanged")

original = subprocess.check_output(["git", "show", BASE + ":.github/workflows/push.yml"], text=True)
expected = original.replace("dot/main-current-frame, dot/parry-multitouch]",
    "dot/main-current-frame, dot/parry-multitouch, dot/material-performance]")
assert Path(".github/workflows/push.yml").read_text() == expected
print("PASS broad desktop workflow excluded only for this performance branch")
