import unittest
from dataclasses import replace
from pathlib import Path
from random import Random
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "research"))
from reference import Bar, scan

SOURCE = (ROOT / "v1.00" / "Nexus_Liquidity_Sweep_NR.mq5").read_text(encoding="utf-8")

def sample():
    r=Random(14)
    bars=[]
    p=100.
    for _ in range(100):
        o=p
        c=o+r.uniform(-.18,.18)
        bars.append(Bar(o,max(o,c)+r.uniform(.05,.2),min(o,c)-r.uniform(.05,.2),c))
        p=c
    return bars

class SweepTests(unittest.TestCase):
    def test_confirmed_sell(self):
        bars=sample()
        upper=max(x.high for x in bars[-20:])
        bars.append(Bar(upper+.6,upper+2.,upper-1.7,upper-1.0))
        self.assertEqual(scan(bars)[-1][1],"SELL")

    def test_confirmed_buy(self):
        bars=sample()
        lower=min(x.low for x in bars[-20:])
        bars.append(Bar(lower-.6,lower+1.7,lower-2.0,lower+1.0))
        self.assertEqual(scan(bars)[-1][1],"BUY")

    def test_no_signal_when_breakout_holds(self):
        bars=sample()
        upper=max(x.high for x in bars[-20:])
        bars.append(Bar(upper+.2,upper+2.0,upper+.1,upper+1.7))
        self.assertFalse(any(e[0]==len(bars)-1 for e in scan(bars)))

    def test_zero_future_leakage_by_prefix(self):
        bars=sample()
        initial=scan(bars)
        bars2=bars+sample()[:10]
        extended=scan(bars2)
        self.assertEqual(initial,[e for e in extended if e[0]<len(bars)])

    def test_forming_bar_never_consumed(self):
        bars=sample()
        x=bars+[Bar(120,150,80,90)]
        self.assertEqual(scan(bars),scan(x[:-1]))

    def test_targets_and_stops(self):
        bars=sample()
        upper=max(x.high for x in bars[-20:])
        bars.append(Bar(upper+.6,upper+2.,upper-1.7,upper-1.0))
        e=scan(bars)[-1]
        self.assertGreater(e[4],e[3])
        self.assertLess(e[5],e[3])
        self.assertLess(e[6],e[5])
        self.assertLess(e[7],e[6])

    def test_mql_closed_candle_and_write_once_guards(self):
        for token in ("for(int i=oldest;i>=1;i--)",
                      "if(!rebuild && time[i]<=previousClosed) continue;",
                      "BuyBuffer[0]=EMPTY_VALUE;",
                      "SellBuffer[0]=EMPTY_VALUE;",
                      "UpperBuffer[0]=EMPTY_VALUE;",
                      "LowerBuffer[0]=EMPTY_VALUE;"):
            self.assertIn(token,SOURCE)
        for token in ("open[0]", "high[0]", "low[0]", "close[0]", "OrderSend(", "trade.Buy("):
            self.assertNotIn(token,SOURCE)

    def test_mql_atr_older_and_signal_plans_after_close(self):
        self.assertIn("for(int j=i+1;j<=i+InpATRPeriod;j++)",SOURCE)
        self.assertIn("for(int j=i+1;j<=i+InpLookbackBars;j++)",SOURCE)
        self.assertIn("const datetime when=closedBar+barSeconds;",SOURCE)

    def test_mql_plot_contract(self):
        for token in ("#property indicator_buffers 4",
                      "#property indicator_plots 4",
                      "PLOT_ARROW,233","PLOT_ARROW,234",
                      "const bool rebuild=(prev_calculated==0 || g_seenOpen==0);"):
            self.assertIn(token,SOURCE)

if __name__ == "__main__":
    unittest.main()
