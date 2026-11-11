import csv
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
class TelegramCatalogTests(unittest.TestCase):
    def read(self,file):
        with (ROOT/file).open(newline="",encoding="utf-8") as f:
            return list(csv.DictReader(f))
    def test_channel_count_unique(self):
        rows=self.read("CANAIS_PUBLICOS_2026-11-11.csv")
        self.assertGreaterEqual(len(rows),15)
        self.assertEqual(len(rows),len(set(r["canal"].casefold() for r in rows)))
        self.assertTrue(all(r["url_publica"].startswith("https://t.me/") for r in rows))
    def test_candidates_count_and_evidence(self):
        rows=self.read("INDICADORES_CANDIDATOS_2026-11-11.csv")
        self.assertGreaterEqual(len(rows),25)
        self.assertEqual(len(rows),len(set(r["id"] for r in rows)))
        self.assertTrue(all(r["url_evidencia"].startswith("https://") for r in rows))
        self.assertTrue(all(r["prioridade"] in ("P1","P2","P3") for r in rows))
        self.assertTrue(all(r["licenca_ou_status"] for r in rows))
    def test_private_inaccessible_not_verified(self):
        channels={x["canal"]:x for x in self.read("CANAIS_PUBLICOS_2026-11-11.csv")}
        for channel in ("INFOREXINDICATORS","fxstrategiesresources"):
            self.assertEqual(channels[channel]["acesso"],"NÃO_VERIFICADO")
    def test_no_unlicensed_mirroring_claims(self):
        md=(ROOT/"RELATORIO_CURADORIA_2026-11-11.md").read_text(encoding="utf-8")
        self.assertIn("não será copiado",md)
        self.assertIn("Esta rodada **não baixou nem executou anexos**",md)
if __name__=="__main__":
    unittest.main()
