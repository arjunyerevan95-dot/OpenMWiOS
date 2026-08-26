# WO-037 Evidence Manifest

Status: blocked at changed-source compilation; no diagnostic IPA produced.

## Authority and identity

- Canonical order: `WorkOrders/WO-037.md` at ControlPlane commit `ba22bbe967c8ebad0cffd9e3e252da978cd18224`
- Accepted engineering baseline: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`
- Execution branch: `codex/wo37-distant-pixel-attribution`
- Pinned OpenMW: `f4bec41444214a7903bebd178389ca22ca13f646`
- Pinned OSG: `01cc2b585c8456a4ff843066b7e1a8715558289f`
- Pinned GL4ES: `c9895df34cd466c23bc60c2bd3db3d87e98fcbe7`

## Records

- [Execution report](report.md)
- [Source and attribution model](source-and-attribution-model.md)
- [Diagnostic design and tests](diagnostic-design-and-tests.md)
- [Fast build failure](build-failure.md)
- [Target-pixel captures](target-pixel-captures.md)

## Build and artifact evidence

- Diagnostic source commit: `7dc76a962fb5cd54494a41296b138badee15038a`
- Fast Development run: `33002709474` (failure)
- Failed boundary: changed GL4ES `drawing.c` compilation
- Artifact ID/digest: NOT PRODUCED
- Executable SHA-256 / Mach-O UUID: NOT PRODUCED
- IPA SHA-256: NOT PRODUCED

## External evidence

No raw IPA, screenshot, framebuffer, shader dump, or device capture was produced. The completion report is published as an unlisted GitHub Gist, per tester preference.
