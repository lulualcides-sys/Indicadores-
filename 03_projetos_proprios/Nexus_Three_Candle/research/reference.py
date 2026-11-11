"""Independent closed-bar 3-candle reversal model."""
from dataclasses import dataclass
@dataclass(frozen=True)
class Bar:
    open:float
    high:float
    low:float
    close:float

def atr_previous(bars,i,n=14):
    if i<n+1:return 0.
    total=0.
    for j in range(i-n,i):
        b=bars[j];p=bars[j-1].close
        total+=max(b.high-b.low,abs(b.high-p),abs(b.low-p))
    return total/n

def detect(bars,atr_period=14,confirm_atr=.03,min_body=.24,
           min_first_body_atr=.15,cooldown=2):
    events=[];last=-999999
    for i in range(max(atr_period+2,3),len(bars)):
        atr=atr_previous(bars,i,atr_period)
        if atr<=0:continue
        a,m,c=bars[i-2],bars[i-1],bars[i]
        midpoint=(a.open+a.close)/2.
        if abs(a.open-a.close)<min_first_body_atr*atr:continue
        frac=(c.close-c.open)/max(c.high-c.low,1e-12)
        buy=(a.open>a.close and m.low<a.low and m.close<=a.close and
             c.close>midpoint+confirm_atr*atr and c.close>c.open and frac>=min_body)
        sell=(a.open<a.close and m.high>a.high and m.close>=a.close and
              c.close<midpoint-confirm_atr*atr and c.close<c.open and frac<=-min_body)
        if buy==sell or i-last<=cooldown:continue
        events.append((i,"BUY" if buy else "SELL"))
        last=i
    return events
