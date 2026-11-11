from dataclasses import dataclass

@dataclass(frozen=True)
class Bar:
    open:float
    high:float
    low:float
    close:float

def atr_before(bars,i,n=14):
    if i<n+1: return 0.0
    s=0.0
    for j in range(i-n,i):
        b=bars[j];prev=bars[j-1].close
        s+=max(b.high-b.low,abs(b.high-prev),abs(b.low-prev))
    return s/n

def detect(bars,left=3,right=3,atr_period=14,atr_break=.03,min_body=.2):
    """Returns (index, direction, kind). Every entry is available after bar[index] CLOSE."""
    hi=lo=None;trend=0;hi_used=lo_used=False
    out=[]
    for i in range(max(left+right+1,atr_period+2),len(bars)):
        c=i-right
        if c-left>=0:
            if (all(bars[c].high>bars[c-k].high for k in range(1,left+1)) and
                all(bars[c].high>bars[c+k].high for k in range(1,right+1))):
                hi=bars[c].high;hi_used=False
            if (all(bars[c].low<bars[c-k].low for k in range(1,left+1)) and
                all(bars[c].low<bars[c+k].low for k in range(1,right+1))):
                lo=bars[c].low;lo_used=False
        if hi is None or lo is None:
            continue
        b=bars[i];p=bars[i-1]
        atr=atr_before(bars,i,atr_period)
        if atr<=0:
            continue
        body=(b.close-b.open)/max(1e-9,b.high-b.low)
        up=(not hi_used and body>=min_body and b.close>=hi+atr_break*atr and p.close<=hi)
        dn=(not lo_used and body<=-min_body and b.close<=lo-atr_break*atr and p.close>=lo)
        if up==dn:
            continue
        direction=1 if up else -1
        kind="CHoCH" if trend!=0 and trend!=direction else "BOS"
        trend=direction
        if up: hi_used=True
        else: lo_used=True
        out.append((i,"BUY" if up else "SELL",kind))
    return out
