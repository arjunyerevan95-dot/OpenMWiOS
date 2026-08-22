# WO-031 renderer diagnostic channel

## Purpose

WO-031 requires representative OpenMW/OSG intent to be correlated with GL4ES received/applied state without live usbmux or the warning-flooded `openmw.log`. The diagnostic build writes a separate, bounded JSON-lines record to the app-owned logical path:

`Documents/OpenMW/renderer-diagnostic.jsonl`

The absolute iOS sandbox prefix is resolved at runtime with `openmw_ios_documents_path()` and is neither persisted nor written into the records.

## Schema and correlation

Every record contains:

- `schema`: `openmw-ios-renderer-diagnostic-v1`
- `session`: a UUID generated once per launch
- `sample`: a monotonically increasing bounded sample identifier
- `family`: probe family
- `source`: `ios`, `openmw`, `gl4es`, or `budget`
- `correlation`: texture-content hash, GL texture/program identifier, or milestone name
- `detail`: bounded semicolon-delimited state values

R1 correlation is content-based:

1. OpenMW classifies a narrowly selected image path and hashes its level-zero bytes after image preparation.
2. GL4ES hashes the corresponding compressed or raw texture upload.
3. The shared hash associates the OpenMW asset identity and intended alpha state with the GL4ES texture identifier.
4. Later GL4ES draw records use that registered texture identifier and capture the applied blend, alpha-test, fog, and program state.

R2 correlation is state-based within the same launch session:

1. OpenMW records intended exterior fog start/end/far/color.
2. GL4ES records received fog calls.
3. GL4ES records the built-in fog values applied to realized programs.

## Budgets

| Family | Record budget |
|---|---:|
| `r1.asset` | 48 |
| `r1.upload` | 48 |
| `r1.draw` | 96 |
| `r1.state` | 48 |
| `r2.intent` | 16 |
| `r2.received` | 32 |
| `r2.applied` | 32 |
| unknown/default | 8 |

The total file is capped at 256 KiB. Each exhausted family emits at most one exhaustion record. The file is truncated at diagnostic-session start and each accepted record is appended through a short-lived file handle so a user can retrieve it after normal app termination. GL4ES diagnostics are read-only and do not change GL state.

## Enablement and retrieval

The bridge defaults disabled unless `OPENMW_IOS_RENDERER_DIAGNOSTICS=1`. The WO-031 diagnostic candidate sets that gate during iOS bootstrap. After reproducing the exterior defects, the tester can share `On My iPhone/OpenMW/renderer-diagnostic.jsonl` without connecting usbmux.

## Deterministic validation

- `validation/test_wo31_renderer_diagnostic_channel.py` covers the logical path, environment gate/default, schema, budgets/file cap, shared R1 correlation, R1/R2 field coverage, GL-state non-mutation, registered-texture filtering, and deterministic patch-stack inclusion.
- All OpenMW patches through `0013` apply in order to pinned OpenMW `f4bec41444214a7903bebd178389ca22ca13f646`.
- All GL4ES patches through `0006` apply in order to pinned GL4ES `c9895df34cd466c23bc60c2bd3db3d87e98fcbe7`.

## Physical-device result

The diagnostic IPA installed and launched, displayed the loading screen for approximately half a second, and then hard-crashed. The retrieved file was only 253 bytes and contained exactly one valid `session/startup` record:

- Session: `C0912F7F-958B-4FC5-BA81-379A75345C7D`
- File SHA-256: `16F3B558437016BE03447688D3D7B26465FCF9B466C897B5B0D01F951139851A`
- OpenMW records: 0
- GL4ES records: 0

The successful startup record proves path creation, truncation, schema serialization, and the initial write. It does not prove later record append or representative renderer correlation.

## Earliest evidenced diagnostic regression

`openmw_ios_renderer_diag_begin()` runs inside an explicit autorelease pool. `beginLocked()` assigns autoreleased Foundation objects to the persistent raw globals `sPath` and `sSession`, then the pool drains. The OpenMW target has no repository CMake/Xcode ARC enablement (only the unrelated bundle probe explicitly enables ARC), and the CI compile invocation for `openmw_ios_renderer_diagnostics.mm` contains no explicit ARC option outside its response file. The first later renderer record dereferences those persistent objects through `appendRecord()`.

This source lifecycle error is consistent with all observed evidence: the startup write succeeds while the objects are alive, no second record is committed, and the app crashes as rendering begins. No R1/R2 correction was attempted. WO-031 stopped under Condition F without consuming a second build.
