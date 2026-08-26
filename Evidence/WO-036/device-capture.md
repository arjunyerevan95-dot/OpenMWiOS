# WO-036 Device Capture

Status: COMPLETE; ROUTE B / STOP CONDITION C; EXACT ARM A RESTORED

## Required matching views

1. Shoreline/open-water view exposing the blue horizontal band and white cutoff.
2. Tree/terrain-line view exposing distant terrain and black/translucent silhouettes.

## Arm A

- Settings identity: 776 bytes; SHA-256 `744A7C89510C5E9BFD649CBD93739721905589F5C815D8F6430D99BA08A9EC10`
- Diagnostic identity: 162,195 bytes; SHA-256 `18B330E70143CCD7C267E6F869FEC41DB1645EAF044ED32B42F25712164C053D`
- Session: `D32D7DD0-7F4B-4568-A68D-AE8983B67DE9`
- `view_distance=7168`: PROVEN
- `object_paging=0`: PROVEN
- Blue band: PRESENT
- White/fog-colored gap: PRESENT
- Dark/black distant silhouettes: PRESENT
- Nearby terrain, water, sky, HUD, touch, corrected smoke/foliage/spell baseline: no new regression reported or visible in the supplied set
- Crash/jetsam: not reported

### Screenshot identities

- Photo 3: 191,816 bytes; SHA-256 `C54420606997CEF5829A2F2814006BB9B417A8E7F4FA6EB989317195C9FC38CD`
- Photo 4: 193,737 bytes; SHA-256 `74F5D37F63264984B3B9DE6A72A1666020B0F0B169215AA603680574236F837B`
- Photo 5: 198,355 bytes; SHA-256 `7A21F0045457A018A18481C9C3A94B1A2A36094599960FCD4282556FEEB3C4C7`
- Photo 6: 170,375 bytes; SHA-256 `AB91E1C8BE0C1E9552F41600FA265025E22C811CDD910B514CFC5A2874742B0D`
- Photo 7: 187,682 bytes; SHA-256 `C0A732B9C45D4DA7C357E141211A59D60C089BCABACAD2E70E96AC5F4D8AD8B0`
- Photo 8: 132,613 bytes; SHA-256 `2CE88C2DCF317EF149F0C88D05D03E5AA2EABD0C6A675983CC669701EF33CD0B`

## Arm B

- Settings identity: 810 bytes; SHA-256 `CF9D0B05CCCDFCAA925BD40A0A1A94F80EF0C41D492CB5E94178EE59B6736C53`
- Delivery: `https://files.catbox.moe/etltwd.cfg`
- Diagnostic identity: 148,642 bytes; SHA-256 `52993834ACF2BE7FC5D72B7F64E7320A387BAD8D258B1D06AF906092B8DFAE09`
- Session: `0ED5F557-168A-4264-8D66-0B533DB76017`
- `view_distance=7168`: PROVEN (`selected=7168`, `camera_far=7168`)
- `object_paging=1`: PROVEN at two active-grid records
- Large-slider UI: not separately captured; pinned source proves the large-slider route is selected when distant terrain is enabled
- Blue band: PRESENT / UNCHANGED
- White/fog-colored gap: PRESENT / UNCHANGED
- Dark/black distant silhouettes: PRESENT
- Object-paged exterior cells: active; scene composition differs but target defect is not materially corrected
- Nearby terrain, objects, water, sky, HUD, and touch overlay: present with no newly reported regression
- Smoke/foliage/spell effects: not exercised in the supplied Arm B captures
- Crash/jetsam, severe hitching, or memory pressure: not reported

### Screenshot identities

