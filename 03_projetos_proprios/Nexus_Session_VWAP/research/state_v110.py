"""Reference of closed-candle direction state only (no financial PnL)."""
def events(candles,confirm=2,cooldown=8):
    observed=0;pending=0;streak=0;active=0;last=-1000000;day=None;signals=[]
    for i,(d,side,eligible) in enumerate(candles):
        if d!=day:day=d;observed=pending=streak=0
        if side==0:pending=streak=0;continue
        if observed==0:observed=side;continue
        if side!=observed:observed=pending=side;streak=1
        elif pending==side:streak+=1
        if pending!=side or streak<confirm:continue
        pending=streak=0
        if side==active or i-last<cooldown or not eligible:continue
        active=side;last=i;signals.append((i,side))
    return signals
