import unittest
from pathlib import Path
P=Path(__file__).resolve().parents[1]/"v1.00"/"Nexus_VWAP_Fusion_Forex_v1.00.mq5"
S=P.read_text(encoding="utf-8")
def evaluate_partials(direction, entry, stop, candles, spread=0.0, point=0.01, maxbars=48):
    risk=direction*(entry-stop)
    targets=[entry+direction*risk*r for r in (1,1.5,2)]
    realized=0.0;nexttp=0
    for i,(o,h,l,c) in enumerate(candles[:maxbars],1):
        hi=h if direction>0 else h+spread
        lo=l if direction>0 else l+spread
        op=o if direction>0 else o+spread
        stophit=lo<=stop if direction>0 else hi>=stop
        if stophit:
            fill=min(op,stop) if direction>0 else max(op,stop)
            return realized+direction*(fill-entry)/point*(3-nexttp)/3.0
        while nexttp<3:
            hit=hi>=targets[nexttp] if direction>0 else lo<=targets[nexttp]
            if not hit: break
            realized+=direction*(targets[nexttp]-entry)/(point*3.0);nexttp+=1
        if nexttp==3:return realized
        if i==maxbars:
            end=c if direction>0 else c+spread
            return realized+direction*(end-entry)/point*(3-nexttp)/3.0
    return None
class FusionContract(unittest.TestCase):
    def test_header_and_buffers(self):
        self.assertIn('#property version "1.00"',S)
        self.assertEqual(S.count('SetIndexBuffer('),5)
        self.assertEqual(S.count('{'),S.count('}'))
    def test_three_distinct_tp(self):
        for t in ('InpTP1R=1.00','InpTP2R=1.50','InpTP3R=2.00','trade.nextTP=3;'):
            self.assertIn(t,S)
    def test_small_arrows(self):
        for t in ('#property indicator_width1 1','#property indicator_width2 1','if(i==0) break;'):
            self.assertIn(t,S)
    def test_uses_past_prices(self):
        for t in ('close[0]','high[0]','low[0]','OrderSend(','WebRequest('):
            self.assertNotIn(t,S)
    def test_no_retro_sound(self):
        self.assertIn('newlyOpened && g_alertedEntry!=time[i]',S)
        self.assertIn('PlaySound(InpSoundFile)',S)
    def test_risk_outcome_green_150_points(self):
        p=evaluate_partials(1,2000,1999,[(2000,2002.2,1999.9,2002)])
        self.assertAlmostEqual(p,150)
    def test_first_tp_then_stop_net_red(self):
        p=evaluate_partials(1,2000,1999,[(2000,2001.2,1999.9,2001),(2001,2001.3,1998.9,1999)])
        self.assertAlmostEqual(p,-100/3)
    def test_sl_tp_same_bar_stop_first(self):
        p=evaluate_partials(1,2000,1999,[(2000,2003,1998.8,2002)])
        self.assertAlmostEqual(p,-100)
    def test_sell_tp(self):
        p=evaluate_partials(-1,2000,2001,[(2000,2000.1,1997.8,1998)])
        self.assertAlmostEqual(p,150)
    def test_sell_spread_worsens_fill(self):
        p=evaluate_partials(-1,2000,2001,[(2000,2000.95,1999.3,1999.4)],spread=.1)
        self.assertAlmostEqual(p,-100)
    def test_conservative_gap(self):
        p=evaluate_partials(1,2000,1999,[(1998.2,2000,1998,1999)])
        self.assertAlmostEqual(p,-180)
    def test_daily_partial_guard(self):
        self.assertIn('firstPartialSession',S)
        self.assertIn('if(currentDay!=-1) firstPartialSession=false;',S)
    def test_score_sources(self):
        for key in ('emaFast-emaSlow','RelativeVolume(','StructureScore(','weightedPrice/weights'):
            self.assertIn(key,S)
if __name__=='__main__':unittest.main()
