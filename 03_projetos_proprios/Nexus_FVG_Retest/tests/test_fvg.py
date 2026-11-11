import sys,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"research"))
from reference import Bar,detect
SRC=(ROOT/"v1.00"/"Nexus_FVG_Retest_NR.mq5").read_text(encoding="utf-8")

def base(n=90):
    return [Bar(100,100.2,99.8,100) for _ in range(n)]

def bullish():
    b=base()
    # first=87 high 100.2; middle=88; third=89 low 101.0 (>100.2)
    b[-3]=Bar(100,100.2,99.8,100.0)
    b[-2]=Bar(100,102.0,99.9,101.9)
    b[-1]=Bar(101.7,102.0,101.0,101.6)
    # FVG zone [100.2, 101.0]; first touch at next bar with bullish close above 101.0
    b.append(Bar(100.95,101.7,100.7,101.5))
    return b

class FVGTests(unittest.TestCase):
    def test_bullish_first_touch(self):
        b=bullish()
        self.assertTrue(any(x[0]==len(b)-1 and x[1]=="BUY" for x in detect(b)))

    def test_no_retroactive_change_with_future(self):
        b=bullish()
        before=detect(b)
        after=detect(b+base(15))
        self.assertEqual(before,[x for x in after if x[0]<len(b)])

    def test_previously_touched_gap_excluded(self):
        b=bullish()
        # Add earlier first touch; later attempt cannot reuse that same gap
        b.append(Bar(101.3,101.7,100.7,101.5))
        matches=[x for x in detect(b) if x[0]==len(b)-1 and x[2]==len(b)-3]
        self.assertFalse(matches)

    def test_pending_live_candle_excluded(self):
        b=bullish()[:-1]
        b.append(Bar(120,170,40,125))
        self.assertEqual(detect(b[:-1]),detect(bullish()[:-1]))

    def test_no_live_bar_read_in_mql(self):
        for s in ("open[0]","close[0]","high[0]","low[0]","OrderSend("):
            self.assertNotIn(s,SRC)
        for s in ("for(int i=oldest;i>=1;i--)",
                  "if(!rebuild && time[i]<=lastClosed) continue;",
                  "BuyBuffer[0]=EMPTY_VALUE;",
                  "SellBuffer[0]=EMPTY_VALUE;"):
            self.assertIn(s,SRC)

    def test_fvg_formation_and_freshness_are_older_than_signal(self):
        for s in ("for(int j=i+1;j<=i+InpMaxGapAgeBars;j++)",
                  "const double bullSize=low[j]-high[j+2];",
                  "const double bearSize=low[j+2]-high[j];",
                  "for(int k=j-1;k>i;k--)"):
            self.assertIn(s,SRC)

    def test_draw_only_after_confirmation(self):
        self.assertIn("const datetime from=barStart+seconds;",SRC)

if __name__=="__main__":
    unittest.main()
