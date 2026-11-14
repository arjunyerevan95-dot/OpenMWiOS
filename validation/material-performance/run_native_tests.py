"""Build only modified CPU units/tests against host OSG. No app or GPU/device access."""
import os, pathlib, shlex, subprocess, tempfile
ROOT = pathlib.Path(__file__).resolve().parents[2]
cxx = os.environ.get("CXX", "g++")
flags = shlex.split(os.environ.get("PERF_TEST_CXXFLAGS", ""))
libs = shlex.split(os.environ.get("PERF_TEST_LDFLAGS", ""))
# OSG and gtest are real; only unused NIF file decoding/stereo entrypoints are
# abort-only link boundaries. No tested controller/material behavior is stubbed.
sources = ["components/nifosg/controller.cpp", "components/sceneutil/material.cpp",
           "components/sceneutil/controller.cpp", "components/sceneutil/statesetupdater.cpp",
           "apps/components_tests/nifosg/testmaterialcolorcontroller.cpp",
           "apps/components_tests/shader/testsampleruniform.cpp",
           "validation/material-performance/link_boundaries.cpp"]
with tempfile.TemporaryDirectory(prefix="openmw-material-tests-") as tmp:
    objects = []
    for i, source in enumerate(sources + ["components/shader/shadervisitor.cpp"]):
        obj = str(pathlib.Path(tmp) / f"{i}.o")
        subprocess.run([cxx, "-std=c++20", "-ffunction-sections", "-fdata-sections", "-I", str(ROOT),
            *flags, "-c", str(ROOT/source), "-o", obj], check=True)
        if source != "components/shader/shadervisitor.cpp":
            objects.append(obj)
    exe = str(pathlib.Path(tmp) / "material-tests")
    subprocess.run([cxx, "-Wl,--gc-sections", *objects, *libs, "-lgtest_main", "-lgtest",
        "-losg", "-losgUtil", "-lOpenThreads", "-pthread", "-o", exe], check=True)
    subprocess.run([exe, "--gtest_filter=*MaterialColor*:*OpaqueDepthSampler*"], check=True)
print("PASS targeted CPU correctness; no measured iPhone performance or rendered-image validation")
