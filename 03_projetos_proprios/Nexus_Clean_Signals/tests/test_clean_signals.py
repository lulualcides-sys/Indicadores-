"""Synthetic non-repaint tests; not MT5 compilation or profitability tests."""
from pathlib import Path
import random
import sys
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"research"))
from reference import Bar, detect, previous_er

SRC=(ROOT/"v1.00"/"Nexus_Clean_Signals_NR.mq5").read_text(encoding="utf-8")

def flat(n=55):
    return [Bar(100.0,101.0,99.0,100.0) for _ in range(n)]

def stochastic(seed=22,n=230):
    rng=random.Random(seed)
    p=100.0
    out=[]
    for _ in range(n):
        op=p
        cl=p+rng.uniform(-.5,.5)
        hi=max(op,cl)+rng.uniform(.03,.45)
        lo=min(op,cl)-rng.uniform(.03,.45)
        out.append(Bar(op,hi,lo,cl))
        p=cl
    return out

class CleanSignalTests(unittest.TestCase):
    def test_buy_breakout(self):
        b=flat()+[Bar(100.2,104.4,100.0,103.9)]
        e=detect(b,mode="BREAKOUT")
        self.assertTrue(any(x[0]==len(b)-1 and x[1]=="BUY" and x[2]=="BREAKOUT" for x in e))

    def test_sell_breakout(self):
        b=flat()+[Bar(99.8,100.0,95.8,96.2)]
        e=detect(b,mode="BREAKOUT")
        self.assertTrue(any(x[0]==len(b)-1 and x[1]=="SELL" for x in e))

    def test_buy_sweep(self):
        b=flat()+[Bar(100.1,101.1,95.5,100.7)]
        e=detect(b,mode="SWEEP")
        self.assertTrue(any(x[0]==len(b)-1 and x[1]=="BUY" and x[2]=="SWEEP" for x in e))

    def test_sell_sweep(self):
        b=flat()+[Bar(100.4,104.5,99.9,99.6)]
        e=detect(b,mode="SWEEP")
        self.assertTrue(any(x[0]==len(b)-1 and x[1]=="SELL" for x in e))

    def test_auto_ranging_prefers_sweep(self):
        b=flat()
        self.assertEqual(previous_er(b,len(b),12),0.0)
        self.assertFalse(any(x[0]==len(b) for x in detect(b+[Bar(100.2,104.4,100.0,103.9)],mode="AUTO")))
        self.assertEqual(detect(b+[Bar(100.1,101.1,95.5,100.7)],mode="AUTO")[-1][2],"SWEEP")

    def test_automatic_trend_accepts_breakout(self):
        # Build a strong directional history. Prior highs can still be broken.
        b=[]
        for i in range(60):
            o=100.+i*.30
            b.append(Bar(o,o+.65,o-.15,o+.45))
        self.assertGreater(previous_er(b,len(b),12),.9)
        nxt=Bar(b[-1].close+.2,b[-1].close+1.8,b[-1].close+.1,b[-1].close+1.65)
        events=detect(b+[nxt],mode="AUTO")
        self.assertTrue(any(x[0]==len(b) and x[2]=="BREAKOUT" for x in events))

    def test_non_repaint_prefix_all_modes(self):
        b=stochastic()
        for mode in ("AUTO","BREAKOUT","SWEEP"):
            whole=detect(b,mode=mode)
            for end in range(38,len(b),9):
                partial=detect(b[:end],mode=mode)
                self.assertEqual(partial,[x for x in whole if x[0]<end])

    def test_live_bar_not_part_of_snapshot(self):
        b=stochastic()
        live=Bar(400,500,0,50)
        for mode in ("AUTO","BREAKOUT","SWEEP"):
            self.assertEqual(detect(b,mode=mode),detect((b+[live])[:-1],mode=mode))

    def test_cooldown(self):
        b=stochastic()
        e=detect(b,mode="BREAKOUT",cooldown=4)
        for first,second in zip(e,e[1:]):
            self.assertGreater(second[0]-first[0],4)

    def test_score_is_not_probability(self):
        b=stochastic()
        for event in detect(b):
            self.assertTrue(0<=event[3]<=1)

    def test_closed_buffer_guards(self):
        self.assertIn("BuyBuffer[0]=EMPTY_VALUE;",SRC)
        self.assertIn("SellBuffer[0]=EMPTY_VALUE;",SRC)
        self.assertIn("for(int i=oldest;i>=1;i--)",SRC)
        self.assertIn("if(rebuild || time[i]>previouslyClosed)",SRC)
        self.assertIn("if(!rebuild && time[0]==g_seenBarOpen)",SRC)
        for s in ("close[0]","open[0]","high[0]","low[0]","OrderSend(", "trade.Buy("):
            self.assertNotIn(s,SRC)

    def test_reference_atr_and_er_are_prior_only(self):
        self.assertIn("for(int k=i+1;k<=i+InpATRPeriod;k++)",SRC)
        self.assertIn("for(int k=i+1;k<=i+InpERPeriod;k++)",SRC)
        self.assertIn("for(int k=i+1;k<=i+InpRangeBars;k++)",SRC)

    def test_plan_starts_at_next_bar(self):
        self.assertIn("time[lastSignalIndex-1]",SRC)
        self.assertIn("ObjectsDeleteAll(0,g_prefix+\"PLAN_\"",SRC)
        self.assertIn("if(InpView!=NCS_LAST_PLAN || direction==0) return;",SRC)

    def test_default_is_clean_mode(self):
        self.assertIn("InpView          = NCS_CLEAN;",SRC)
        self.assertIn("InpShowDashboard          = true;",SRC)
        self.assertIn("NCS_AUTO=0, NCS_BREAKOUT=1, NCS_SWEEP=2",SRC)

if __name__=="__main__":
    unittest.main()
