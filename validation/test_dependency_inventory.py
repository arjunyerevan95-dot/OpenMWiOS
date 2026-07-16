#!/usr/bin/env python3

import importlib.util
import pathlib
import sys
import tempfile
import unittest

PORT_ROOT = pathlib.Path(__file__).resolve().parents[1]
MODULE_PATH = PORT_ROOT / "scripts" / "dependency-inventory.py"
SPEC = importlib.util.spec_from_file_location("openmw_dependency_inventory", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
INVENTORY = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = INVENTORY
SPEC.loader.exec_module(INVENTORY)


class ProductManifestTests(unittest.TestCase):
    def test_fetched_archive_is_excluded_but_declared_output_is_included(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            fetched = root / "build" / "ios" / "extern" / "fetched" / "example"
            produced = root / "build" / "ios" / "_deps" / "library-build" / "Release-iphoneos"
            fetched.mkdir(parents=True)
            produced.mkdir(parents=True)
            fetched_archive = fetched / "libhost-example.a"
            produced_archive = produced / "libdevice-product.a"
            fetched_archive.touch()
            produced_archive.touch()

            manifest = root / "products.tsv"
            manifest.write_text(
                "kind\torigin\tname\tpath\n"
                f"directory\tcmake-product-root\tdevice-products\t{produced}\n")
            entries = INVENTORY.read_product_manifest(manifest)
            products, violations = INVENTORY.resolve_product_manifest(entries)

            self.assertEqual(violations, [])
            self.assertIn(produced_archive.resolve(), products)
            self.assertNotIn(fetched_archive.resolve(), products)
            self.assertEqual(
                products[produced_archive.resolve()],
                [{"kind": "directory", "origin": "cmake-product-root", "name": "device-products"}],
            )

    def test_missing_expected_archive_is_a_violation(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            missing = pathlib.Path(temporary) / "libmissing.a"
            entry = INVENTORY.ManifestEntry("archive", "cmake-target", "Missing", missing)
            products, violations = INVENTORY.resolve_product_manifest([entry])
            self.assertEqual(products, {})
            self.assertTrue(any("missing expected" in item for item in violations))
            self.assertTrue(any("empty archive inventory" in item for item in violations))

    def test_empty_manifest_is_a_violation(self) -> None:
        products, violations = INVENTORY.resolve_product_manifest([])
        self.assertEqual(products, {})
        self.assertIn("product manifest contains no declarations", violations)
        self.assertIn("product manifest resolved to an empty archive inventory", violations)

    def test_duplicate_paths_are_deduplicated_with_sorted_provenance(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            archive = pathlib.Path(temporary) / "libsame.a"
            archive.touch()
            entries = [
                INVENTORY.ManifestEntry("archive", "staged-dependency", "Second", archive),
                INVENTORY.ManifestEntry("archive", "cmake-target", "First", archive),
                INVENTORY.ManifestEntry("archive", "cmake-target", "First", archive),
            ]
            products, violations = INVENTORY.resolve_product_manifest(entries)
            self.assertEqual(violations, [])
            self.assertEqual(list(products), [archive.resolve()])
            self.assertEqual(
                products[archive.resolve()],
                [
                    {"kind": "archive", "origin": "cmake-target", "name": "First"},
                    {"kind": "archive", "origin": "staged-dependency", "name": "Second"},
                ],
            )


if __name__ == "__main__":
    unittest.main()
