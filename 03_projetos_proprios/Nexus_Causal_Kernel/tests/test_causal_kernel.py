import sys,unittest,random
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"research"))
from reference import Bar,endpoint,detect
SRC=(ROOT/"v1.00"/"Nexus_Causal_Kernel_NR.mq5").read_text(encoding="utf-8")
def flat(n=90):
    return [Bar(100,100.3,99.7,100) for _ in range(n)]
class TestKernel(unittest.TestCase):
    def test_causal_endpoint_is_unchanged_when_future_is_added(self):
        b=flat()
        old=endpoint(b,55)
        b2=b+[Bar(500,900,1,50),Bar(50,70,2,5)]
        self.assertEqual(old,endpoint(b2,55))
    def test_long_extreme_then_reentry(self):
        b=flat()+[Bar(100,100.5,85,86),Bar(86,102,85,100)]
        self.assertTrue(any(x[0]==len(b)-1 and x[1]=="BUY" for x in detect(b)))
    def test_short_extreme_then_reentry(self):
        b=flat()+[Bar(100,115,99,114),Bar(114,115,98,100)]
        self.assertTrue(any(x[0]==len(b)-1 and x[1]=="SELL" for x in detect(b)))
    def test_temporal_prefix_invariance(self):
        rnd=random.Random(28);p=100;bars=[]
        for _ in range(180):
            op=p;cl=p+rnd.uniform(-2,2)
            bars.append(Bar(op,max(op,cl)+.4,min(op,cl)-.4,cl));p=cl
        e=detect(bars)
        for stop in range(50,len(bars),7):
            self.assertEqual(detect(bars[:stop]),[x for x in e if x[0]<stop])
    def test_mql_closed_bar_no_symmetric_window(self):
        for token in ("for(int i=oldest;i>=1;i--)","close[i+k]","if(!rebuild && time[i]<=previousClosed) continue;",
                      "BuyBuffer[0]=EMPTY_VALUE;","SellBuffer[0]=EMPTY_VALUE;"):
            self.assertIn(token,SRC)
        for token in ("close[0]","high[0]","low[0]","open[0]","OrderSend("):
            self.assertNotIn(token,SRC)
    def test_no_future_signals_and_buffer_contract(self):
        self.assertIn("SetIndexBuffer(0,BuyBuffer,INDICATOR_DATA);",SRC)
        self.assertIn("SetIndexBuffer(1,SellBuffer,INDICATOR_DATA);",SRC)
        self.assertEqual(detect(flat()),[])
if __name__=="__main__":unittest.main()
