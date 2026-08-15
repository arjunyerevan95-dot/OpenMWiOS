#!/usr/bin/env python3

import hashlib
import pathlib
import subprocess
import sys
import tempfile
import unittest


PORT_ROOT = pathlib.Path(__file__).resolve().parents[1]
RESOLVER = PORT_ROOT / "scripts" / "resolve-xcode-manifest.py"
HEADER = "kind\torigin\tname\tpath\n"
LINK_PARTICIPATION_HEADER = "name\tcategory\tarchive\n"


class ResolveXcodeManifestTests(unittest.TestCase):
    def run_resolver(
        self,
        template: pathlib.Path,
        output: pathlib.Path,
        *definitions: str,
        require_existing: bool = True,
        schema: str | None = None,
    ) -> subprocess.CompletedProcess[str]:
        command = [
            sys.executable,
            str(RESOLVER),
        ]
        if schema is not None:
            command.extend(("--schema", schema))
        command.extend(("--input", str(template), "--output", str(output)))
        for definition in definitions:
            command.extend(("--define", definition))
        if require_existing:
            command.append("--require-existing-products")
        return subprocess.run(command, check=False, capture_output=True, text=True)

    def write_template(self, path: pathlib.Path, *rows: str) -> str:
        content = HEADER + "".join(f"{row}\n" for row in rows)
        path.write_text(content, encoding="utf-8")
        return content

    def assert_rejected(
        self,
        result: subprocess.CompletedProcess[str],
        output: pathlib.Path,
        expected_message: str,
    ) -> None:
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn(expected_message, result.stderr)
        self.assertFalse(output.exists())

    def test_resolves_exact_release_effective_platform_form(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            archive = root / "Release-iphoneos" / "libExample.a"
            resolved_archive_text = f"{root}/Release-iphoneos/libExample.a"
            archive.parent.mkdir()
            archive.touch()
            template = root / "template.tsv"
            output = root / "resolved.tsv"
            original = self.write_template(
                template,
                "archive\tcmake-target\tExample\t"
                f"{root}/Release${{EFFECTIVE_PLATFORM_NAME}}/libExample.a",
            )

            result = self.run_resolver(
                template,
                output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(template.read_text(encoding="utf-8"), original)
            self.assertEqual(
                output.read_text(encoding="utf-8"),
                HEADER
                + f"archive\tcmake-target\tExample\t{resolved_archive_text}\n",
            )
            self.assertIn(
                f"template_sha256={hashlib.sha256(template.read_bytes()).hexdigest()}",
                result.stdout,
            )
            self.assertIn("resolved_sha256=", result.stdout)

    def test_rejects_missing_required_setting(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            template = root / "template.tsv"
            output = root / "resolved.tsv"
            self.write_template(
                template,
                "archive\tcmake-target\tExample\t"
                f"{root}/Release${{EFFECTIVE_PLATFORM_NAME}}/libExample.a",
            )
            result = self.run_resolver(template, output)
            self.assert_rejected(result, output, "EFFECTIVE_PLATFORM_NAME")

    def test_rejects_unknown_brace_style_setting(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            template = root / "template.tsv"
            output = root / "resolved.tsv"
            self.write_template(
                template,
                f"archive\tcmake-target\tExample\t{root}/${{UNKNOWN}}/libExample.a",
            )
            result = self.run_resolver(
                template,
                output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )
            self.assert_rejected(result, output, "UNKNOWN")

    def test_rejects_unknown_parenthesis_style_setting(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            template = root / "template.tsv"
            output = root / "resolved.tsv"
            self.write_template(
                template,
                f"archive\tcmake-target\tExample\t{root}/$(UNKNOWN)/libExample.a",
            )
            result = self.run_resolver(
                template,
                output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )
            self.assert_rejected(result, output, "UNKNOWN")

    def test_rejects_placeholder_remaining_outside_path_column(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            archive = root / "Release-iphoneos" / "libExample.a"
            archive.parent.mkdir()
            archive.touch()
            template = root / "template.tsv"
            output = root / "resolved.tsv"
            self.write_template(
                template,
                "archive\tcmake-target\t$(LEFTOVER)\t"
                f"{root}/Release${{EFFECTIVE_PLATFORM_NAME}}/libExample.a",
            )
            result = self.run_resolver(
                template,
                output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )
            self.assert_rejected(result, output, "LEFTOVER")

    def test_rejects_missing_resolved_archive(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            template = root / "template.tsv"
            output = root / "resolved.tsv"
            self.write_template(
                template,
                "archive\tcmake-target\tMissing\t"
                f"{root}/Release${{EFFECTIVE_PLATFORM_NAME}}/libMissing.a",
            )
            result = self.run_resolver(
                template,
                output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )
            self.assert_rejected(result, output, "existing regular .a file")

    def test_rejects_missing_declared_directory(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            template = root / "template.tsv"
            output = root / "resolved.tsv"
            self.write_template(
                template,
                "directory\tvcpkg-package-output\tarm64-ios\t"
                f"{root}/Release${{EFFECTIVE_PLATFORM_NAME}}/lib",
            )
            result = self.run_resolver(
                template,
                output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )
            self.assert_rejected(result, output, "existing directory")

    def test_preserves_non_path_columns_and_row_order(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            first = root / "Release-iphoneos" / "libFirst.a"
            second = root / "Release-iphoneos" / "libSecond.a"
            first_text = f"{root}/Release-iphoneos/libFirst.a"
            second_text = f"{root}/Release-iphoneos/libSecond.a"
            first.parent.mkdir()
            first.touch()
            second.touch()
            template = root / "template.tsv"
            output = root / "resolved.tsv"
            self.write_template(
                template,
                "archive\tsecond-origin\tSecond Name\t"
                f"{root}/Release${{EFFECTIVE_PLATFORM_NAME}}/libSecond.a",
                "archive\tfirst-origin\tFirst Name\t"
                f"{root}/Release${{EFFECTIVE_PLATFORM_NAME}}/libFirst.a",
            )

            result = self.run_resolver(
                template,
                output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(
                output.read_text(encoding="utf-8").splitlines()[1:],
                [
                    f"archive\tsecond-origin\tSecond Name\t{second_text}",
                    f"archive\tfirst-origin\tFirst Name\t{first_text}",
                ],
            )

    def test_output_is_deterministic_for_identical_inputs(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            archive = root / "Release-iphoneos" / "libExample.a"
            archive.parent.mkdir()
            archive.touch()
            template = root / "template.tsv"
            first_output = root / "first.tsv"
            second_output = root / "second.tsv"
            self.write_template(
                template,
                "archive\tcmake-target\tExample\t"
                f"{root}/Release${{EFFECTIVE_PLATFORM_NAME}}/libExample.a",
            )

            first_result = self.run_resolver(
                template,
                first_output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )
            second_result = self.run_resolver(
                template,
                second_output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )

            self.assertEqual(first_result.returncode, 0, first_result.stderr)
            self.assertEqual(second_result.returncode, 0, second_result.stderr)
            self.assertEqual(first_output.read_bytes(), second_output.read_bytes())
            self.assertEqual(first_result.stdout, second_result.stdout)

    def test_does_not_glob_for_archive(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            (root / "libActual.a").touch()
            template = root / "template.tsv"
            output = root / "resolved.tsv"
            self.write_template(
                template,
                f"archive\tcmake-target\tGlob\t{root}/lib*.a",
            )
            result = self.run_resolver(
                template,
                output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )
            self.assert_rejected(result, output, "existing regular .a file")

    def test_does_not_recursively_search_for_archive(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            nested = root / "expected" / "nested"
            nested.mkdir(parents=True)
            (nested / "libExample.a").touch()
            template = root / "template.tsv"
            output = root / "resolved.tsv"
            self.write_template(
                template,
                f"archive\tcmake-target\tNested\t{root}/expected/libExample.a",
            )
            result = self.run_resolver(
                template,
                output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )
            self.assert_rejected(result, output, "existing regular .a file")

    def test_does_not_fall_back_to_matching_basename(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            elsewhere = root / "elsewhere"
            elsewhere.mkdir()
            (elsewhere / "libExample.a").touch()
            template = root / "template.tsv"
            output = root / "resolved.tsv"
            self.write_template(
                template,
                f"archive\tcmake-target\tBasename\t{root}/expected/libExample.a",
            )
            result = self.run_resolver(
                template,
                output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )
            self.assert_rejected(result, output, "existing regular .a file")

    def test_rejects_duplicate_definitions(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            template = root / "template.tsv"
            output = root / "resolved.tsv"
            self.write_template(template, f"archive\tcmake-target\tX\t{root}/libX.a")
            result = self.run_resolver(
                template,
                output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
                "EFFECTIVE_PLATFORM_NAME=-iphonesimulator",
            )
            self.assert_rejected(result, output, "duplicate definition")

    def test_rejects_malformed_definition(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            template = root / "template.tsv"
            output = root / "resolved.tsv"
            self.write_template(template, f"archive\tcmake-target\tX\t{root}/libX.a")
            result = self.run_resolver(
                template,
                output,
                "EFFECTIVE_PLATFORM_NAME",
            )
            self.assert_rejected(result, output, "malformed definition")

    def test_rejects_unsupported_definition_name(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            template = root / "template.tsv"
            output = root / "resolved.tsv"
            self.write_template(template, f"archive\tcmake-target\tX\t{root}/libX.a")
            result = self.run_resolver(template, output, "OTHER=value")
            self.assert_rejected(result, output, "unsupported definition")


class ResolveXcodeLinkParticipationManifestTests(unittest.TestCase):
    def run_resolver(
        self,
        template: pathlib.Path,
        output: pathlib.Path,
        *definitions: str,
        require_existing: bool = True,
        schema: str | None = None,
    ) -> subprocess.CompletedProcess[str]:
        command = [sys.executable, str(RESOLVER)]
        if schema is not None:
            command.extend(("--schema", schema))
        command.extend(("--input", str(template), "--output", str(output)))
        for definition in definitions:
            command.extend(("--define", definition))
        if require_existing:
            command.append("--require-existing-products")
        return subprocess.run(command, check=False, capture_output=True, text=True)

    def write_template(self, path: pathlib.Path, *rows: str) -> str:
        content = HEADER + "".join(f"{row}\n" for row in rows)
        path.write_text(content, encoding="utf-8")
        return content

    def assert_rejected(
        self,
        result: subprocess.CompletedProcess[str],
        output: pathlib.Path,
        expected_message: str,
    ) -> None:
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn(expected_message, result.stderr)
        self.assertFalse(output.exists())

    def write_link_template(self, path: pathlib.Path, *rows: str) -> str:
        content = LINK_PARTICIPATION_HEADER + "".join(f"{row}\n" for row in rows)
        path.write_text(content, encoding="utf-8")
        return content

    def run_link_resolver(
        self,
        template: pathlib.Path,
        output: pathlib.Path,
        *definitions: str,
        require_existing: bool = True,
    ) -> subprocess.CompletedProcess[str]:
        return self.run_resolver(
            template,
            output,
            *definitions,
            require_existing=require_existing,
            schema="link-participation",
        )

    def test_link_schema_resolves_48_rows_and_preserves_order_and_fields(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            template = root / "participation.tsv"
            output = root / "participation.resolved.tsv"
            template_rows: list[str] = []
            expected_rows: list[str] = []
            for index in range(48):
                name = f"Archive{index:02d}"
                category = "engine-dependency" if index % 2 == 0 else "vcpkg-port"
                archive = root / "Release-iphoneos" / f"lib{name}.a"
                archive.parent.mkdir(parents=True, exist_ok=True)
                archive.touch()
                concrete = archive.as_posix()
                if index < 6:
                    template_archive = concrete.replace(
                        "Release-iphoneos", "Release${EFFECTIVE_PLATFORM_NAME}"
                    )
                else:
                    template_archive = concrete
                template_rows.append(f"{name}\t{category}\t{template_archive}")
                expected_rows.append(f"{name}\t{category}\t{concrete}")
            original = self.write_link_template(template, *template_rows)

            result = self.run_link_resolver(
                template,
                output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(template.read_text(encoding="utf-8"), original)
            resolved_lines = output.read_text(encoding="utf-8").splitlines()
            self.assertEqual(resolved_lines[0], LINK_PARTICIPATION_HEADER.rstrip("\n"))
            self.assertEqual(resolved_lines[1:], expected_rows)
            self.assertEqual(
                [(row.split("\t")[0], row.split("\t")[1]) for row in template_rows],
                [(row.split("\t")[0], row.split("\t")[1]) for row in resolved_lines[1:]],
            )

    def test_link_schema_rejects_unexpected_header(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            template = root / "participation.tsv"
            output = root / "resolved.tsv"
            template.write_text("name\tarchive\nExample\t/tmp/libExample.a\n", encoding="utf-8")
            result = self.run_link_resolver(
                template,
                output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )
            self.assert_rejected(result, output, "unexpected header")

    def test_link_schema_rejects_unknown_brace_placeholder(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            template = root / "participation.tsv"
            output = root / "resolved.tsv"
            self.write_link_template(
                template,
                f"Example\tengine-dependency\t{root.as_posix()}/${{UNKNOWN}}/libExample.a",
            )
            result = self.run_link_resolver(
                template,
                output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )
            self.assert_rejected(result, output, "UNKNOWN")

    def test_link_schema_rejects_unknown_parenthesis_placeholder(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            template = root / "participation.tsv"
            output = root / "resolved.tsv"
            self.write_link_template(
                template,
                f"Example\tengine-dependency\t{root.as_posix()}/$(UNKNOWN)/libExample.a",
            )
            result = self.run_link_resolver(
                template,
                output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )
            self.assert_rejected(result, output, "UNKNOWN")

    def test_link_schema_rejects_remaining_placeholder_in_non_path_column(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            archive = root / "libExample.a"
            archive.touch()
            template = root / "participation.tsv"
            output = root / "resolved.tsv"
            self.write_link_template(
                template,
                f"Example\t${{LEFTOVER}}\t{archive.as_posix()}",
            )
            result = self.run_link_resolver(
                template,
                output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )
            self.assert_rejected(result, output, "LEFTOVER")

    def test_link_schema_rejects_missing_exact_archive(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            template = root / "participation.tsv"
            output = root / "resolved.tsv"
            self.write_link_template(
                template,
                f"Missing\tengine-dependency\t{root.as_posix()}/libMissing.a",
            )
            result = self.run_link_resolver(
                template,
                output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )
            self.assert_rejected(result, output, "existing regular .a file")

    def test_link_schema_rejects_existing_non_archive(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            non_archive = root / "libExample.dylib"
            non_archive.touch()
            template = root / "participation.tsv"
            output = root / "resolved.tsv"
            self.write_link_template(
                template,
                f"Example\tengine-dependency\t{non_archive.as_posix()}",
            )
            result = self.run_link_resolver(
                template,
                output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )
            self.assert_rejected(result, output, "existing regular .a file")

    def test_link_schema_does_not_glob_search_or_fall_back_by_basename(self) -> None:
        cases = (
            ("Glob", "expected/lib*.a", "libActual.a"),
            ("Recursive", "expected/libExample.a", "expected/nested/libExample.a"),
            ("Basename", "expected/libExample.a", "elsewhere/libExample.a"),
        )
        for name, declared_relative, existing_relative in cases:
            with self.subTest(name=name), tempfile.TemporaryDirectory() as temporary:
                root = pathlib.Path(temporary)
                existing = root / existing_relative
                existing.parent.mkdir(parents=True, exist_ok=True)
                existing.touch()
                template = root / "participation.tsv"
                output = root / "resolved.tsv"
                self.write_link_template(
                    template,
                    f"{name}\tengine-dependency\t{(root / declared_relative).as_posix()}",
                )
                result = self.run_link_resolver(
                    template,
                    output,
                    "EFFECTIVE_PLATFORM_NAME=-iphoneos",
                )
                self.assert_rejected(result, output, "existing regular .a file")

    def test_link_schema_output_is_deterministic_and_separate(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            archive = root / "Release-iphoneos" / "libExample.a"
            archive.parent.mkdir()
            archive.touch()
            template = root / "participation.tsv"
            first_output = root / "first.resolved.tsv"
            second_output = root / "second.resolved.tsv"
            original = self.write_link_template(
                template,
                "Example\tengine-dependency\t"
                f"{root.as_posix()}/Release${{EFFECTIVE_PLATFORM_NAME}}/libExample.a",
            )

            first_result = self.run_link_resolver(
                template,
                first_output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )
            second_result = self.run_link_resolver(
                template,
                second_output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )

            self.assertEqual(first_result.returncode, 0, first_result.stderr)
            self.assertEqual(second_result.returncode, 0, second_result.stderr)
            self.assertNotEqual(template, first_output)
            self.assertNotEqual(template, second_output)
            self.assertEqual(template.read_text(encoding="utf-8"), original)
            self.assertEqual(first_output.read_bytes(), second_output.read_bytes())
            self.assertEqual(first_result.stdout, second_result.stdout)

    def test_explicit_product_schema_matches_backward_compatible_default(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            archive = root / "Release-iphoneos" / "libExample.a"
            archive.parent.mkdir()
            archive.touch()
            template = root / "product.tsv"
            default_output = root / "default.resolved.tsv"
            explicit_output = root / "explicit.resolved.tsv"
            self.write_template(
                template,
                "archive\tcmake-target\tExample\t"
                f"{root.as_posix()}/Release${{EFFECTIVE_PLATFORM_NAME}}/libExample.a",
            )

            default_result = self.run_resolver(
                template,
                default_output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
            )
            explicit_result = self.run_resolver(
                template,
                explicit_output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
                schema="product",
            )

            self.assertEqual(default_result.returncode, 0, default_result.stderr)
            self.assertEqual(explicit_result.returncode, 0, explicit_result.stderr)
            self.assertEqual(default_output.read_bytes(), explicit_output.read_bytes())
            self.assertEqual(default_result.stdout, explicit_result.stdout)

    def test_rejects_unknown_schema(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            template = root / "product.tsv"
            output = root / "resolved.tsv"
            self.write_template(template, f"archive\tcmake-target\tX\t{root}/libX.a")
            result = self.run_resolver(
                template,
                output,
                "EFFECTIVE_PLATFORM_NAME=-iphoneos",
                schema="unknown",
            )
            self.assert_rejected(result, output, "invalid choice")


if __name__ == "__main__":
    unittest.main()
