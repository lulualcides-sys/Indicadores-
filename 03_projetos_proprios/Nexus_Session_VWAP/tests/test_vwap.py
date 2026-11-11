import sys
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"research"))
from reference import Bar,calc
SOURCE=(ROOT/"v1.00"/"Nexus_Session_VWAP_NR.mq5").read_text(encoding="utf-8")

def sample(n=45):
    bars=[Bar(1,100,100.2,99.8,100,100) for _ in range(n)]
    bars.append(Bar(1,99.8,100.4,99.7,100.3,200))
    bars.append(Bar(1,100.1,100.5,99.9,100.4,200))
    return bars

class VWAPTests(unittest.TestCase):
    def test_signal_can_form_on_cross(self):
        b=sample()
        # Price starts below VWAP and reclaims from below on a closed candle
        b=b[:45]+[Bar(1,99.6,99.85,99.4,99.65,120),Bar(1,99.8,100.5,99.7,100.4,220)]
        self.assertTrue(any(e[0]==46 and e[1]=="BUY" for e in calc(b)))
    def test_prefix_invariance(self):
        b=sample()
        base=calc(b)
        new=b+[Bar(2,100,101,99,100.5,300),Bar(2,100.5,102,100,101,400)]
        self.assertEqual(base,[x for x in calc(new) if x[0]<len(b)])
    def test_current_bar_excluded_by_caller(self):
        b=sample()
        self.assertEqual(calc(b),calc((b+[Bar(1,300,400,20,21,20000)])[:-1]))
    def test_closed_bar_guards(self):
        for s in ("BuyBuffer[0]=EMPTY_VALUE;","SellBuffer[0]=EMPTY_VALUE;",
                  "VwapBuffer[0]=EMPTY_VALUE;","for(int i=oldest;i>=1;i--)",
                  "if(!rebuild && time[i]<=previouslyClosed) continue;"):
            self.assertIn(s,SOURCE)
        for s in ("open[0]","close[0]","high[0]","low[0]","OrderSend("):
            self.assertNotIn(s,SOURCE)
    def test_previous_only_volume_and_atr(self):
        self.assertIn("for(int j=i+1;j<=i+InpRVOLPeriod;j++)",SOURCE)
        self.assertIn("for(int j=i+1;j<=i+InpATRPeriod;j++)",SOURCE)
        self.assertIn("const datetime from=closedTime+sec",SOURCE)

if __name__=="__main__":
    unittest.main()
