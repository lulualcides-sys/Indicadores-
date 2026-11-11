import sys,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"research"))
from reference import Bar,detect
SRC=(ROOT/"v1.00"/"Nexus_Structure_Break_NR.mq5").read_text(encoding="utf-8")

def sample():
    b=[Bar(100,100.2,99.8,100) for _ in range(80)]
    # Low confirmed before high break
    b.append(Bar(100,100.5,98.0,98.7))
    b += [Bar(99,99.5,98.5,99),Bar(99,99.7,98.7,99.1),Bar(99,99.6,98.8,99.2)]
    # High confirmed later
    b.append(Bar(100,102.0,99.0,101.0))
    b += [Bar(101,101.5,100.2,101),Bar(101,101.4,100.4,101),Bar(101,101.3,100.6,101.1)]
    return b

class StructureTests(unittest.TestCase):
    def test_confirmed_break(self):
        b=sample()
        b.append(Bar(101.3,103.0,101.2,102.7))
        self.assertTrue(any(x[0]==len(b)-1 and x[1]=="BUY" for x in detect(b)))
    def test_no_pivot_without_confirming_right_bars(self):
        b=sample()[:-3]
        # Only pivot at last bar, cannot be confirmed without 3 later closed candles
        b.append(Bar(100.3,105,100,104))
        self.assertFalse(any(x[0]==len(b)-1 for x in detect(b)))
    def test_prefix_invariance(self):
        b=sample()+[Bar(101.3,103,101.2,102.7)]
        before=detect(b)
        later=detect(b+[Bar(102.6,104,102.0,103),Bar(103,105,102.9,104)])
        self.assertEqual(before,[x for x in later if x[0]<len(b)])
    def test_no_live_candle(self):
        b=sample()
        self.assertEqual(detect(b),detect((b+[Bar(10,1000,0,500)])[:-1]))
        for t in ("open[0]","close[0]","high[0]","low[0]","OrderSend("):
            self.assertNotIn(t,SRC)
        self.assertIn("for(int i=oldest;i>=1;i--)",SRC)
        self.assertIn("if(!rebuild && time[i]<=lastClosed) continue;",SRC)
    def test_pivot_confirmation_clock(self):
        for t in ("const int candidate=i+InpRightBars;",
                  "for(int k=1;k<=right;k++)",
                  "BuyBuffer[0]=EMPTY_VALUE;",
                  "SellBuffer[0]=EMPTY_VALUE;",
                  "const datetime from=barStart+seconds"):
            self.assertIn(t,SRC)

if __name__=="__main__":
    unittest.main()
