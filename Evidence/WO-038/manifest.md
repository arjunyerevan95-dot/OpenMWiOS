# WO-038 Evidence Manifest

Status: **IN PROGRESS**

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
- [Target-pixel captures](target-pixel-captures.md)
- [Execution report](report.md)

## External identities

- Prior failed Fast run establishing the cold-config boundary: `33265712820`
- Prior failure artifact: `OpenMW-iOS-fast-failure-63`, ID `9718681291`
- Prior failure digest: `sha256:c7cc2fea29cf86ae6e8c16d78ee237c18487ef4e56409ffc6547c49a4966676e`
- WO38 Fast run/artifact/device identities: pending

No IPA, screenshot, framebuffer dump, full shader dump, or raw JSONL is committed here.
