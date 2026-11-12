import unittest,random,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"research"))
from state_v110 import events
SOURCE=(ROOT/"v1.10"/"Nexus_Session_VWAP_NR_v1.10.mq5").read_text(encoding="utf8")
def base(n,m):return [(1,-1,True)]*n+[(1,1,True)]*m
class DirectionTests(unittest.TestCase):
    def test_wait_for_second_candle(self):
        self.assertEqual(events(base(8,1)),[])
        self.assertEqual(events(base(8,2)),[(9,1)])
    def test_no_repeat_same_side(self):
        self.assertEqual(events(base(8,50)),[(9,1)])
    def test_spacing_bars(self):
        self.assertEqual(events(base(8,2)+[(1,-1,True)]*2+[(1,1,True)]*12),[(9,1)])
    def test_confirmed_reversal(self):
        self.assertEqual(events(base(8,8)+[(1,-1,True)]*2),[(9,1),(17,-1)])
    def test_neutral_is_not_reversal(self):
        self.assertEqual(events([(1,-1,True)]*6+[(1,0,True),(1,1,True),(1,0,True),(1,1,True)]),[])
    def test_prefix_invariance(self):
        r=random.Random(23)
        bars=[(i//30,r.choice([-1,0,1]),r.random()>.2) for i in range(420)]
        whole=events(bars)
        for n in range(1,len(bars),9):
            self.assertEqual(events(bars[:n]),[e for e in whole if e[0]<n])
    def test_mql_buffers_only_closed(self):
        for t in ('InpConfirmCloses    = 2','InpMinBarsBetweenSignals = 8','InpSideDistanceATR  = 0.12','if(side==activeDirection) continue;','BuyBuffer[0]=EMPTY_VALUE;','SellBuffer[0]=EMPTY_VALUE;'):
            self.assertIn(t,SOURCE)
        self.assertNotIn('OrderSend(',SOURCE)
        self.assertIn('#property version "1.10"',SOURCE)
        self.assertIn('InpDrawPlanBars    = 0;',SOURCE)
        self.assertEqual(SOURCE.count('{'),SOURCE.count('}'))
if __name__=='__main__':unittest.main()
