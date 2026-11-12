"""Verify and stage the unsigned app, dSYM and reproducible source identity."""
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / "DerivedData/Build/Products/Release-iphoneos/OpenMW.app"
OUT = ROOT / "DerivedData/wo40-artifact"
OUT.mkdir(parents=True, exist_ok=True)
def run(*args):
    return subprocess.check_output(args, cwd=ROOT, text=True).strip()
def sha(path):
    with path.open("rb") as f:
        return hashlib.file_digest(f, "sha256").hexdigest()
info = plistlib.loads((APP / "Info.plist").read_bytes())
assert info["CFBundleIdentifier"] == "org.openmw.ios.framediagnostic"
assert info["CFBundleDisplayName"] == "OpenMW Frame Diagnostic"
exe = APP / info["CFBundleExecutable"]
assert run("lipo", "-archs", str(exe)) == "arm64"
assert not (APP / "embedded.mobileprovision").exists()
assert not (APP / "_CodeSignature").exists()
assert subprocess.run(["codesign", "-d", str(APP)], capture_output=True).returncode != 0
ipas = list((ROOT / "DerivedData/ipa").glob("*-unsigned.ipa"))
assert len(ipas) == 1, ipas
ipa = Path(shutil.copy2(ipas[0], OUT / "OpenMW-Current-Frame-Diagnostic-unsigned.ipa"))
dsym = Path(str(APP) + ".dSYM")
if dsym.is_dir():
    subprocess.run(["ditto", "-c", "-k", "--keepParent", str(dsym), str(OUT / "OpenMW.dSYM.zip")], check=True)
manifest = {
    "source": run("git", "rev-parse", "HEAD"),
    "workflowSource": os.environ.get("GITHUB_SHA"),
    "foundation": "2931be63bd2147e437a2b077ed6c97f563648a0a",
    "touchDonor": "93f892dd0cf9834259b4cad2045ddb2ef9c53ed9",
    "pauseCandidate": "457ab881442302a9bd59435c1878ed4e72f6e52b",
    "run": os.environ.get("GITHUB_RUN_ID"),
    "runnerImage": os.environ.get("ImageVersion"),
    "xcode": run("xcodebuild", "-version"),
    "sdk": run("xcrun", "--sdk", "iphoneos", "--show-sdk-version"),
    "bundleId": info["CFBundleIdentifier"], "displayName": info["CFBundleDisplayName"],
    "minimumOS": info["MinimumOSVersion"], "version": info["CFBundleShortVersionString"],
    "build": info["CFBundleVersion"], "architecture": "arm64", "signed": False,
    "ipaSHA256": sha(ipa), "ipaBytes": ipa.stat().st_size,
    "executableSHA256": sha(exe), "uuid": run("dwarfdump", "--uuid", str(exe)),
    "dSYM": dsym.is_dir(),
    "entitlementsSource": plistlib.loads((ROOT/"ios/OpenMW/OpenMW.entitlements").read_bytes()),
    "deviceValidation": "pending; NOT a validated latency fix",
    "presentationDiagnostic": "current PBO frame; SDL_UIKIT_EGL_CURRENT_FRAME default true",
}
archives = []
for path in sorted((ROOT/"ios-deps/source").glob("*/*")):
    if path.is_file() and any(str(path).endswith(s) for s in (".tar.gz", ".tar.xz", ".tar.bz2", ".tgz", ".zip")):
        archives.append({"path": str(path.relative_to(ROOT)), "sha256": sha(path)})
manifest["dependencyArchives"] = archives
(OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(json.dumps(manifest, indent=2))
