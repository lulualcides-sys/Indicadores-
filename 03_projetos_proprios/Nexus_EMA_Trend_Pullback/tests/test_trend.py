import importlib.util,sys,unittest,random
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sp=importlib.util.spec_from_file_location("trend_reference",ROOT/"research/reference.py")
ref=importlib.util.module_from_spec(sp);sys.modules[sp.name]=ref;sp.loader.exec_module(ref)
SRC=(ROOT/"v1.00/Nexus_EMA_Trend_Pullback_NR.mq5").read_text()
def series_up(n=140):
    return [ref.Bar(100+.20*i,100+.20*i+.3,100+.20*i-.3,100+.20*i+.1) for i in range(n)]
def series_down(n=140):
    return [ref.Bar(150-.20*i,150-.20*i+.3,150-.20*i-.3,150-.20*i-.1) for i in range(n)]
class TrendPullbackTests(unittest.TestCase):
    def test_long_pullback_then_resume(self):
        b=series_up()
        fast=b[0].close
        for candle in b[1:]:
            fast=(2/21)*candle.close+(19/21)*fast
        # Pullback touches last EMA, then closed bullish recovery.
        b.append(ref.Bar(b[-1].close,b[-1].close+.2,fast-.14,fast+.04))
        b.append(ref.Bar(fast+.04,fast+1.0,fast-.02,fast+.85))
        self.assertIn((len(b)-1,"BUY"),ref.detect(b))
    def test_short_pullback_then_resume(self):
        b=series_down()
        fast=b[0].close
        for candle in b[1:]:
            fast=(2/21)*candle.close+(19/21)*fast
        b.append(ref.Bar(b[-1].close,fast+.14,b[-1].close-.2,fast-.04))
        b.append(ref.Bar(fast-.04,fast+.02,fast-1.0,fast-.85))
        self.assertIn((len(b)-1,"SELL"),ref.detect(b))
    def test_no_future_leakage(self):
        rnd=random.Random(36);p=100;bars=[]
        for _ in range(240):
            o=p;c=o+rnd.uniform(-.4,.4)
            bars.append(ref.Bar(o,max(o,c)+.2,min(o,c)-.2,c));p=c
        full=ref.detect(bars)
        for end in range(65,len(bars),9):
            self.assertEqual(ref.detect(bars[:end]),[x for x in full if x[0]<end])
    def test_flat_no_trend(self):
        bars=[ref.Bar(100,101,99,100) for _ in range(90)]
        self.assertEqual(ref.detect(bars),[])
    def test_mql_closed_bar_guards(self):
        for t in ("for(int i=oldest;i>=1;i--)","BuyBuffer[0]=EMPTY_VALUE;",
                  "SellBuffer[0]=EMPTY_VALUE;","const double previousFast=emaFast,previousSlow=emaSlow;"):
            self.assertIn(t,SRC)
        for t in ("close[0]","high[0]","low[0]","open[0]","OrderSend("):
            self.assertNotIn(t,SRC)
    def test_older_buffers_stabilize_cooldown(self):
        self.assertIn("if(!rebuild && time[i]<=previousClosed)",SRC)
        self.assertIn("lastSignal=i",SRC)
if __name__=="__main__":unittest.main()
