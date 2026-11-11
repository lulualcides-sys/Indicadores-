import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OLD=(ROOT/"v1.20"/"H1_Vector_Factor_M1.mq5").read_text(encoding="utf-8")
NEW=(ROOT/"v1.30"/"H1_Vector_Factor_M1.mq5").read_text(encoding="utf-8")

class H1V130(unittest.TestCase):
    def test_original_preserved(self):
        self.assertIn('#property version   "1.20"',OLD)
        self.assertIn('#property version   "1.30"',NEW)

    def test_new_gates_opt_in(self):
        self.assertIn("input double InpMaxSpreadATR        = 0.00;",NEW)
        self.assertIn("input double InpDirectionalBodyGate = 0.00;",NEW)
        self.assertIn("if(InpMaxSpreadATR>0.0 &&",NEW)
        self.assertIn("if(InpDirectionalBodyGate>0.0)",NEW)

    def test_new_gates_only_use_closed_bars(self):
        for token in ("close[0]","open[0]","high[0]","low[0]"):
            self.assertNotIn(token,NEW)
        self.assertIn("const double relativeBody=signedBody/MathMax(high[i]-low[i],_Point);",NEW)
        self.assertIn("if(!fullRebuild && time[0]==g_seenOpenBar)",NEW)
        self.assertIn("BuyBuffer[0]=EMPTY_VALUE;",NEW)
        self.assertIn("SellBuffer[0]=EMPTY_VALUE;",NEW)

    def test_formula_still_same(self):
        start=NEW.index("double FactorScore(")
        end=NEW.index("string SessionId(",start)
        oldstart=OLD.index("double FactorScore(")
        oldend=OLD.index("string SessionId(",oldstart)
        self.assertEqual(NEW[start:end],OLD[oldstart:oldend])

if __name__=="__main__":
    unittest.main()
