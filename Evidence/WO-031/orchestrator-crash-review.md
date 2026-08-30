# WO-031 orchestrator crash review

- Review date: 2026-08-22
- Disposition: **AMENDMENT REQUIRED**
- Original execution commit: `e1f0734043a5ec5de1b770def293484a2d5c96ea`
- Diagnostic source candidate: `50aa047c3010be5380393a81c452bcfae206407d` — **REJECTED**
- Accepted engineering baseline: `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27` — unchanged

## Result accepted as evidence

The worker correctly stopped after the exact diagnostic IPA showed a loading screen for roughly half a second and then hard-crashed. It did not attempt a speculative renderer correction or consume a second build. The evidence-only report and manifest are preserved.

Independent review verified run `32581482760`, artifact `OpenMW-iOS-fast-37` (ID `9478916654`), IPA SHA-256 `351F218A48D0054BBEF7C1D7D9C513548E0F0EE93B89BA0C55EA2370D18D66A7`, executable SHA-256 `EC6FD36924513DBF3BF3D61307A4442898EE4314B4D004B04FD352B7A24AA33F`, and Mach-O UUID `98121EA4-1B76-30BC-83E0-14326772000A`.

## Supplied IPS identity

- Evidence file: `device-crash-98121EA4.ips`
- SHA-256: `F1FA79D3FB4A598BEB78C015518BDE7D2E7B058BDA1212AB4264D748587D0B3F`
- Incident: `C0B6EFA9-052B-4DBD-B5D8-75ECFA74D54F`
- App slice UUID: `98121EA4-1B76-30BC-83E0-14326772000A` — exact artifact match
- Launch: `2026-08-22 22:39:03.2436 +0530`
- Capture: `2026-08-22 22:39:04.0361 +0530`
- Exception: `EXC_BAD_ACCESS`, `SIGSEGV`, `KERN_INVALID_ADDRESS at 0x20`
- Faulting thread: thread 0 / main thread

The post-signing bundle identifier is `org.openmw.ios.7CP756AU4P`; the exact executable UUID remains unchanged. The report contains no signing, provisioning, entitlement, dyld, or installation failure.

## Decisive stack boundary

The relevant symbolicated sequence is:

1. `objc_retain`
2. `__NSDictionaryI_new`
3. `+[NSDictionary dictionaryWithObjects:forKeys:count:]`
4. `openmw_ios_renderer_diag_record`
5. `Shader::ShaderVisitor::createProgram(...)`

The diagnostic JSONL contained exactly one startup record and no later OpenMW, GL4ES, R1, or R2 record. The crash therefore occurred when shader creation attempted the first later diagnostic record.

## Source correlation

Direct inspection of `ios/openmw_ios_renderer_diagnostics.mm` at the rejected candidate found process-persistent raw globals `NSString *sPath` and `NSString *sSession`. `beginLocked()` assigned autoreleased results from `stringByAppendingPathComponent:` and `NSUUID.UUID.UUIDString` inside `openmw_ios_renderer_diag_begin()`'s `@autoreleasepool`. The production target does not enable ARC for this translation unit.

When the startup pool drained, neither object remained owned. The later dictionary literal in `openmw_ios_renderer_diag_record` attempted to retain the dangling session object, matching the `objc_retain` → `NSDictionary` frames. The path object has the same lifetime defect and would be unsafe on the subsequent append.

The IPS changes the worker report's source-backed suspect into a proven causal boundary for this regression. It does not reveal the underlying R1/R2 renderer defect because the diagnostic path crashed first.

## Orchestrator disposition

- Preserve worker execution evidence.
- Reject the diagnostic source candidate; do not merge it into the accepted engineering baseline.
- Keep R1 and R2 causes unknown and separate.
- Issue WO31 Amendment 1 as READY, authorizing only ownership repair, focused lifetime checks, one replacement diagnostic build, and then resumption of the original renderer scope if the diagnostics qualify.
- Require a new explicit start directive before the existing worker resumes.

See [DEC-008](../../Decisions/DEC-008.md) and [WO-031 Amendment 1](../../WorkOrders/WO-031.md).
