# WO-037 Target-Pixel Captures

Status: pending diagnostic IPA.

All captures must use restored WO36 Arm A settings: view/fog distance `7168`, accepted terrain configuration, `sky blending = true`, and `sky blending start = 0.8`.

| Session label | Target | Screenshot SHA-256 | JSONL SHA-256 | Classification |
|---|---|---|---|---|
| `wo37-black-silhouette` | hard black silhouette/cap centered under crosshair | pending | pending | pending |
| `wo37-fading-comparison` | similar-distance object fading normally | pending | pending | pending |
| `wo37-white-region` | pale/white horizon region centered | pending | pending | pending |
| `wo37-blue-band` | sharp blue band centered | pending | pending | pending |

Each launch must contain only its matching request label in `renderer-target-request.txt`, then preserve the resulting bounded `renderer-diagnostic.jsonl` before the next launch.
