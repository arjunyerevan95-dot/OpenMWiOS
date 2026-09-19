# WO-035 Source and Setting Proof

## Effective configuration ownership

Direct source inspection establishes this startup chain:

1. `ios/openmw_ios_paths.mm::openmw_ios_documents_path()` resolves the current application Documents directory with Foundation `NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)`.
2. `ios/openmw_ios_bootstrap.mm::openmw_ios_prepare_environment()` defines `root = documents / "OpenMW"`.
3. The bootstrap passes `--config <root>` to OpenMW.
4. OpenMW therefore reads the effective `settings.cfg` from `<current Documents>/OpenMW/settings.cfg`.

User-visible Files location:

`On My iPhone/OpenMW/OpenMW/settings.cfg`

This path contains no persisted sandbox UUID.

## File-backed diagnostics

`ios/openmw_ios_bootstrap.mm` sets `OPENMW_IOS_RENDERER_DIAGNOSTICS=1` before renderer initialization. `ios/openmw_ios_renderer_diagnostics.mm` writes the bounded JSONL stream to:

`On My iPhone/OpenMW/OpenMW/renderer-diagnostic.jsonl`

The diagnostic writer advertises a 262,144-byte cap. WO-035 does not require live usbmux logging.

## Setting definition and default

Pinned OpenMW `files/settings-default.cfg` defines under `[Fog]`:

```ini
sky blending = false
sky blending start = 0.8
```

The setting's source comment says it blends the sky into distant geometry to hide the clipping plane.

## Runtime ownership

Codebase Memory and direct source inspection show:

- `RenderingManager::RenderingManager` reads `Settings::fog().mSkyBlending` during renderer construction.
- It sets the global shader define `skyBlending`.
- It constructs `SharedUniformStateUpdater` with `mSkyBlendingStart`.
- When enabled, it reserves the sky texture unit and enables the sky RTT.
- `components/sceneutil/stateupdater.cpp` computes `skyBlendingStart = far * coefficient`.
- `files/shaders/compatibility/fog.glsl::applyFogAtDist` blends scene color toward the sampled sky between `skyBlendingStart` and the far plane when `@skyBlending` is enabled.

Consequently, force-quit and relaunch are required after changing the setting; a live toggle inside an already-constructed renderer is not treated as valid qualification.

## Expected falsifiable effect

If the exterior white/blue cutoff is caused by the far-plane transition that this feature owns, enabling sky blending at `0.8` should materially soften or eliminate that cutoff while leaving near scene rendering intact. Pure-black distant silhouettes are classified independently and are not assumed to share this cause.
