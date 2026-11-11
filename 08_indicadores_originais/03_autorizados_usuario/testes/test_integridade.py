from pathlib import Path
import hashlib
import json
import unittest

ROOT=Path(__file__).resolve().parents[1]

class Originais(unittest.TestCase):
    def setUp(self):
        self.manifest=json.loads((ROOT/"manifesto_lote1.json").read_text(encoding="utf-8"))

    def test_five_text_originals_no_binary(self):
        files=self.manifest["files"]
        self.assertEqual(len(files),5)
        self.assertTrue(all(f["filename"].endswith((".pine",".txt")) for f in files))

    def test_archive_blob_hash_and_size(self):
        for entry in self.manifest["files"]:
            raw=(ROOT/entry["filename"]).read_bytes()
            git=hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()
            self.assertEqual(len(raw),entry["git_archived_bytes"],entry["filename"])
            self.assertEqual(git,entry["git_blob_sha_archived"],entry["filename"])

    def test_actual_indicators_not_placeholders(self):
        for entry in self.manifest["files"]:
            code=(ROOT/entry["filename"]).read_text(encoding="utf-8")
            self.assertIn("indicator(",code,entry["filename"])
            self.assertGreater(len(code),2500,entry["filename"])

    def test_provenance_not_telegram_download(self):
        self.assertEqual(self.manifest["collection_method"],"copied_from_existing_user_library_not_fetched_from_telegram_today")

if __name__=="__main__":
    unittest.main()
