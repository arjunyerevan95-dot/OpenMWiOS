#!/usr/bin/env python3

import argparse
import hashlib
import os
import pathlib
import re
import sys
import tempfile


EXPECTED_HEADER = ("kind", "origin", "name", "path")
SUPPORTED_SETTING = "EFFECTIVE_PLATFORM_NAME"
PLACEHOLDER = re.compile(r"\$\{([^{}]+)\}|\$\(([^()]+)\)")


class ResolutionError(ValueError):
    pass


def parse_definitions(raw_definitions: list[str]) -> dict[str, str]:
    definitions: dict[str, str] = {}
    for raw_definition in raw_definitions:
        if "=" not in raw_definition:
            raise ResolutionError(f"malformed definition: {raw_definition!r}")
        name, value = raw_definition.split("=", 1)
        if not name or not value:
            raise ResolutionError(f"malformed definition: {raw_definition!r}")
        if name != SUPPORTED_SETTING:
            raise ResolutionError(f"unsupported definition: {name}")
        if name in definitions:
            raise ResolutionError(f"duplicate definition: {name}")
        definitions[name] = value
    return definitions


def resolve_path(template_path: str, definitions: dict[str, str]) -> str:
    def replace(match: re.Match[str]) -> str:
        name = match.group(1) or match.group(2)
        if name not in definitions:
            raise ResolutionError(f"unresolved or unknown placeholder: {name}")
        return definitions[name]

    return PLACEHOLDER.sub(replace, template_path)


def reject_remaining_placeholders(fields: list[str]) -> None:
    for field in fields:
        match = PLACEHOLDER.search(field)
        if match:
            name = match.group(1) or match.group(2)
            raise ResolutionError(f"unresolved or unknown placeholder: {name}")


def validate_product(kind: str, product_path: str) -> None:
    path = pathlib.Path(product_path)
    if kind == "archive":
        if path.suffix != ".a" or not path.is_file():
            raise ResolutionError(
                f"archive is not an existing regular .a file: {product_path}"
            )
    elif kind == "directory":
        if not path.is_dir():
            raise ResolutionError(f"path is not an existing directory: {product_path}")
    else:
        raise ResolutionError(f"unsupported manifest row kind: {kind}")


def resolve_manifest(
    input_path: pathlib.Path,
    output_path: pathlib.Path,
    definitions: dict[str, str],
    require_existing_products: bool,
) -> tuple[str, str]:
    if input_path.resolve() == output_path.resolve():
        raise ResolutionError("input and output manifests must be separate files")

    template_bytes = input_path.read_bytes()
    try:
        template_text = template_bytes.decode("utf-8")
    except UnicodeDecodeError as error:
        raise ResolutionError(f"template is not valid UTF-8: {error}") from error

    lines = template_text.splitlines()
    if not lines:
        raise ResolutionError("template manifest is empty")
    if tuple(lines[0].split("\t")) != EXPECTED_HEADER:
        raise ResolutionError("template manifest has an unexpected header")

    resolved_lines = ["\t".join(EXPECTED_HEADER)]
    for line_number, line in enumerate(lines[1:], start=2):
        fields = line.split("\t")
        if len(fields) != len(EXPECTED_HEADER):
            raise ResolutionError(
                f"template row {line_number} must contain exactly four columns"
            )
        fields[3] = resolve_path(fields[3], definitions)
        reject_remaining_placeholders(fields)
        if require_existing_products:
            validate_product(fields[0], fields[3])
        resolved_lines.append("\t".join(fields))

    resolved_bytes = ("\n".join(resolved_lines) + "\n").encode("utf-8")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    temporary_name: str | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="wb", dir=output_path.parent, delete=False
        ) as temporary:
            temporary.write(resolved_bytes)
            temporary_name = temporary.name
        os.replace(temporary_name, output_path)
        temporary_name = None
    finally:
        if temporary_name is not None:
            pathlib.Path(temporary_name).unlink(missing_ok=True)

    return (
        hashlib.sha256(template_bytes).hexdigest(),
        hashlib.sha256(resolved_bytes).hexdigest(),
    )


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Resolve explicitly supplied Xcode settings in a product manifest."
    )
    parser.add_argument("--input", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    parser.add_argument("--define", action="append", default=[])
    parser.add_argument("--require-existing-products", action="store_true")
    return parser.parse_args()


def main() -> int:
    arguments = parse_arguments()
    try:
        definitions = parse_definitions(arguments.define)
        template_hash, resolved_hash = resolve_manifest(
            arguments.input,
            arguments.output,
            definitions,
            arguments.require_existing_products,
        )
    except (OSError, ResolutionError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    print(f"template_sha256={template_hash}")
    print(f"resolved_sha256={resolved_hash}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
