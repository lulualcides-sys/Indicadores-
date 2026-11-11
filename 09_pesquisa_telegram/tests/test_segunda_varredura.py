import csv
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class TelegramSecondScan(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with (ROOT/"NOVOS_CANDIDATOS_2026-11-11.csv").open(encoding="utf-8",newline="") as f:
            cls.items=list(csv.DictReader(f))
    def test_count_and_distinct_names(self):
        self.assertEqual(len(self.items),23)
        self.assertEqual(len({x["nome"].casefold() for x in self.items}),len(self.items))
        self.assertEqual(len({x["id"] for x in self.items}),len(self.items))
    def test_source_links(self):
        self.assertTrue(all(x["url_post"].startswith("https://t.me/") for x in self.items))
        self.assertTrue(all(x["arquivo_mencionado"] and x["canal"] for x in self.items))
    def test_no_unfounded_downloads(self):
        self.assertTrue(all(x["download"]=="NAO_BAIXADO" for x in self.items))
    def test_priority_and_risks(self):
        self.assertTrue(all(x["prioridade"] in {"P1","P2","P3"} for x in self.items))
        self.assertGreaterEqual(sum(x["prioridade"]=="P1" for x in self.items),6)
        self.assertTrue(all(x["risco"] for x in self.items))
if __name__=="__main__":
    unittest.main()
