# WO40 candidate manifest

- Date: 2026-10-31. Worker: OpenMWiOS Astra Worker, 01a0b99a-8578-7503-bc57-a9665b14950f.
- Canonical READY publication/start authority: b8bf69b4b73f991a35eecb0029dff812c3e2310b plus explicit orchestrator directive; canonical activation subsequently observed. Canonical files are outside this checkout and untouched.
- Foundation: [joedemo42/OpenMW v0.52-149](https://github.com/joedemo42/OpenMW/tree/2931be63bd2147e437a2b077ed6c97f563648a0a), exact 2931be63bd2147e437a2b077ed6c97f563648a0a; verified by ls-remote before clone and local HEAD after clone.
- Checkout: C:/Users/arjun/Documents/Codex/2026-08-14/you-are-taking-over-an-existing-2/.candidates/wo40-zink-touch.
- Branch: codex/wo40-zink-touch. Origin: arjunyerevan95-dot/OpenMWiOS. Upstream reads: joedemo42/OpenMW; its push URL is locally disabled. No force push or old-history merge.
- Exact touch donor: 93f892dd0cf9834259b4cad2045ddb2ef9c53ed9, four ios/openmw_ios_touch* files. Selective Pause lifetime adaptation: 457ab881442302a9bd59435c1878ed4e72f6e52b. No other WO38 source imported.
- Existing root/WO37/WO38 and local IPA preserved. Root ledger edit, historical untracked handoffs/caches and WO38 diagnostics were already present. Neither WO39 checkout nor branch existed; its interrupted creation did not complete.
- Graph query: OpenMWiOS not indexed; only black-ios-v1.5.4 and cosmetiq-kerala-v9 returned. Direct source used; no reindex.
- Initial CI snapshot: unrelated completed/action_required PR run 40158810951 (2026-10-25), last successful iOS build 33306995685 (2026-08-30); no active project run. Actions-policy API returned 403; repository API confirmed push permission. No permissions/settings changed.
- Renderer/dependency identity: ios-deps recipes/patches/build script, all mwrender, shaders, MetalFX, firstlaunch, iOS toolchain and project.yml retained verbatim. OSG 01cc2b585c8456a4ff843066b7e1a8715558289f, SDL 2.32.10, Mesa 25.1.9, MoltenVK 1.4.2.
- Candidate bundle: org.openmw.ios.zinktouch / OpenMW Zink Touch; iOS 18+, unsigned arm64. Original increased-memory-limit entitlement remains in source; unsigned artifact carries no provisioning credentials. The eventual sideload signer controls granted capabilities.
- Build limit: primary + at most one evidenced repair, maximum two macOS runs. Results/run/artifact hashes will be recorded in report.md and generated artifact manifest.json.
- Licensing/provenance: donor LICENSE, AUTHORS.md and ios/licenses unchanged. Ported controls/icons retain historical source content and notices; source attribution is in integration.md. No public release/upload service.
