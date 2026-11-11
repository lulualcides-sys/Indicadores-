import hashlib
import json
import csv
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
LIB = REPO / "08_indicadores_originais"

class UpstreamOriginalIntegrity(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data = json.loads((LIB / "manifesto_lote2.json").read_text(encoding="utf-8"))
        cls.files = cls.data["files"]

    def test_total_exact(self):
        self.assertEqual(27, self.data["script_count"])
        self.assertEqual(37, len(self.files))
        self.assertEqual(5, self.data["source_count"])
        self.assertEqual(27, sum(f["kind"] == "pine" for f in self.files))
        self.assertEqual(5, sum(f["kind"] == "license" for f in self.files))
        self.assertEqual(5, sum(f["kind"] == "readme" for f in self.files))

    def test_each_git_blob_sha(self):
        for f in self.files:
            path = REPO / f["local_path"]
            raw = path.read_bytes()
            sha = hashlib.sha1(b"blob " + str(len(raw)).encode("ascii") + b"\0" + raw).hexdigest()
            self.assertEqual(f["size"], len(raw), str(path))
            self.assertEqual(f["sha"], sha, str(path))

    def test_licenses(self):
        for source in self.data["sources"]:
            text = (LIB / source["folder"] / "LICENSE").read_text(encoding="utf-8")
            if source["license"] == "MIT":
                self.assertIn("MIT License", text)
                self.assertIn("Permission is hereby granted", text)
            elif source["license"] == "MPL-2.0":
                self.assertIn("Mozilla Public License", text)
            else:
                self.fail("Unexpected license " + str(source["license"]))

    def test_catalog_consistency(self):
        with (REPO / "01_catalogos/SEGUNDA_LEVA_27_ORIGINAIS_2026-11-11.csv").open(newline="", encoding="utf-8") as f:
            rows = list(csv.DictReader(f))
        self.assertEqual(27, len(rows))
        self.assertEqual(27, len(set(row["pasta"] for row in rows)))
        self.assertEqual(
            set(row["pasta"] for row in rows),
            set(f["local_path"] for f in self.files if f["kind"] == "pine")
        )

    def test_source_files_not_binaries(self):
        for f in self.files:
            self.assertTrue(f["local_path"].endswith((".pine", "LICENSE", "README.md")))
            self.assertTrue(f["commit"] and f["repo"])
            self.assertTrue((REPO / f["local_path"]).is_file())

if __name__=="__main__":
    unittest.main()
