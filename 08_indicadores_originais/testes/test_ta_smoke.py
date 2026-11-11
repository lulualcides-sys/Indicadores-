from pathlib import Path
import sys,unittest
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"02_python_ta"))
import numpy as np
import pandas as pd
from ta.trend import EMAIndicator,ADXIndicator
from ta.volatility import AverageTrueRange,BollingerBands
from ta.momentum import RSIIndicator
from ta.volume import OnBalanceVolumeIndicator,VolumeWeightedAveragePrice
class OriginalTA(unittest.TestCase):
    def test_six_reference_indicators_on_synthetic_ohlcv(self):
        x=np.linspace(0,20,250)
        close=pd.Series(100+np.sin(x)*2+.07*np.arange(250))
        high=close+0.6
        low=close-0.7
        volume=pd.Series(1200+np.arange(250)%50,dtype="float64")
        result={
            "ema20":EMAIndicator(close,window=20).ema_indicator(),
            "adx14":ADXIndicator(high,low,close,window=14).adx(),
            "atr14":AverageTrueRange(high,low,close,window=14).average_true_range(),
            "bollinger20":BollingerBands(close,window=20).bollinger_hband(),
            "rsi14":RSIIndicator(close,window=14).rsi(),
            "obv":OnBalanceVolumeIndicator(close,volume).on_balance_volume(),
            "vwap14":VolumeWeightedAveragePrice(high,low,close,volume,window=14).volume_weighted_average_price(),
        }
        for name,v in result.items():
            self.assertEqual(len(v),250,name)
            self.assertTrue(np.isfinite(float(v.iloc[-1])),name)
    def test_warmup_nan_is_not_a_trade_signal(self):
        close=pd.Series([100.+j*0.25 for j in range(60)])
        rsi=RSIIndicator(close,window=14).rsi()
        self.assertTrue(pd.isna(rsi.iloc[0]))
        self.assertTrue(pd.notna(rsi.iloc[-1]))
if __name__=="__main__":unittest.main()