- Photo 1: 139,279 bytes; SHA-256 `DC2555A19753D0897FA9F68A61B0F810662C07A5EBC4C8505EE569FA6C315348`
- Photo 2: 178,870 bytes; SHA-256 `1C27BCFAB771AF17D4EF79F9FF3B0711EC086C53278132E8A30E67BFEC1B39B1`
- Photo 3: 207,267 bytes; SHA-256 `E2EB37C03C04D09CD0B8CB8CE33D197ED8077C4A2A7B45142184DE63A5CF9F49`
- Photo 4: 188,622 bytes; SHA-256 `45017C6A3E7FE5E8AB6BD01639318137CB3484644EBDD6D2A409CE1A4B9E30B5`
- Photo 5: 187,749 bytes; SHA-256 `A71EB04F90D1392EF548EDAD8754CD3429A9F8C8ABCA5B0BCD8778F049E8FE76`
- Photo 6: 175,404 bytes; SHA-256 `ABF6CD7CF36E989B083E0D36198502D4DB2B15FA623E2FDA9EB878BA1C20FA61`
- Photo 7: 156,749 bytes; SHA-256 `B2CB9A554AEF7E507E7291DCED3F14ABB00269787F4382B4508D402F3BCF6AB1`
- Photo 8: 186,915 bytes; SHA-256 `6653A99FE58B700D7D51A3CA30256B0718F06CF8D9561B22A080BC9DD7B538F2`

## Runtime observations

No benchmark claim is made. The supplied captures and diagnostic show a live, traversed exterior session without a reported crash or severe runtime regression. The large-slider UI was not separately captured, and the effects not visible in this Arm B set are not requalified.

## Arm C

- Settings identity: 811 bytes; SHA-256 `E3EEE648AD561F3EC5B950AB63645442256DB62FDEBFD863DF8316AE762A3829`
- Diagnostic identity: 163,291 bytes; SHA-256 `360A209BD9D751493E5C6215E5F369730CE13E09CF16A4A00D9037B92DF8A92C`
- Session: `644CF060-AAD4-42AC-9026-9C8713EE78F8`
- `view_distance=16384`: PROVEN (`selected=16384`, `camera_far=16384`, fog/view end `16384`)
- `object_paging=1`: PROVEN
- Blue band: PRESENT at the farther boundary
- White/fog-colored gap: PRESENT at the farther boundary
- Dark/black fade silhouettes: PRESENT at farther distances where draw distance fades out
- Moderate-distance coverage: MEANINGFULLY IMPROVED
- User observation: "the weird dark silhouette effect still persists now at FURTHER distances, wherever the draw distance is fading out - it didn't solve the problem but just pushed it further out"
- Performance: user observed a modest dip when looking at long vistas; no benchmark claim
- Crash/jetsam: not reported
- Arm D: not run; optional and unnecessary because Arm C already distinguishes displacement from correction

### Screenshot identities

- Photo 1: 186,556 bytes; SHA-256 `D69429A1C94E73C8F193B68BCAD727225EEB58471161830F24A026FDD6265748`
- Photo 2: 217,542 bytes; SHA-256 `626189285939A240786551C66E02FA3EBE3FE7C652D42A4712B92BEC2DE6A68D`
- Photo 3: 176,378 bytes; SHA-256 `7577AA55846D62634BF5B2278EAF0A8F9A7F33410BBBB36BCE6886BDAF7F73E0`
- Photo 4: 180,916 bytes; SHA-256 `7036516B5B9ECFF31F4D4CCD873F63CE883319D084E5A5796BBC42CE5E1549F6`
- Photo 5: 217,906 bytes; SHA-256 `AF7C699259AC248E7F631907D960D21D3D9F88CB5BF810F27C48DDA19040826A`
- Photo 6: 194,207 bytes; SHA-256 `C568ED83E7ADDAFFB2F58F775AC37CD5367540896924E84C73679ABD19925E3C`

## Restoration result

- Post-Arm-B restoration was completed and user reported `Launched normal`.
- Final post-Arm-C restoration to exact Arm A (776 bytes; SHA-256 `744A7C89510C5E9BFD649CBD93739721905589F5C815D8F6430D99BA08A9EC10`) is COMPLETE.
- User confirmation: `Done`

## Interim orchestrator review

- Arm A/B trustworthiness: PROVISIONALLY ACCEPTED
- Constant-distance result: accepted (`object_paging 0 → 1`; blue band, white gap, and silhouettes remained)
- Stop Condition C after Arm B alone: NOT ACCEPTED
- Required continuation: Arm C at 16384 with paging active, matching views, then restore Arm A

## Final classification after Arm C

- Route: B — paging/higher distance only moves the boundary
- Stop condition: C — distant-terrain and higher-distance hypothesis falsified
- Strongest conclusion: the configured camera/fog radius controls where the visible failure begins, but is not its root correction
