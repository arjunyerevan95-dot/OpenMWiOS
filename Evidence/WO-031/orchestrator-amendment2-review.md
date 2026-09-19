# WO-031 Amendment 2 orchestrator review

- Review date: 2026-08-23
- Disposition: **PARTIAL ACCEPT / CLOSE WO31**
- Worker execution commit: `123ae04675dda763158fa7332e8f36d64b88105d`
- Diagnostic source commit: `626b3321ee7ce83f82d22a707dfa4f9177cf6fff`
- Accepted engineering baseline: `195f3a4bbcfd17ecd46546f3e28d3ee8558bed27` — unchanged

## CI and artifact verification

- Fast run `32597504051`: completed / success, head `626b3321ee7ce83f82d22a707dfa4f9177cf6fff`.
- Artifact: `OpenMW-iOS-fast-42`, ID `9482706450`, 39,171,265 bytes.
- Artifact digest: `sha256:f48928d4f6b30c6b7e305fe27df69213f17405a35ac20c3367af6e98de6c41a5`.
- Reported IPA SHA-256: `824395081D76CBC7B5B164B4FC9CDC4CEBB752D7D7D451E011246B42674B6857`.
- Reported executable SHA-256: `0B19227B2E7950307385BE5B467D36C7D2F01AC6AD05FFE0B74C239879314447`.
- Reported Mach-O UUID: `9A5D277A-AC2B-3E86-9E18-D1E85985EC88`.
- No Full Qualification or renderer-correction build ran.

## Device diagnostic verification

The committed JSONL is 119,299 bytes, SHA-256 `DE23923768DC05B302BC9FF4FF11AB4ECD7EF62579123A5667BB9076549DD0E9`, session `D439E773-231C-47E7-A41B-FC53A80BDDEB`, with 396 records.

Accepted record inventory includes:

- one OpenMW and one GL4ES handshake;
- 48 OpenMW assets, 48 OSG bindings, 48 GL4ES uploads, and 96 GL4ES draws;
- 16 OpenMW exterior fog intents and 16 OSG fog applications;
- 32 GL4ES fog-received and 32 early applied-program records.

The bridge is proven live and the exact shipped product retains/resolves the diagnostic symbols.

## R1 conclusion

Defective smoke, moss, fern, kelp, tree, and fire-family textures are identified and bound. The visible particle case was chimney smoke; no cast fire spell was deliberately exercised. The broad `r1.draw` budget exhausted at sample 199, while the first defective binding appeared at sample 210. Therefore none of the captured applied draws represents a defective texture.

Accept the asset/binding localization. Do not infer the failing alpha/blend/depth/shader boundary.

## R2 conclusion

OpenMW intended, OSG applied, and GL4ES received exterior fog values agree. Exterior GL4ES receipt begins after sample 324, while the `r2.applied` budget exhausted at sample 41. Therefore the device file proves correct receipt but not program consumption. It also contains only one effective view-distance setting.

Accept the receipt chain. Do not infer that fog consumption, content coverage, culling, sky/clear, or depth behavior is correct.

## Source review

- Touch source diff: empty.
- Canonical ControlPlane diff by worker: empty.
- Dependency revisions: unchanged.
- Renderer correction: none.
- `git diff --check 8140aa4..626b332` reports trailing whitespace on blank lines inside the added dependency patch payloads. This must be corrected before any final source acceptance.

## Disposition

WO31 satisfies a meaningful partial diagnostic milestone but cannot continue within its exhausted diagnostic budget. Close it as ACCEPTED / PARTIAL ACCEPT. Issue WO32 as a new targeted late-session order. It must record only dynamically identified defective R1 draws and post-exterior-receipt R2 applied state before considering a correction.

See [DEC-010](../../Decisions/DEC-010.md), [WO-032](../../WorkOrders/WO-032.md), and the [user coverage clarification](user-amendment2-coverage.md).
