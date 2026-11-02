# WO-038 Amendment 1 Orchestrator Review

- Review date: 2026-08-30
- Original execution disposition: **PARTIAL EXECUTION ACCEPTANCE — COLD BUILD RECOVERED; ATTRIBUTION NOT REACHED**
- Amendment disposition: **READY — NARROW PAUSE SHORT-TAP PREREQUISITE**
- Accepted engineering baseline remains: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`

## Inputs reviewed

- Worker execution/evidence commit: `6f3eb24ae9be73950c3813964755169497bcc26e`
- Cold-build/source commit: `f3ccd53e1fa823e583057afd15e8a5ce94d0ab97`
- Fast run: `33269657425` — successful
- Artifact: `OpenMW-iOS-fast-66`, ID `9720624645`
- Artifact digest: `sha256:17b27b5a0b4a957dafefb9792f545b0fed8826955b7ebdbb9c5f878148f9d8ed`
- IPA SHA-256: `d66f5c31a50a48a8a35c8b5e9bc74e558d224c2da9d0debf8072f8b61df194ee`
- Executable SHA-256: `3d0308bb45d1823b441c4bb627846eb92c239c24e57aa4238a6ac1105c949d54`
- Mach-O UUID: `0FBDA93C-0871-39E6-A80D-C16B14606AC3`
- Worker report: `Evidence/WO-038/report.md` at the evidence commit
- Mirrored report: <https://gist.github.com/arjunyerevan95-dot/f440c84042db917388a74cc2186fcc38>

## Original execution findings

The iOS-only `-DCMAKE_DISABLE_FIND_PACKAGE_GLIB=ON` correction stayed within scope. Focused validation passed, patch bootstrap/source validation passed, and Fast run `33269657425` traversed the previously failing cold path with source-download, vcpkg, and qualified incremental-state cache misses. Cold OSG configuration, real OpenMW compile/link, packaging, and artifact upload all passed.

This accepts build-recovery evidence only. The source commit and diagnostic artifact do not become the accepted engineering/runtime baseline before physical-device qualification and target attribution.

The worker correctly stopped rather than applying a user-requested touch change prohibited by canonical WO38. No touch, renderer, additional build, or canonical ControlPlane change occurred.

## Capture blocker and direct source proof

The diagnostic fires once at the first eligible exterior frame. Trustworthy correlation therefore requires a save whose restored camera already centers the prepared target. The user confirms that this exact-location save cannot be made because short-tapping Pause/Menu does not open the pause menu; long-press still opens the touch editor.

Codebase Memory located the relevant OpenMW and SDL controller paths. Direct inspection was required for the current Objective-C++ bridge and proves:

- ordinary buttons keep their pressed state from `touchesBegan` until a later `finishTouches` callback;
- Pause short-tap instead emits pressed and released synchronously inside `finishTouches` after long-press arbitration;
- pinned SDL's `SDL_JoystickSetVirtualButtonInner` only writes the current value to virtual-device storage; and
- `VIRTUAL_JoystickUpdate` later compares/emits that stored state to SDL controller events, which OpenMW then forwards to its input binder.

The immediate true/false pair can be reduced to only the final false value before SDL's update observes it. This is a precise prerequisite defect with a narrow ownership boundary in the iOS Pause arbitration—not authority for general touch work.

## Amendment decision

- Authorize only a bounded Pause short-tap lifetime correction that preserves one pressed edge through SDL observation and then releases exactly once.
- Preserve long-press editor entry and suppression, cancellation safety, all other touch mappings, layout/editor/profile behavior, diagnostic semantics, and renderer behavior.
- Require deterministic transition-lifetime coverage; existing static source assertions are not sufficient by themselves.
- Authorize exactly one additional Fast build for this prerequisite. The original conditional replacement clause is expired, and no replacement for the amendment build is authorized.
- After device verification, use the same IPA to create the prepared save and complete the original target attribution.
- Continue to prohibit any renderer correction under WO38.

No durable Decision is created before the correction and capture protocol qualify on device.
