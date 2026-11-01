# WO-040 — Integrated IPA accepted for device testing

- Review date: 2026-11-01
- Disposition: **PARTIAL ACCEPT — implementation, automated checks and unsigned package accepted; device runtime/controls not yet qualified.**
- [WO-040](../../WorkOrders/WO-040.md) closed at stop C. No active/ready order; no remaining build budget. [DEC-018](../../Decisions/DEC-018.md) stands.

### What was verified

The [worker report](https://github.com/arjunyerevan95-dot/OpenMWiOS/blob/d24d65cdae7c580fea5cc4a833f26ffee37c95c6/Evidence/WO-040/report.md) and companion integration, validation and manifest were reviewed. The clean local execution checkout and remote branch `codex/wo40-zink-touch` agree at evidence commit `d24d65cdae7c580fea5cc4a833f26ffee37c95c6`. Relative to built commit `f4d9f9d8d6bcba1b3bc59201724aab62627aaa4e`, the final commit changes only three evidence files.

Git confirms ancestry from pinned joedemo42/OpenMW `2931be63bd2147e437a2b077ed6c97f563648a0a`. The implementation diff is confined to the touch adapter/model, platform/input hooks, build/CI, validation and evidence. Source inspection confirms explicit iOS input-manager install/mode/teardown hooks, short/long Menu arbitration and observable SDL Pause edges. Protected renderer/dependency paths, shaders, MetalFX, first-launch source, iOS toolchain and Xcode project specification are unchanged. No canonical or old renderer patches are in the execution diff.

Exactly two candidate-branch runs: [primary](https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/41199873586) failed on the version-check broken pipe before compilation; [repair](https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/41200954123) succeeded on the exact built commit. Its log confirms 132 executable input/layout/profile checks; device compile/link, unsigned packaging and upload passed. The worker also reports 132 checks on Windows MSVC. These are not on-device input tests.

### Deliverable

- [GitHub artifact 13044247922](https://github.com/arjunyerevan95-dot/OpenMWiOS/actions/runs/41200954123/artifacts/13044247922) — IPA, matching dSYM, manifest and logs; expiry November 30, 2026.
- Preserved local IPA: `C:/Users/arjun/Documents/Codex/2026-08-14/you-are-taking-over-an-existing-2/.candidates/wo40-zink-touch/DerivedData/wo40-delivery/DerivedData/wo40-artifact/OpenMW-Zink-Touch-unsigned.ipa`.
- Local byte-level review: ZIP integrity passed for IPA and dSYM. IPA: 26,317,147 bytes, SHA-256 `50890e180c42bdfe5c77c5c8b40aae3ea28d7534fd31958bed3f3b24d22dc620`. Executable SHA-256 `b80a8ae91a462948cd3d678ba3241262881232037f0656976387ca18abe5f76b`; arm64 executable and dSYM UUID `8D3AFF23-3332-305A-A4D1-E75003429268`. No executable code-signature command, bundled signature directory or embedded provisioning profile.
- Info.plist: `OpenMW Zink Touch`, `org.openmw.ios.zinktouch`, minimum iOS 18.0. Distinct from the old app; preserve existing saves/data. IPA must be signed by the user's sideloading tool.

### Outstanding evidence

After sideloading and loading a game, check movement/look/actions, a single short Menu action, a 0.75-second hold opening the editor without Pause, move/resize/opacity, and persistence after Done and relaunch. Also note duplicate or stuck input on release/backgrounding or external-controller handoff when available. If there is a failure, record the exact action and result before proposing a repair. Stock rendering/performance comparison remains waived; do not request a horizon capture.

WO33 `93f892dd0cf9834259b4cad2045ddb2ef9c53ed9` remains the last physical-device-qualified runtime. No merge to main, release publication, third build, or new worker dispatch is authorized by this review.
