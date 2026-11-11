import sys,random,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"research"))
from reference import Bar,detect
SRC=(ROOT/"v1.00"/"Nexus_Three_Candle_NR.mq5").read_text(encoding="utf-8")
def flat(n=75):
    return [Bar(100,100.4,99.6,100) for _ in range(n)]
class ThreeCandleTests(unittest.TestCase):
    def test_buy_after_3_full_candles(self):
        b=flat()+[
            Bar(104,104.2,99,100),
            Bar(100,100.4,96,98),
            Bar(98,103.8,97.8,103.5)
        ]
        self.assertIn((len(b)-1,"BUY"),detect(b))
    def test_sell_after_3_full_candles(self):
        b=flat()+[
            Bar(96,101,95.8,100),
            Bar(100,104,99.7,102),
            Bar(102,102.3,96.2,96.6)
        ]
        self.assertIn((len(b)-1,"SELL"),detect(b))
    def test_no_signal_before_third_candle(self):
        b=flat()+[Bar(104,104.2,99,100),Bar(100,100.4,96,98)]
        self.assertFalse(any(i>=len(b)-2 for i,_ in detect(b)))
    def test_prefix_stability(self):
        rnd=random.Random(44);p=100;bars=[]
        for _ in range(240):
            o=p;cl=o+rnd.uniform(-2,2)
            bars.append(Bar(o,max(o,cl)+.35,min(o,cl)-.35,cl));p=cl
        full=detect(bars)
        for n in range(25,len(bars),8):
            self.assertEqual(detect(bars[:n]),[x for x in full if x[0]<n])
    def test_mql_no_future(self):
        for token in ("for(int i=oldest;i>=1;i--)","low[i+1]<low[i+2]","if(!rebuild && time[i]<=previousClosed) continue;",
                      "BuyBuffer[0]=EMPTY_VALUE;","SellBuffer[0]=EMPTY_VALUE;"):
            self.assertIn(token,SRC)
        for token in ("close[0]","high[0]","low[0]","open[0]","OrderSend("):
            self.assertNotIn(token,SRC)
    def test_ea_buffer_contract(self):
        self.assertIn("SetIndexBuffer(0,BuyBuffer,INDICATOR_DATA);",SRC)
        self.assertIn("SetIndexBuffer(1,SellBuffer,INDICATOR_DATA);",SRC)
if __name__=="__main__":unittest.main()
