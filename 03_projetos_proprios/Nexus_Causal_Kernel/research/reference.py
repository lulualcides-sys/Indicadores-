"""Original causal endpoint Gaussian smoother and recovery event detection.
Input data MUST contain only fully closed candles; no repaint by future bars.
"""
from dataclasses import dataclass
from math import exp
@dataclass(frozen=True)
class Bar:
    open:float
    high:float
    low:float
    close:float

def endpoint(bars,index,window=40,bandwidth=9.0):
    if index+1<window:
        return None
    w=[exp(-.5*(k/bandwidth)**2) for k in range(window)]
    p=[bars[index-k].close for k in range(window)]
    s=sum(w)
    basis=sum(a*b for a,b in zip(w,p))/s
    mad=sum(a*abs(b-basis) for a,b in zip(w,p))/s
    return basis,mad

def atr_before(bars,index,period=14):
    if index<period+1:return 0.
    total=0.
    for j in range(index-period,index):
        b=bars[j];pc=bars[j-1].close
        total+=max(b.high-b.low,abs(b.high-pc),abs(b.low-pc))
    return total/period

def detect(bars,window=40,bandwidth=9.,multiplier=2.,atr_period=14,
           floor_atr=.2,body_min=.12,cooldown=2):
    events=[]
    last=-999999
    for i in range(max(window+1,atr_period+2),len(bars)):
        cur=endpoint(bars,i,window,bandwidth)
        prev=endpoint(bars,i-1,window,bandwidth)
        atr=atr_before(bars,i,atr_period)
        patr=atr_before(bars,i-1,atr_period)
        if cur is None or prev is None or atr<=0 or patr<=0:continue
        base,mad=cur;pbase,pmad=prev
        width=max(multiplier*mad,floor_atr*atr)
        pwidth=max(multiplier*pmad,floor_atr*patr)
        b=bars[i]
        body=(b.close-b.open)/max(b.high-b.low,1e-12)
        buy=(bars[i-1].close<pbase-pwidth and b.close>base-width and body>=body_min)
        sell=(bars[i-1].close>pbase+pwidth and b.close<base+width and body<=-body_min)
        if buy==sell or i-last<=cooldown:continue
        events.append((i,"BUY" if buy else "SELL"))
        last=i
    return events
