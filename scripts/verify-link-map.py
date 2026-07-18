#!/usr/bin/env python3

import argparse
import pathlib
import re
import sys


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Verify exact static archive participation in an Apple linker map")
    parser.add_argument("link_map", type=pathlib.Path)
    parser.add_argument("participation_manifest", type=pathlib.Path)
    parser.add_argument("report", type=pathlib.Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    violations: list[str] = []
    if not args.link_map.is_file():
        print(f"error: linker map is missing: {args.link_map}", file=sys.stderr)
        return 1
    if not args.participation_manifest.is_file():
        print(
            f"error: link participation manifest is missing: {args.participation_manifest}",
            file=sys.stderr,
        )
        return 1

    lines = args.participation_manifest.read_text().splitlines()
    if not lines or lines[0] != "name\tcategory\tarchive":
        print("error: invalid link participation manifest header", file=sys.stderr)
        return 1

    declarations: list[tuple[str, str, pathlib.Path]] = []
    seen_names: set[str] = set()
    for line_number, line in enumerate(lines[1:], start=2):
        if not line:
            continue
        fields = line.split("\t")
        if len(fields) != 3:
            violations.append(
                f"manifest line {line_number} does not have three tab-separated fields")
            continue
        name, category, raw_archive = fields
        archive = pathlib.Path(raw_archive)
        if name in seen_names:
            violations.append(f"duplicate participation name: {name}")
        seen_names.add(name)
        if not archive.is_absolute():
            violations.append(f"participation path for {name} is not absolute: {archive}")
        if archive.suffix != ".a":
            violations.append(f"participation path for {name} is not a static archive: {archive}")
        if not archive.is_file():
            violations.append(f"participation archive for {name} is missing: {archive}")
        declarations.append((name, category, archive))

    if not declarations:
        violations.append("link participation manifest contains no archives")

    map_text = args.link_map.read_text(errors="replace")
    report_rows = ["name\tcategory\tarchive\tobject_contributions\tstatus"]
    for name, category, archive in declarations:
        # Apple ld64 map object rows retain the resolved archive path and append
        # either `(member.o)` or `[member.o]`. Requiring that exact path avoids
        # accepting an unrelated archive with the same basename.
        pattern = re.compile(
            r"(?m)^\[\s*\d+\]\s+" + re.escape(str(archive)) + r"(?:\(|\[)")
        contributions = len(pattern.findall(map_text))
        status = "passed" if contributions else "missing"
        if not contributions:
            violations.append(f"{name} did not contribute any object to the linker map: {archive}")
        report_rows.append(
            f"{name}\t{category}\t{archive}\t{contributions}\t{status}")

    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text("\n".join(report_rows) + "\n")
    if violations:
        print("\n".join(f"error: {item}" for item in violations), file=sys.stderr)
        return 1
    print(f"Verified {len(declarations)} exact static archive contributions in {args.link_map}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
