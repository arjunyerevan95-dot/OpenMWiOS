# WO-032 execution report

## Outcome

**BLOCKED / STOPPED — Condition G, build budget exhausted.**

WO-032 successfully produced and device-tested its targeted diagnostic candidate. That evidence proves one R1 smoke/particle cause: OSG direct core blend-state calls bypass GL4ES state ownership while GL4ES owns converted programs and draw submission. A narrow Apple-only OSG routing correction was implemented and passed local/patch validation. The one authorized correction Fast run then missed both dependency caches and was terminated by GitHub's two-hour limit during dependency preparation, before OpenMW compilation. No corrected IPA exists, so the correction is not device-qualified and accepted product state does not change.

R2 remains unqualified because the supplied capture used maximum view distance only and contains no second materially different stable generation. The foliage target is also already opaque before raster output, so its distinct earliest cause remains unproven.

## Execution identity

- Original ControlPlane issue commit: `9100edc9ee3f9dc89ec6adafc28ec72a77ed48a8`.
- Amendment 1 ControlPlane commit: `6cae3de751382cf764defc8ab783b338e2351d4a`.
- Investigation continuation: `626b3321ee7ce83f82d22a707dfa4f9177cf6fff`.
- Branch: `codex/wo32-targeted-renderer-boundary`.
- Targeted diagnostics: `4b626d80dcf58bc5768c71f2e043c9f4edec6b07`.
- Parser repair / diagnostic candidate: `79231c0fbf9293388f8f47456f8c2a2696291633`.
- R1 correction source candidate: `1625713b949ddb0cde5471feead75f29fedadfaa`.
- Full Qualification: not run.
- Canonical ControlPlane changes: none.

## Amendment 1 and diagnostic build

Amendment 1 changed only the two test-side embedded-diff parsers and added synthetic blank-context regressions. Replacement Fast run `32627872506` succeeded in 58m09s, compiled and linked the real production app, validated and packaged one artifact, and uploaded `OpenMW-iOS-fast-47` (artifact ID `9490874268`, digest `sha256:d32529f56a7d495ffb689db40781aa4cf088517213579aa2b7e15ad132d25675`).

The exact device candidate identities are:

- IPA SHA-256 `90C6AA65BBAADE4FF1C0D13D2BC7E124E1EBD119D2A91C513E80FA39C802A942`;
- executable SHA-256 `BA7E32C8A3E5BBBFF0D38DBE89606D0D009C562E323F4F9B206C8BEE6513F316`;
- Mach-O UUID `1173DA95-B273-3CE7-948D-BA2EDA504701`.

## Device evidence and R1 conclusion

The user supplied five matching screenshots plus a bounded 317-record JSONL. The screenshots visibly preserve opaque foliage cards, blocky chimney smoke, white/blank distance, the sharp blue horizon band, opaque blue spell cards, and opaque orange fire cards. Exact hashes and samples are in [device-capture-analysis.md](device-capture-analysis.md).

The chimney-smoke asset `textures/tx_smokealpha00a.dds` is DXT5/translucent. Its applied program 9 draw has standard `SRC_ALPHA` / `ONE_MINUS_SRC_ALPHA` factors, depth writes disabled, and a fragment shader that writes alpha and contains discard, but GL4ES records blending disabled. This is not an asset-alpha or shader-alpha absence.

Pinned OSG directly calls core `glEnable`, `glDisable`, and ordinary `glBlendFunc`; the existing routing patch covered dynamically resolved extension entry points only. The exact Mach-O defines the GL4ES wrapper symbols but imports the unprefixed core symbols from native GLES. Thus native GLES and GL4ES hold split state: OSG enables native blending while GL4ES submits the converted draw without observing that enable.

This proves the earliest R1 cause for smoke/particles. It does not prove the foliage cause: `textures/tx_bc_moss.dds` reaches its program 21 draw as DXT1/RGB, `translucent=0`, with alpha test disabled, depth writes enabled, and no fragment discard/alpha output.

## R2 conclusion

The device run captured one effective maximum-distance fog generation only. OpenMW intent, OSG application, GL4ES receipt, and eight of nine sampled consumers agree on fog start/end/color/scale. Program 81 lacks fog locations, but its purpose is unknown. The nearby projection values are slider-transition samples, not a second selected stable view distance.

The user's clarification that every supplied distance screenshot used maximum view distance is authoritative. R2 therefore remains insufficient; WO-032 made no distance, fog, paging, cull, sky, clear, or depth correction.

## Minimal correction

Commit `1625713b949ddb0cde5471feead75f29fedadfaa` modifies the deterministic OSG patch so Apple manual-init builds route the two OSG core mode sites and ordinary blend-function application through GL4ES. Other platforms preserve direct GL behavior. Focused and aggregate local gates passed, the patch applied cleanly to pinned OSG, and no touch, data path, shader, FBO, dependency revision, workflow, or canonical ControlPlane file changed.

## Correction-build failure boundary

The only authorized correction Fast run was `32634038454`, job `97181008153`, at exact commit `1625713b949ddb0cde5471feead75f29fedadfaa`.

The OSG patch changed the cache ABI fingerprint to `e450a18045485e1ccbeb921b8d7c3abff8faaf3ebaa70756dfb02b8e53128786`. Source downloads restored, but the vcpkg binary cache and qualified incremental build-state cache both missed. The workflow therefore entered a cold dependency path. Bootstrap and every ordered patch passed; GL4ES rebuilt successfully. GitHub then cancelled the job at the two-hour limit while still in `Incremental configure and dependency preparation`.

Consequences:

- production OpenMW compilation/link did not start;
- bundle/package validation did not run;
- no artifact, executable, or IPA was produced;
- no corrected device test was possible;
- no second Fast run was triggered;
- Full Qualification did not run.

Run: <https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/32634038454>

## Strongest conclusion and review boundary

R1 smoke/particle state divergence is causally localized, and the prepared correction is narrow and locally validated. However, the build-timeout boundary prevents production and device qualification. Foliage and R2 remain separate unresolved boundaries; neither may be inferred fixed by the unbuilt correction.

WO-032 must stop under Condition G. The orchestrator must decide whether and how to authorize a future build opportunity for this already-prepared correction. This execution report does not authorize another build, acceptance, a work-order amendment, or further renderer work.
