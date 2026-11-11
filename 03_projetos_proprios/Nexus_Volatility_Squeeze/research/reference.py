"""Independent chronological reference to BB/Keltner squeeze-release arrows.
Only completely closed bars may be passed; not a financial backtest.
"""
from dataclasses import dataclass
from math import sqrt

@dataclass(frozen=True)
class Bar:
    open:float
    high:float
    low:float
    close:float

def atr_including(bars,i,period):
    if i<period: return 0.0
    return sum(max(bars[j].high-bars[j].low,
                   abs(bars[j].high-bars[j-1].close),
                   abs(bars[j].low-bars[j-1].close))
               for j in range(i-period+1,i+1))/period

def bb_half(bars,i,n,deviation):
    vals=[bars[j].close for j in range(i-n+1,i+1)]
    mean=sum(vals)/n
    return deviation*sqrt(sum((v-mean)**2 for v in vals)/n)

def detect(bars,bb_period=20,bb_deviation=2.,atr_period=20,
           keltner_atr=1.5,lookback=12,min_break_atr=.02,
           min_body=.20):
    out=[]
    start=max(bb_period,atr_period+1,lookback)
    for i in range(start,len(bars)):
        before=atr_including(bars,i-1,atr_period)
        now=atr_including(bars,i,atr_period)
        if not now or not before:continue
        was=bb_half(bars,i-1,bb_period,bb_deviation)<=keltner_atr*before
        release=bb_half(bars,i,bb_period,bb_deviation)>keltner_atr*now
        if not was or not release:continue
        old=bars[i-lookback:i]
        high=max(v.high for v in old)
        low=min(v.low for v in old)
        candle=bars[i]
        body=(candle.close-candle.open)/max(candle.high-candle.low,1e-9)
        buy=candle.close>high+min_break_atr*before and body>=min_body
        sell=candle.close<low-min_break_atr*before and body<=-min_body
        if buy==sell:continue
        out.append((i,"BUY" if buy else "SELL"))
    return out
