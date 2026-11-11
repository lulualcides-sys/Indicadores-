"""Verify immutable originals in Lot 3; does not certify profitable indicators."""
import csv
import hashlib
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "08_indicadores_originais"

class Lot3Integrity(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.m = json.loads((SRC/"manifesto_lote3.json").read_text(encoding="utf8"))

    def test_exact_number_and_types(self):
        files = self.m["files"]
        self.assertEqual(30, len(files))
        self.assertEqual(21, sum(f["type"] in ("mq5", "pine") for f in files))
        self.assertEqual(6, sum(f["type"] == "mq5" for f in files))
        self.assertEqual(15, sum(f["type"] == "pine" for f in files))
        self.assertEqual(3, sum(f["type"] == "license" for f in files))
        self.assertEqual(6, sum(f["type"] == "documentation" for f in files))
        self.assertEqual(len(files), len({f["path"] for f in files}))

    def test_every_git_blob_and_size(self):
        for f in self.m["files"]:
            content = (ROOT / f["path"]).read_bytes()
            h = hashlib.sha1(b"blob " + str(len(content)).encode("ascii") + b"\0" + content).hexdigest()
            self.assertEqual(len(content), f["size_bytes"], f["path"])
            self.assertEqual(h, f["git_blob_sha"], f["path"])

    def test_licenses_and_attribution(self):
        for folder in ("09_miron_mql5", "10_robwhitlow_orderflow", "11_mihakralj_matematica"):
            lic = (SRC / folder / "LICENSE").read_text(encoding="utf8")
            self.assertIn("MIT License", lic)
            self.assertIn("Permission is hereby granted", lic)
        self.assertEqual({x["license"] for x in self.m["files"]}, {"MIT"})

    def test_only_expected_source_extensions(self):
        for f in self.m["files"]:
            data = (ROOT / f["path"]).read_bytes()
            self.assertNotIn(b"\0", data, f["path"]) # archive text; no binary EX5
            if f["type"] == "mq5":
                self.assertTrue(f["path"].endswith(".mq5"))
                self.assertIn(b"#property", data)
            if f["type"] == "pine":
                self.assertTrue(f["path"].endswith(".pine"))
                self.assertIn(b"//@version=", data)

    def test_catalog_matches_files(self):
        with (ROOT / "01_catalogos/LOTE3_21_FONTES_2026-11-11.csv").open(encoding="utf8",newline="") as file:
            rows=list(csv.DictReader(file))
        self.assertEqual(21, len(rows))
        self.assertEqual({r["caminho"] for r in rows},
                         {f["path"] for f in self.m["files"] if f["type"] in ("mq5","pine")})

if __name__ == "__main__":
    unittest.main()
