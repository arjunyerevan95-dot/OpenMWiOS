# OpenMW iOS engineering ledger

## 2026-08-15 — pre-launch installation root cause

The pre-launch iOS installation failure was caused by a top-level lowercase
`resources` directory in the flat application bundle. On Apple's normal
case-insensitive filesystem this collides with the conventional `Resources`
bundle directory. Foundation and CoreFoundation consequently interpret the
bundle using the wrong layout, ignore the root `Info.plist`, and return nil
bundle identity and executable resolution.

The causal model was proven with reciprocal Apple-native tests: removing only
the top-level `resources` directory from a copied OpenMW bundle restored bundle
identity and executable resolution, while adding only an empty lowercase
`resources` directory to a known-good eDuke32 bundle removed both.

The production correction stages the byte-identical OpenMW resource tree at
top-level `openmw-resources`. The iOS bootstrap passes that path through
OpenMW's existing configurable `--resources` option; the generated iOS
`openmw.cfg` uses the same root. Generic OpenMW resource semantics are
unchanged. Production validation rejects any top-level entry whose
case-insensitive name is `Resources`, compares source and staged resource
manifests, and requires Apple Foundation/CoreFoundation to resolve the bundle
identifier and executable before packaging.

SideStore, provisioning, signing, deployment target, executable architecture,
and leading-slash ZIP entry names were excluded as the root cause by the prior
control experiments.
