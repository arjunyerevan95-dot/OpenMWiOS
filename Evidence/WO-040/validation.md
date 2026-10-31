# WO40 validation

Local host: Windows; existing VS 2022 BuildTools MSVC 14.44.35207. No Apple SDK or UIKit runtime is locally available. No toolchain provisioning was done on Windows.

Run from the candidate checkout in a VS x64 Native Tools prompt:

    python validation/wo40/run_tests.py

Result: **PASS 132 executable input/layout/profile checks**, plus focused wiring and unchanged-renderer/dependency guards. Tests compile and run the actual C++ model/state used by UIKit. Covers observed rapid Pause edge sequences, cancellation/editor suppression, repeated callbacks/address reuse, long-press threshold/movement cancellation, second-finger Menu ownership, all device-policy combinations, layout/profile round-trip and safe-area rotation, corrupt/nonfinite/versioned values, Done/Cancel/Reset-confirmation/Undo, input ownership/release, movement deadzone and menu passthrough. Wiring guards supplement, not replace, executable tests.

Also passed: bash -n ios/build.sh; Python AST syntax for both validation scripts; YAML parse and manual workflow event-filter review; git diff --check. Primary build runs the same executable contract under Apple clang before the integrated compilation.

Primary CI stopped before its executable tests/compile because the version-check consumer closed the pipe early. The repaired actual preflight shell was executed locally with a delayed two-line producer: old script exit 141, repaired script exit 0, including real candidate ancestry and graphics-diff checks. This validates the shell repair, not Apple compilation. See report.md for exact run/failure.

Limits: these fixtures do not run UIKit, NSUserDefaults, an SDL device, physical input or the iOS GPU. Actual app relaunch persistence, controls on real hardware, startup/load and device takeover remain pending until the touch checklist is observed. The integrated Apple compile/link/package result will be recorded separately. No stock renderer/performance comparison is required or claimed.
