#!/usr/bin/env python3

"""Prove that the staged iOS resource tree preserves the build resource tree."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import stat
from pathlib import Path


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def inventory(root: Path) -> dict[str, dict[str, object]]:
    if not root.is_dir():
        raise ValueError(f"resource root is not a directory: {root}")

    result: dict[str, dict[str, object]] = {}
    for path in sorted(root.rglob("*")):
        relative = path.relative_to(root).as_posix()
        metadata = path.lstat()
        mode = stat.S_IMODE(metadata.st_mode)
        if path.is_symlink():
            target = os.readlink(path)
            entry_type = "symlink"
            size = len(target.encode("utf-8"))
            digest = hashlib.sha256(target.encode("utf-8")).hexdigest()
        elif path.is_dir():
            entry_type = "directory"
            size = 0
            digest = ""
        elif path.is_file():
            entry_type = "file"
            size = metadata.st_size
            digest = sha256_file(path)
        else:
            entry_type = "other"
            size = metadata.st_size
            digest = ""
        result[relative] = {
            "type": entry_type,
            "size": size,
            "mode": f"{mode:04o}",
            "sha256": digest,
        }
    return result


def write_manifest(path: Path, entries: dict[str, dict[str, object]]) -> None:
    with path.open("w", encoding="utf-8", newline="\n") as stream:
        stream.write("relative_path\ttype\tsize\tmode\tsha256\n")
        for relative, values in entries.items():
            stream.write(
                f"{relative}\t{values['type']}\t{values['size']}\t"
                f"{values['mode']}\t{values['sha256']}\n"
            )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--staged", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()

    source = inventory(args.source.resolve())
    staged = inventory(args.staged.resolve())
    args.output_dir.mkdir(parents=True, exist_ok=True)
    write_manifest(args.output_dir / "source-resources.tsv", source)
    write_manifest(args.output_dir / "staged-openmw-resources.tsv", staged)

    source_paths = set(source)
    staged_paths = set(staged)
    missing = sorted(source_paths - staged_paths)
    unexpected = sorted(staged_paths - source_paths)
    shared = sorted(source_paths & staged_paths)
    type_mismatches = [
        path for path in shared if source[path]["type"] != staged[path]["type"]
    ]
    size_mismatches = [
        path for path in shared if source[path]["size"] != staged[path]["size"]
    ]
    hash_mismatches = [
        path for path in shared if source[path]["sha256"] != staged[path]["sha256"]
    ]

    summary = {
        "source_root": str(args.source.resolve()),
        "staged_root": str(args.staged.resolve()),
        "source_entry_count": len(source),
        "staged_entry_count": len(staged),
        "source_file_count": sum(value["type"] == "file" for value in source.values()),
        "staged_file_count": sum(value["type"] == "file" for value in staged.values()),
        "source_file_bytes": sum(
            int(value["size"]) for value in source.values() if value["type"] == "file"
        ),
        "staged_file_bytes": sum(
            int(value["size"]) for value in staged.values() if value["type"] == "file"
        ),
        "missing_count": len(missing),
        "unexpected_count": len(unexpected),
        "type_mismatch_count": len(type_mismatches),
        "size_mismatch_count": len(size_mismatches),
        "changed_hash_count": len(hash_mismatches),
        "missing": missing,
        "unexpected": unexpected,
        "type_mismatches": type_mismatches,
        "size_mismatches": size_mismatches,
        "hash_mismatches": hash_mismatches,
        "qualified": not any(
            (missing, unexpected, type_mismatches, size_mismatches, hash_mismatches)
        ),
    }
    with (args.output_dir / "resource-relocation-summary.json").open(
        "w", encoding="utf-8", newline="\n"
    ) as stream:
        json.dump(summary, stream, indent=2, sort_keys=True)
        stream.write("\n")

    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0 if summary["qualified"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
