# WO-038 Evidence Manifest

Status: **AMENDMENT 1 IN PROGRESS — LOCAL PAUSE CORRECTION VALIDATED**

## Baselines

- Accepted engineering baseline: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9`
- Reviewed WO37 evidence continuation: `7c17095ff876909e31e4c7e63702fff52b237373`
- WO37 diagnostic source candidate in that ancestry: `fbddf1f65fef8d3d56e5ee9b3511e0b72198163d`
- Execution branch: `codex/wo38-cold-osg-attribution`
- Published ControlPlane order: `52e905c85524f3efaaece9a840e0fe0c24d18193`

The accepted engineering baseline is an ancestor of the execution branch. The reviewed WO37 continuation adds only bounded renderer diagnostics, their fixtures/tests, and evidence. WO38 adds only the narrow cold-OSG configuration recovery, its regression fixture, and this evidence directory.

## Records

- [Cold OSG configuration](cold-osg-configuration.md)
- [Diagnostic validation](diagnostic-validation.md)
- [Pause short-tap correction](pause-short-tap-correction.md)
- [Target-pixel captures](target-pixel-captures.md)
- [Execution report](report.md)

## External identities

- Prior failed Fast run establishing the cold-config boundary: `33265712820`
- Prior failure artifact: `OpenMW-iOS-fast-failure-63`, ID `9718681291`
- Prior failure digest: `sha256:c7cc2fea29cf86ae6e8c16d78ee237c18487ef4e56409ffc6547c49a4966676e`
- WO38 correction/evidence commit: `f3ccd53e1fa823e583057afd15e8a5ce94d0ab97`
- Fast Development run: `33269657425` (success)
- Run URL: <https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/33269657425>
- Product artifact: `OpenMW-iOS-fast-66`, ID `9720624645`
- Artifact digest: `sha256:17b27b5a0b4a957dafefb9792f545b0fed8826955b7ebdbb9c5f878148f9d8ed`
- IPA SHA-256: `d66f5c31a50a48a8a35c8b5e9bc74e558d224c2da9d0debf8072f8b61df194ee`
- Executable SHA-256: `3d0308bb45d1823b441c4bb627846eb92c239c24e57aa4238a6ac1105c949d54`
- Mach-O UUID: `0FBDA93C-0871-39E6-A80D-C16B14606AC3`
- Device target-pixel identities: pending
- Mirrored unlisted report Gist: <https://gist.github.com/arjunyerevan95-dot/f440c84042db917388a74cc2186fcc38>

## Amendment 1 continuation

- Amendment authority: published ControlPlane `ae3fa28`; exact continuation `6f3eb24ae9be73950c3813964755169497bcc26e`.
- Source cause revalidated: virtual START true/false collapsed before SDL's later virtual-joystick update.
- Local correction: preserve the pressed state through one explicit SDL joystick update, then store one release.
- Executable fixture result: passed; cancellation and long-press suppression passed.
- Exactly one Amendment 1 Fast dispatch remains authorized; not yet consumed in this record.

No IPA, screenshot, framebuffer dump, full shader dump, or raw JSONL is committed here.
