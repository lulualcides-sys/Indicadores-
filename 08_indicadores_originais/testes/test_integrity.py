#!/usr/bin/env python3
"""Verify byte-for-byte Git blob identities of MIT external source mirrors."""
from pathlib import Path
import hashlib,json,unittest
ROOT=Path(__file__).resolve().parents[1]
class VendorSources(unittest.TestCase):
    def test_mit_licenses_present(self):
        for path in ("01_pine_wavesunchained/LICENSE","02_python_ta/LICENSE"):
            content=(ROOT/path).read_text(encoding="utf-8")
            self.assertIn("MIT License",content)
            self.assertIn("Permission is hereby granted",content)
    def test_exact_upstream_blob_checksums(self):
        data=json.loads((ROOT/"manifesto_origens.json").read_text(encoding="utf-8"))
        self.assertEqual(25,len(data["files"]))
        self.assertEqual(10,sum(x["local_path"].endswith(".pine") for x in data["files"]))
        for file in data["files"]:
            path=ROOT.parent/file["local_path"]
            raw=path.read_bytes()
            git_sha=hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()
            self.assertEqual(file["bytes"],len(raw),file["local_path"])
            self.assertEqual(file["git_blob_sha"],git_sha,file["local_path"])
if __name__=="__main__":unittest.main()
