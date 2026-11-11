"""Python reference for session VWAP reclaim, using CLOSED bars only."""
from dataclasses import dataclass

@dataclass(frozen=True)
class Bar:
    day:int
    open:float
    high:float
    low:float
    close:float
    volume:float

def calc(bars, min_session=5, rvol_window=20, min_score=.42):
    """Data are closed bars in chronological order; outputs indices of confirmed signals."""
    daily={}
    out=[]
    for i,bar in enumerate(bars):
        w,s,s2,count=daily.get(bar.day,(0.,0.,0.,0))
        previous=s/w if w else None
        typ=(bar.high+bar.low+bar.close)/3
        vol=max(1.,bar.volume)
        w+=vol
        s+=typ*vol
        s2+=typ*typ*vol
        count+=1
        vwap=s/w
        daily[bar.day]=(w,s,s2,count)
        if i==0 or count<min_session or previous is None or i<rvol_window+2:
            continue
        prev=bars[i-1]
        if prev.day!=bar.day:
            continue
        recent=bars[i-rvol_window:i]
        rvol=vol/(sum(max(1.,b.volume) for b in recent)/rvol_window)
        buy=prev.close<=previous and bar.close>vwap and bar.close>bar.open
        sell=prev.close>=previous and bar.close<vwap and bar.close<bar.open
        if buy==sell:
            continue
        sign=1 if buy else -1
        body=sign*(bar.close-bar.open)
        quality=body/max(1e-9,bar.high-bar.low)
        # ATR exclusively from PRIOR closed bars
        atr=sum(max(b.high-b.low,abs(b.high-bars[j-1].close),
                    abs(b.low-bars[j-1].close))
                for j,b in ((k,bars[k]) for k in range(i-14,i)))/14
        if atr<=0:
            continue
        reclaim=sign*(bar.close-vwap)
        clip=lambda x:max(0.,min(1.,x))
        score=.40*clip(quality/.70)+.35*clip(reclaim/(.60*atr))+.25*clip(rvol/1.80)
        if score>=min_score:
            out.append((i,"BUY" if buy else "SELL",round(score,8)))
    return out
