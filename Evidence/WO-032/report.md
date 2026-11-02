# WO-032 execution report

## Outcome

**BLOCKED / STOPPED — Amendment 2 explicit stop boundary and Condition C.**

Amendment 2 successfully compiled, linked, packaged, installed, and ran the exact previously prepared R1 smoke correction. The timeout-only workflow change cleared the prior two-hour build boundary. Device evidence then falsified the correction's acceptance prediction: GL4ES still recorded blending disabled for four representative smoke draws, and the matching screenshot shows the chimney smoke remains visibly blocky. The correction is not device-qualified.

WO-032 stops here. No second build, renderer adjustment, foliage work, R2 distance/horizon work, touch work, or canonical ControlPlane change was made.

## Execution identity

- Accepted product baseline: `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27`.
- ControlPlane Amendment 2 commit: `208b9e9eb654a44b58273803e1be24f85e5e9e62`.
- Branch: `codex/wo32-targeted-renderer-boundary`.
- Diagnostic candidate: `79231c0fbf9293388f8f47456f8c2a2696291633`.
- Unchanged R1 correction source: `1625713b949ddb0cde5471feead75f29fedadfaa`.
- Timeout-only build commit: `c9161e579ff1814cc7fc5c86fb63a9ef177502f3`.
- Full Qualification: not run.
- Canonical ControlPlane changes: none.

## Amendment 2 validation and build

The only implementation delta after the correction commit was `.github/workflows/ios-fast.yml` job `timeout-minutes` from 120 to 180. The correction source itself remained unchanged.

Local gates:

- focused WO31/WO32 diagnostic tests: 22 run, 20 passed, 2 skipped because no host C compiler was available;
- aggregate iOS validation excluding the POSIX-only verifier: 129 passed, 6 skipped;
- ordered reconstruction: all 15 OpenMW patches, all 8 GL4ES patches, and the OSG patch passed;
- `git diff --check`: passed.

Exactly one replacement Fast Development run was triggered:

- run `32649331052`, job `97218368995`;
- result: success in 1h21m13s;
- dependency preparation: 2,219 seconds;
- production compile/link: 2,316 seconds;
- source-download cache hit; vcpkg and qualified build-state caches did not restore;
- production compile/link, bundle validation, resource validation, package, and upload all passed;
- artifact `OpenMW-iOS-fast-51`, ID `9496797285`, digest `sha256:4c358ee09b35270cdc3d39b1d5887ca5e6331c0a9bd140ef728cbdf3461101b4`;
- IPA SHA-256 `57B4A011E29C9116E451877169351B0A6A5D5B063AE843605CE0C0B4D4D031B7`;
- executable SHA-256 `FC4A34EB321633BBEE4DD47F8AB3E8E0E3C3347091EA4B56CC415C2C6BB4CE95`;
- Mach-O UUID `FAC81B2E-2852-37AF-A602-DED71C652E56`.

Run: <https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/32649331052>

## Device evidence

The exact IPA was supplied for installation. The user reached the mandatory Seyda Neen chimney-smoke view and returned one screenshot plus a fresh bounded renderer JSONL.

- JSONL: 97,681 bytes / 309 records; SHA-256 `E0289184EEE32FCA9DF38C66239EF71B061713F182F94646CE1032AA8ACA0AAE`.
- Session: `5ED135B0-B449-4845-8A83-2251FF810A03`.
- Screenshot SHA-256: `F0CCBDC60A0F44D4FDE01F3788D5D5FDCE70E417727518EE8D198CACF596D15B`.
- Visual result: chimney smoke remains blocky/opaque against the sky.

The capture dynamically identified `textures/tx_smokealpha00a.dds` as texture 115 / program 9. Samples 259, 262, 276, and 277 all report:

```text
blend=0;blend_func=770,771,770,771;alpha_test=0;depth_test=1;depth_write=0;fragment_has_discard=1;fragment_writes_alpha=1
```

Thus the correction did not cause GL4ES to observe blend enable. The same invalid state and visible symptom remain. Detailed capture evidence is in [amendment2-device-capture.md](amendment2-device-capture.md).

OpenMW reached the exterior with HUD, native landscape presentation, and diagnostic output functioning; no launch crash was reported. Separate indoor, water, touch-action, short-tap Menu, and extended traversal regression checks were not supplied and are **NOT RECORDED** rather than inferred.

## Causal disposition

The prior diagnostic evidence remains valid: the smoke asset, intended factors, depth-write state, and fragment alpha behavior reach the draw, while GL4ES records blend disabled. What Amendment 2 disproves is that correction commit `1625713` is sufficient to repair that boundary in the production device path.

The next incorrect state-ownership mechanism is not established by this work order. Modifying the correction in response would require a new orchestrator decision and is prohibited here. Foliage and R2 distance/horizon remain independent unresolved boundaries.

## Stop boundary

The canonical Amendment 2 instruction requires an immediate stop if GL4ES still records disabled blending or the visible smoke does not improve. Both occurred. This also invokes general Condition C: the remaining cause is unproven, so do not guess.

No second Fast build was triggered. No Full Qualification ran. No accepted project state, work order, or durable decision was modified.
