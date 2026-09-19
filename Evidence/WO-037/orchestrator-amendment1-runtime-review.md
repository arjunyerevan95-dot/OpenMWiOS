# WO-037 Amendment 1 runtime-diagnostic review

- Review date: 2026-08-29
- Disposition: **AMENDMENT REQUIRED**
- Accepted engineering baseline: `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9` — unchanged
- Repair commit: `9f5cfee61a450d628901d8bc08da1ddaf441fbfb`
- Worker evidence commit: `c890fcda3178c36bc34ae2e99760c971dc9dd4ec`

## Source and repository review

The pushed worker branch `codex/wo37-distant-pixel-attribution` is clean at the evidence commit. Amendment 1 changed the runtime diagnostic only from `LOAD_GLES_FPE(glReadPixels)` to pinned-source-correct `LOAD_GLES(glReadPixels)` and added deterministic loader/patch-stack validation. No canonical CURRENT_STATE, WorkOrders, or Decisions file changed.

The report, manifest, diagnostic design, target-capture record, request-loader device record, and CI identity are accepted as execution evidence only. The diagnostic branch remains unaccepted product state and does not advance the accepted engineering baseline. The unlisted Gist is a convenience mirror; the repo-backed report at the evidence commit is authoritative execution evidence.

## CI and artifact verification

- Fast run `33019021667`: completed / success at head `9f5cfee61a450d628901d8bc08da1ddaf441fbfb`.
- Run interval: 2026-08-26 22:16:10Z to 23:57:47Z.
- Patch bootstrap, dependency preparation, production OpenMW compile/link, bundle validation, packaging, and artifact upload passed.
- Artifact `OpenMW-iOS-fast-60`, ID `9628038289`, is not expired and has digest `sha256:489e24849b01f88a47cfed96b69349d1c71434b325194b9a7d8bd239ce2e7259`.
- Reported IPA SHA-256: `898BA0F25BB6B1A76050FDDB0558721A50ADF2A08E1F067E5D670D6AE10EC96B`.
- No duplicate run or Full Qualification occurred.

## Device result

The exact IPA installed and rendered normally, but two fresh sessions recorded `target_request=none` and zero `r3.*` records:

- `1FCD125A-6ADC-45DA-88E2-ABA46D46B974`, JSONL SHA-256 `013ac7a91762a5a01eb497662fd99e0a3dd568392cb4abddae4868a40940b791`;
- `DEA6C1B8-C370-4561-B752-013882C79087`, JSONL SHA-256 `d3526ac3be040da5230d9f546b1ee77a275c84dec7d659a61af12c55bf0a8e2a`.

Independent Files screenshots establish the exact 21-byte UTF-8 request, filename, content, same-folder placement, and chronology before the second JSONL. User placement is accepted as correct.

## Exact trigger boundary

Direct source inspection establishes:

1. diagnostic startup derives the request and JSONL paths from the same Foundation Documents/OpenMW directory;
2. it creates/truncates the JSONL, reads `renderer-target-request.txt` once with `stringWithContentsOfFile`, ignores the returned error, and never retries;
3. the later first changed exterior-fog generation already owns the one-shot arm transition; and
4. only `sTargetRequest.empty()` prevents that existing transition from arming.

Therefore the failure is in the diagnostic activation prerequisite, not in the proven native loader repair and not yet in the renderer attribution path. The available evidence does not distinguish Files materialization, one-shot timing, or Foundation read failure. Investigating that distinction would not advance the renderer objective.

## Disposition

Accept Amendment 1 build/device evidence and Stop Condition B. No renderer result or correction is accepted.

Issue WO37 Amendment 2 as READY to preserve valid explicit requests while falling back to a fixed auto-first-exterior diagnostic label when the request is unavailable. Authorize the third and final original Fast slot for that diagnostic candidate and reallocate the unused correction slot. If target attribution is obtained, stop and issue any renderer correction separately; WO37 may not perform another build.

See [WO-037 Amendment 2](../../WorkOrders/WO-037.md).
