# WO-037 Target-Pixel Capture Status

## Amendment 1

Two fresh physical-device sessions from the qualified Amendment 1 IPA remained unarmed (`target_request=none`, zero `r3.*` records) even though independent Files evidence showed the correctly named 21-byte request file beside the diagnostic log before the second session. Those identities remain in `manifest.md` and `request-loader-device-evidence.md`.

## Amendment 2

No target-pixel captures exist.

The auto-first-exterior fallback was implemented and validated locally, and its complete ordered patch stack passed CI bootstrap. However, final Fast run `33265712820` failed during CMake configure before product compilation. No executable or IPA was produced, so the fallback could not be installed or exercised on device.

Accordingly:

- representative black silhouette attribution: unavailable;
- representative blue/white-region attribution: unavailable;
- OSG candidate/draw correlation: unavailable;
- native drawn-pixel samples: unavailable;
- pre-swap presented-pixel sample: unavailable;
- exact renderer correction boundary: unproven.

The WO-037 build budget is exhausted; another diagnostic build is not authorized.
