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

## Amendment 1 ownership repair

ControlPlane commit `3265016fd1d583e98bebf1379eea95853a85674e` authorized one replacement diagnostic build after a narrow repair of the proven MRC lifetime defect. Commit `8140aa4ee2af00e335b9212605524883571e65ed` changes only the two persistent assignments:

- `sPath` is assigned a copied path string;
- `sSession` is assigned a copied UUID string.

Both objects therefore remain owned after the startup autorelease pool drains. They intentionally live for the process lifetime. The translation unit remains under the existing MRC production semantics; no ARC or build-system change was introduced.

The focused suite now has 11 tests. Its lifetime check accepts the copied assignments and rejects a synthetic source variant containing the original raw autoreleased assignments. The existing path, schema, enablement, record budgets, total file cap, correlation design, OpenMW probes, and GL4ES probes are unchanged.

Replacement Fast run `32588069228` compiled, linked, bundle-validated, packaged, and uploaded the exact repair successfully. The replacement artifact has IPA SHA-256 `498D0285103C0F3664F44F35004FF1ADD8D463A6ACB6F4E5C11C4CE682A6C9CD`, executable SHA-256 `5AA12617933D031E25D06C590BEA15507CC7CA863DB63EEBDC91FDBC994F2D40`, and Mach-O UUID `56699F22-BA7C-3E7D-B5B6-0B9CEBB0AFC8`.

The exact replacement candidate reached exterior runtime without the prior crash, proving the copied ownership survives the startup autorelease-pool boundary. The retrieved file was 7,028 bytes (SHA-256 `5A6113914B4D90EEF274588E8914CA01D37F53BFB4CAB45DAE22F8E8ABD5FAC0`) and contained one startup plus 22 later OpenMW records in session `02306F28-5A6E-45AB-ADAC-414235769F83`.

It contained zero GL4ES records and zero R2 records. The 22 OpenMW records were 21 `r1.state` records and one `r1.asset` record; the asset was the non-translucent control texture `textures/_land_default.dds`, not a correlated defective foliage or particle sample. Therefore the required intended-versus-applied correlation was not established. Amendment 1 stops under Condition B; the final renderer-correction build was not used.

## Amendment 2 observable-path design and result

Commit `626b3321ee7ce83f82d22a707dfa4f9177cf6fff` supplements the original probes without changing renderer state:

- guaranteed GL4ES handshake at `gl4es_GetProcAddress`;
- OSG registers the actual GL texture object name with the app bridge after `Texture2D` upload;
- GL4ES draw records look up the stable texture-name mapping rather than depending solely on byte hashes across compression/conversion boundaries;
- fog receipt and applied-program observations run on the active GL4ES draw route;
- OpenMW records fog intent where the OSG `Fog` state is actually applied.

The deterministic fixture materializes the patched GL4ES diagnostic translation unit, compiles and links it with an app-side bridge, executes it, and requires a GL4ES handshake plus R1 draw and R2 received/applied records. Production Mach-O UUID `9A5D277A-AC2B-3E86-9E18-D1E85985EC88` retains all probe and bridge definitions. Direct AArch64 call inspection confirms every `_wo31_diag_*` function resolves to the corresponding `openmw_ios_renderer_diag_*` functions.

The physical-device file proves both handshakes and all probe families can write. Its SHA-256 is `DE23923768DC05B302BC9FF4FF11AB4ECD7EF62579123A5667BB9076549DD0E9`. The remaining insufficiency is temporal budget ordering:

- `r1.draw` exhausts at sample 199; defective asset-to-texture bindings begin at sample 210;
- `r2.applied` exhausts at sample 41; exterior fog receipt begins at sample 324.

Thus the channel is linked and active, but it still does not capture the mandated representative late exterior correlations. Amendment 2 permits no second diagnostic redesign build.
