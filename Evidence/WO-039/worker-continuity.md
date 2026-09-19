# WO-039 — Replacement Worker Adoption

- Date: 2026-09-19
- Author: orchestrator
- Disposition: **READ-ONLY ADOPTION ACCEPTED; REASSIGNED; WO39 STILL READY AT THIS CHECKPOINT**
- Orchestrator: `01a02593-1ac3-76f1-9978-0a877bdc0484`
- Previous worker: OpenMW Instrumentor, `019ffd24-a544-7153-9790-108f7079471e`
- Replacement worker: OpenMWiOS Astra Worker, `01a0b99a-8578-7503-bc57-a9665b14950f`

## Reason and authority

The previous worker failed during remote context compaction while receiving the status-only WO39 notice. The app reported `systemError`; the failed turn contained no worker acknowledgment. Message delivery was not successful adoption or a start. The user authorized a fresh worker and supplied the read-only bootstrap manually. The original thread/history and repository remain preserved.

The user-created replacement identifies as Astra, rather than the initially discussed SOL. The orchestrator preserves that thread's setting; no model override is sent. This is worker continuity, not a change of engineering direction or an additional implementation owner.

## Adoption verified

The replacement delivered its acknowledgment directly to the orchestrator and stopped. A read of the new thread confirms its adoption turn completed and its status is idle.

- Canonical branch: `codex/wo29-ios-crash-isolation`, HEAD `daefee6dabe9d6d44d57ce48771c1fe19bd31cb7`, clean. Orchestrator independently verified the remote tip.
- WO38 execution branch: `codex/wo38-cold-osg-attribution`, HEAD `7dbedda156b9ab2de1b23f7119f58a6f6a0d6667`; tracked files clean, untracked `.artifacts/` preserved. Orchestrator independently verified local/remote HEAD.
- Worker verified accepted runtime `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9` is an ancestor of the execution baseline, not of the canonical branch. Canonical authority must not be merged as product source.
- Worker read CURRENT_STATE, WO39, DEC-017 and WO38 final review, and correctly distinguished READY from execution authority.
- Worker independently verified preserved IPA size `39159562` and SHA-256 `9312EA3B1AD757E9CEE8A22785907F93AD9C68A33E02D845210FF5F733660593`.
- No WO39 branch/worktree or engineering execution existed at adoption.

## Preserved discrepancies and location guard

The worker reported six pre-existing untracked diagnostic files in WO38 `.artifacts/wo38-amendment1/diagnostics/`. The root checkout remains on WO36 with a modified `docs/ios-port-ledger.md` and historical untracked files/caches; WO37 remains at its recorded baseline. These are not cleaned, moved, reset or attributed to the replacement.

The new thread's default cwd is an unrelated Gmail runtime. All adoption reads used explicit OpenMW paths. WO39 now requires explicit OpenMW workdirs and a separate WO39 worktree after activation; no project work may be written into the default cwd.

No files, branches, tests, builds, CI runs, device settings or indexes were changed by adoption. The previous worker is not being restarted or sent another message. The assignment change supersedes only WO39's old named-worker/no-replacement clause; every scope, acceptance and budget restriction remains unchanged.

## Next authority event

This assignment is published while WO39 remains READY. Only a subsequent explicit start directive from the orchestrator activates execution. The start and READY -> ACTIVE transition must be recorded separately; this acknowledgment itself is not a start.

## Subsequent activation — 2026-09-19

The READY assignment was committed and pushed as `4cd82f9aac0f2561bca8ac5470851287b1c8ee6c`. After that publication, the orchestrator delivered the explicit `Start WO-039 now` directive directly to replacement thread `01a0b99a-8578-7503-bc57-a9665b14950f`. Delivery returned that thread ID without error. The directive names the published canonical order and exact continuation baseline, repeats the explicit-workdir guard and zero-production/CI scope, and requests a brief start receipt followed by execution to the review gate.

WO39 is now ACTIVE, recorded in a separate canonical activation commit. The adoption disposition at the top describes the preceding READY checkpoint, not the current work-order state. No start directive was sent to the failed original worker. The worker's receipt/execution result remains separate evidence; this delivery record does not accept any technical result.
