# WO-035 Device Capture

Status: COMPLETE — Arm B retained by explicit user choice

## Required matching views

1. Shoreline/open-water view exposing the blue horizontal band and white cutoff.
2. Tree/terrain-line view exposing far terrain and pure-black silhouette behavior.

## Arm A observations

- Screenshot identities: PENDING
- Blue horizontal band: PENDING
- White/fog cutoff: PENDING
- Pure-black distant silhouettes: PENDING
- Near scene regression: PENDING
- Process/crash status: PENDING

## Arm B observations

- Screenshot identities: ten 1280x589 JPEG captures received under attachment set `347EC5DA-8081-4FE4-8C26-CB620CEA70EB`.
- Blue horizontal band: PERSISTS; plainly visible in shoreline and terrain-line captures.
- White/fog cutoff: PERSISTS; still materially present behind water, terrain, and trees.
- Pure-black distant silhouettes: CHANGED BUT NOT RESOLVED. User reports that objects which were continuously black at some distances now become translucent and fade in at certain distances/angles, but remain solid black at other distances/angles. The image set contains both translucent/faded distant trees and persistent dark/black terrain/tree silhouettes.
- Nearby terrain/water/sky/HUD/touch: no new regression reported in this capture.
- Smoke/foliage: previously qualified corrections remain visually present; no new regression reported.
- Process/crash status: application remained usable through exterior traversal; no crash reported.

### Screenshot SHA-256 identities

- Photo 1: `B44892C7E8F5ABADA590373829FA45EE5967AE05A0FC3BE093AA25D0AF930449`
- Photo 2: `B0BFEE7924EF36F958253879D0E0E2C968D911F66B993548DFCDFB3B9C6CF340`
- Photo 3: `1E9624FDB45492650D5FEA64E227A731FAFEDB54FD0858E4E004677D9A78A810`
- Photo 4: `E55F89B905C305228C097DE29F7B528629697256CF7A408A382312DD6AA3E0C4`
- Photo 5: `3499EB3EE9A93895375332EABD762D8967015157C505066525AE13F2BDB1CEED`
- Photo 6: `CBB02F80AA464383C6256F1CC35566A69C99396E111F0E4EF7C0B9B89C943FEC`
- Photo 7: `E857DFDE03A29502F394BD205201E520AF2888307996425F16F9D377795C85B9`
- Photo 8: `47595E8B23D227CFC2C4780CDAE740F96947ED49BEB40275057704B32B4209DE`
- Photo 9: `2E0BB30CC007A6A6B7A7FC3BA5FB972313A945333898F70D0890B6EE82920173`
- Photo 10: `B0F28020FB73AB98DC436BEDE9EBA072E280CD8FDEE71AE3D960EA622B352C23`

## Classification

- Visible A/B: a material change exists only in angle/distance-dependent silhouette fading; the target blue/white cutoff did not materially improve.
- Sky-blending hypothesis for the WO-035 target cutoff: FALSIFIED. Fresh diagnostic session `AFEF6F3A-DD3C-402D-AF51-9D91BECAE505` proves `sky_blending=1`, while matching physical views retain the blue horizontal band and white/fog-colored cutoff.
- Black-silhouette boundary: sky blending influences its presentation but does not eliminate it; it remains a separate unresolved boundary.

## User follow-up hypothesis (recorded, not executed)

The user proposed testing a view distance above the current `7168` limit to see whether moving the far boundary reduces visible artifacts. WO-035 explicitly prohibits changing camera/view distance. This observation is preserved for orchestrator review and does not amend or broaden this execution.
