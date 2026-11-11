"""Independent chronological reference for EMA fast/slow pullback.
Signals occur on CLOSED bars, including confirmation only at that close.
"""
from dataclasses import dataclass

@dataclass(frozen=True)
class Bar:
    open:float
    high:float
    low:float
    close:float

def atr_previous(bars,i,n=14):
    if i<n+1:return 0.
    return sum(max(bars[k].high-bars[k].low,
                   abs(bars[k].high-bars[k-1].close),
                   abs(bars[k].low-bars[k-1].close))
               for k in range(i-n,i))/n

def detect(bars,fast=20,slow=50,atr_period=14,
           touch_tolerance=.10,max_touch_distance=.50,
           resume_distance=.05,min_body=.20,cooldown=2):
    if not bars:return []
    alpha_fast=2/(fast+1)
    alpha_slow=2/(slow+1)
    ema_fast=ema_slow=bars[0].close
    events=[]
    previous_signal=-10**9
    for i,b in enumerate(bars):
        prev_fast,prev_slow=ema_fast,ema_slow
        ema_fast=alpha_fast*b.close+(1-alpha_fast)*ema_fast
        ema_slow=alpha_slow*b.close+(1-alpha_slow)*ema_slow
        if i+1<slow+8 or i==0:continue
        atr=atr_previous(bars,i,atr_period)
        if atr<=0:continue
        p=bars[i-1]
        body=(b.close-b.open)/max(b.high-b.low,1e-9)
        touched_long=(p.low<=prev_fast+touch_tolerance*atr and
                      p.close>=prev_fast-max_touch_distance*atr)
        touched_short=(p.high>=prev_fast-touch_tolerance*atr and
                       p.close<=prev_fast+max_touch_distance*atr)
        buy=(ema_fast>ema_slow and ema_slow>prev_slow and touched_long and
             b.close>ema_fast+resume_distance*atr and body>=min_body)
        sell=(ema_fast<ema_slow and ema_slow<prev_slow and touched_short and
              b.close<ema_fast-resume_distance*atr and body<=-min_body)
        if buy==sell or i-previous_signal<=cooldown:continue
        events.append((i,"BUY" if buy else "SELL"))
        previous_signal=i
    return events
