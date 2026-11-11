"""Independent chronological Python reference for Nexus Clean Signals NR v1.00.
Closed-bar-only input. Output events are NOT market trades.
"""
from dataclasses import dataclass
from math import fabs

@dataclass(frozen=True)
class Bar:
    open: float
    high: float
    low: float
    close: float
    spread: int = 0

def clamp(x):
    return max(0.0, min(1.0, x))

def previous_atr(bars, i, period):
    if i < period + 1:
        return 0.0
    tr = []
    for k in range(i-period, i):
        b, prior = bars[k], bars[k-1]
        tr.append(max(b.high-b.low, abs(b.high-prior.close), abs(b.low-prior.close)))
    return sum(tr)/period

def previous_er(bars, i, period):
    if i < period + 1:
        return 0.0
    net = abs(bars[i-1].close-bars[i-period-1].close)
    path = sum(abs(bars[k].close-bars[k-1].close) for k in range(i-period, i))
    return clamp(net/path) if path else 0.0

def detect(bars, mode="AUTO", lookback=18, atr_period=14, er_period=12,
           range_er=.25, trend_er=.43, min_break_atr=.07, min_sweep_atr=.06,
           min_reclaim_atr=.02, min_body=.22, min_wick=.28,
           min_score=.43, cooldown=1, max_spread=0, sl_buffer=.08):
    """Only closed bars supplied; event becomes actionable after its bar closes.
    Returns tuple (index, side, kind, score, reference_entry, sl).
    """
    if mode not in {"AUTO", "BREAKOUT", "SWEEP"}:
        raise ValueError(mode)
    events=[]
    # Signal always requires the same older-bar ATR and ER context as the MQL5 code.
    start=max(lookback, atr_period+1, er_period+1)
    last_idx=-10**9
    for i in range(start, len(bars)):
        prev=bars[i-lookback:i]
        top=max(b.high for b in prev)
        bottom=min(b.low for b in prev)
        atr=previous_atr(bars, i, atr_period)
        if atr<=0 or top<=bottom:
            continue
        er=previous_er(bars,i,er_period)
        b=bars[i]
        rng=max(b.high-b.low,1e-10)
        body=(b.close-b.open)/rng
        upper_wick=b.high-max(b.open,b.close)
        lower_wick=min(b.open,b.close)-b.low
        allow_break=(mode=="BREAKOUT" or (mode=="AUTO" and er>=range_er))
        allow_sweep=(mode=="SWEEP" or (mode=="AUTO" and er<=trend_er))
        direction=0
        kind=""
        score=0.
        if allow_break and b.close>top+min_break_atr*atr and body>=min_body:
            direction=1
            kind="BREAKOUT"
            score=(.50*clamp(body/.65)+.35*clamp((b.close-top)/(.55*atr))
                   +.15*clamp(er/.60))
        elif allow_break and b.close<bottom-min_break_atr*atr and body<=-min_body:
            direction=-1
            kind="BREAKOUT"
            score=(.50*clamp(-body/.65)+.35*clamp((bottom-b.close)/(.55*atr))
                   +.15*clamp(er/.60))
        elif (allow_sweep and b.low<bottom-min_sweep_atr*atr and
              b.close>bottom+min_reclaim_atr*atr and
              body>0 and lower_wick/rng>=min_wick):
            direction=1
            kind="SWEEP"
            score=(.50*clamp((lower_wick/rng)/.60)
                   +.35*clamp((b.close-bottom)/(.55*atr))
                   +.15*clamp((1-er)/.75))
        elif (allow_sweep and b.high>top+min_sweep_atr*atr and
              b.close<top-min_reclaim_atr*atr and
              body<0 and upper_wick/rng>=min_wick):
            direction=-1
            kind="SWEEP"
            score=(.50*clamp((upper_wick/rng)/.60)
                   +.35*clamp((top-b.close)/(.55*atr))
                   +.15*clamp((1-er)/.75))
        if score<min_score or (max_spread and b.spread>max_spread):
            direction=0
        if i-last_idx<=cooldown:
            direction=0
        if not direction:
            continue
        sl=b.low-sl_buffer*atr if direction==1 else b.high+sl_buffer*atr
        risk=direction*(b.close-sl)
        if risk<=0:continue
        events.append((i,"BUY" if direction==1 else "SELL",kind,round(score,8),b.close,sl))
        last_idx=i
    return events
