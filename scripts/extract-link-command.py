#!/usr/bin/env python3

import argparse
import pathlib
import sys


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract a final app linker command from xcodebuild output")
    parser.add_argument("build_log", type=pathlib.Path)
    parser.add_argument("output", type=pathlib.Path)
    parser.add_argument("--bundle-executable", required=True)
    args = parser.parse_args()

    product_suffix = f"/{args.bundle_executable}.app/{args.bundle_executable}"
    candidates = []
    for line in args.build_log.read_text(errors="replace").splitlines():
        stripped = line.strip()
        if ("clang" in stripped and " -o " in stripped and " -c " not in stripped
                and product_suffix in stripped):
            candidates.append(stripped)
    if not candidates:
        print(
            f"error: final {args.bundle_executable} linker command was not found",
            file=sys.stderr,
        )
        return 1
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(candidates[-1] + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
