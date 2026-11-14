# Scoped material performance candidate

Base: corrected map/HUD source 3fd0d3bc2da789049f32b2ee0333776d61aed028.

Changes: deferred first-active initialization per material buffer, one animated color update per subsequent frame, immutable opaque-depth sampler sharing keyed by texture unit. No visual quality settings, shadow behavior, mod assets, phone data, or platform dependencies changed.

Nine native tests cover initialization timing, custom-value retention without input, reset, four color modes, alpha, template/buffer isolation, real linear keyframe interpolation and cloned controllers, sampler identity/value/removal/concurrency. The full modified ShaderVisitor translation unit is also compiled. Unused NIF decoding/stereo link boundaries abort if reached; this is unit validation, not whole-engine or device validation.

One dedicated workflow gates the existing pinned Apple app recipe on focused Linux native checks. It retains the shared concurrency group and dependency/provenance checks. Dispatch only after the map build is terminal and ownership is coordinated. No speedup claim without measurements. Phone testing remains for the owner after delivery, not automated profiling.
