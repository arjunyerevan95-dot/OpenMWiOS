# WO-037 Request-Loader Device Evidence

## Result

The diagnostic request-file activation contract did not operate on the physical device even though the request file was demonstrably named, encoded, populated, and placed correctly.

## Runtime evidence

Two replacement-IPA sessions independently emitted the startup record with:

`enabled=1;path=Documents/OpenMW/renderer-diagnostic.jsonl;max_bytes=262144;target_request=none`

Neither session emitted any `r3.*` family record.

| Session | JSONL SHA-256 | `r3.*` records |
|---|---|---:|
| `1FCD125A-6ADC-45DA-88E2-ABA46D46B974` | `013ac7a91762a5a01eb497662fd99e0a3dd568392cb4abddae4868a40940b791` | 0 |
| `DEA6C1B8-C370-4561-B752-013882C79087` | `d3526ac3be040da5230d9f546b1ee77a275c84dec7d659a61af12c55bf0a8e2a` | 0 |

## Independent Files evidence

Tester screenshots prove:

- file name: `renderer-target-request.txt`;
- visible content: `wo37-black-silhouette`;
- size: 21 bytes (the exact UTF-8 label without a trailing newline);
- encoding: UTF-8;
- line endings: LF;
- placement: same OpenMW Files directory as `renderer-diagnostic.jsonl`;
- chronology shown by Files: request file at 20:09, replacement session JSONL at 20:24.

Screenshot SHA-256 identities:

- exact-name/content preview: `5253c6248341c54b79289e6c44ba5c4cbf5d1e27a78fcf6ef27c2c3a40f44b17`;
- same-folder directory view: `83af0a4168de0ab3cc4bbd5ccc85b8f2b4f4e3f0d58985e2c74ce34f45be801c`;
- UTF-8/LF/name metadata: `51946b2f6452fa23950856d5bbcb1b71476cc541f053a6057d835421e905cc2f`.

## Boundary

This contradicts the expected activation behavior but does not identify whether Foundation path resolution, Files-provider materialization, request read timing, or another diagnostic-only boundary is responsible. Amendment 1 authorizes neither a diagnostic redesign nor a third diagnostic build. The correct disposition is to preserve the contradiction and stop for orchestrator review.
