import importlib.util,sys,unittest,random
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location("squeeze_reference",ROOT/"research/reference.py")
ref=importlib.util.module_from_spec(spec);sys.modules[spec.name]=ref;spec.loader.exec_module(ref)
SRC=(ROOT/"v1.00/Nexus_Volatility_Squeeze_NR.mq5").read_text()
def flat(n=70):
    return [ref.Bar(100,101,99,100) for _ in range(n)]
class SqueezeTests(unittest.TestCase):
    def test_bull_release(self):
        b=flat()+[ref.Bar(100,114,99,113)]
        self.assertEqual(ref.detect(b)[-1],(len(b)-1,"BUY"))
    def test_bear_release(self):
        b=flat()+[ref.Bar(100,101,86,87)]
        self.assertEqual(ref.detect(b)[-1],(len(b)-1,"SELL"))
    def test_flat_has_no_signals(self):
        self.assertEqual(ref.detect(flat()),[])
    def test_no_lookahead_prefix(self):
        rnd=random.Random(27);p=100;bars=[]
        for _ in range(250):
            o=p;c=o+rnd.uniform(-2,2)
            bars.append(ref.Bar(o,max(o,c)+rnd.uniform(.05,.5),min(o,c)-rnd.uniform(.05,.5),c));p=c
        all_events=ref.detect(bars)
        for end in range(35,len(bars),7):
            self.assertEqual(ref.detect(bars[:end]),[x for x in all_events if x[0]<end])
    def test_mql_closed_bar_guards(self):
        for token in ("for(int i=oldest;i>=1;i--)","if(!rebuild && time[i]<=previousClosed) continue;",
                      "BuyBuffer[0]=EMPTY_VALUE;","SellBuffer[0]=EMPTY_VALUE;",
                      "const bool wasCompressed=","const bool releasedNow="):
            self.assertIn(token,SRC)
        for t in ("close[0]","open[0]","high[0]","low[0]","OrderSend("):self.assertNotIn(t,SRC)
    def test_buffers_for_ea(self):
        self.assertIn("#property indicator_buffers 2",SRC)
        self.assertIn("SetIndexBuffer(0,BuyBuffer",SRC)
        self.assertIn("SetIndexBuffer(1,SellBuffer",SRC)
if __name__=="__main__":unittest.main()
