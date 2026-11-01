# WO40 validation

Local host: Windows; existing VS 2022 BuildTools MSVC 14.44.35207. No Apple SDK or UIKit runtime is locally available. No toolchain provisioning was done on Windows.

Run from the candidate checkout in a VS x64 Native Tools prompt:

    python validation/wo40/run_tests.py

Result: **PASS 132 executable input/layout/profile checks**, plus focused wiring and unchanged-renderer/dependency guards. Tests compile and run the actual C++ model/state used by UIKit. Covers observed rapid Pause edge sequences, cancellation/editor suppression, repeated callbacks/address reuse, long-press threshold/movement cancellation, second-finger Menu ownership, all device-policy combinations, layout/profile round-trip and safe-area rotation, corrupt/nonfinite/versioned values, Done/Cancel/Reset-confirmation/Undo, input ownership/release, movement deadzone and menu passthrough. Wiring guards supplement, not replace, executable tests.

Also passed: bash -n ios/build.sh; Python AST syntax for both validation scripts; YAML parse and manual workflow event-filter review; git diff --check. The successful repair build ran the same executable contract under Apple clang: **PASS 132 checks**, followed by passing wiring/preservation guards.

Primary CI stopped before its executable tests/compile because the version-check consumer closed the pipe early. The repaired actual preflight shell was executed locally with a delayed two-line producer: old script exit 141, repaired script exit 0, including real candidate ancestry and graphics-diff checks. The repair run then passed real Xcode/foundation verification, the executable touch contract under Apple clang, integrated Objective-C++/engine compilation/linking, unsigned IPA packaging and artifact upload. See report.md for exact runs.

The successful run used Xcode 27.1 (27A9275), iPhoneOS SDK 27.1 and runner image 20261026.0314.1. Source and workflow revision were both f4d9f9d8d6bcba1b3bc59201724aab62627aaa4e. Git diff against foundation 2931be63bd2147e437a2b077ed6c97f563648a0a remained empty for protected renderer/dependency/resource paths.

Artifact retrieval used `gh run download 41200954123 --repo arjunyerevan95-dot/OpenMWiOS --name WO40-Zink-Touch-41200954123 --dir DerivedData/wo40-delivery`. Independent Python reads of the downloaded bytes passed: `ZipFile.testzip()` for IPA and dSYM, SHA-256/byte-count comparison with manifest, Info.plist bundle/display/minimum-OS values, and extracted executable SHA-256. Mach-O parsing confirmed arm64, UUID 8D3AFF23-3332-305A-A4D1-E75003429268 and no LC_CODE_SIGNATURE; archive inspection found no embedded.mobileprovision or _CodeSignature and found bundled license resources. The executable is selected by Info.plist's CFBundleExecutable (`OpenMW`); an initial redundant lowercase-filename assertion was corrected in the local verification command. No artifact or source repair was needed. A concise local result is saved at `DerivedData/wo40-delivery/local-verification.json` (ignored).

Independent parsing of the downloaded dSYM's DWARF Mach-O also confirmed arm64 and the same UUID as the app executable.

Limits: these fixtures do not run UIKit, NSUserDefaults, an SDL device, physical input or the iOS GPU. Actual app relaunch persistence, controls on real hardware, startup/load and device takeover remain pending until the touch checklist is observed. Successful compile/link/package does not establish those runtime results. No stock renderer/performance comparison is required or claimed.

Device follow-up on 2026-11-01: after the verified game-data transfer into LiveContainer, the user reported that the candidate "works great" and identified inability to swipe-aim while holding a button such as Attack. This general report supplies initial device feedback. Detailed Menu/editor/persistence/release observations and the exact aiming gesture remain pending. See [device feedback in the report](report.md#device-feedback-after-delivery). The automated tests did not cover a button-owned touch also producing aiming deltas.
