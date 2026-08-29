# WO-038 Diagnostic Validation

## Local focused validation

Command:

`python -m unittest validation.test_wo38_cold_osg_configuration`

Result: **5 passed**.

The combined WO38/WO37/WO33 selection ran 32 tests with 2 compiler-dependent skips. The five WO38 checks passed. Two inherited patch-materialization checks failed on this Windows checkout because Git materialized the OSG patch with CRLF line endings; one of those consequently could not apply the patch. These are host-checkout artifacts and are not source regressions.

## Aggregate validation

Command:

`python -m unittest discover -s validation -p "test_*.py"`

Result: **163 run; 8 skipped; 2 failures; 2 errors**.

The two errors are the pre-existing Windows `WinError 193` attempts to execute a POSIX verifier script. The two failures are the inherited CRLF OSG patch checks described above. The new WO38 suite passes.

## Other checks

- `python -m py_compile validation/test_wo38_cold_osg_configuration.py`: passed.
- `git diff --check`: passed.
- Local shell syntax check: unavailable because this Windows host has no Bash executable; covered by successful macOS CI execution of the edited script.
- CI patch bootstrap/source validation: passed.
- Cold OSG configure/dependency preparation: passed in 1,958 seconds.
- Product compile/link: passed in 2,355 seconds.
- Bundle validation/package/upload: passed.
- Full Qualification: not run.

All three Fast cache restores missed. This was therefore a cold-path validation rather than evidence hidden by a restored qualified build tree.

No inherited diagnostic source or renderer patch was edited to accommodate Windows-only test behavior.
