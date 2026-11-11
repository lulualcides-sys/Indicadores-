"""Modelo de referencia independente para verificar causalidade do Nexus Sweep NR.
Nao substitui compilacao MQL5 ou backtest financeiro.
"""
from dataclasses import dataclass

@dataclass(frozen=True)
class Bar:
    open: float
    high: float
    low: float
    close: float

def clamp01(x):
    return min(1., max(0., x))

def atr_previous(bars, i, period=14):
    if i < period + 1:
        return None
    tr = []
    for j in range(i-period, i):
        older = bars[j-1].close
        bar = bars[j]
        tr.append(max(bar.high-bar.low, abs(bar.high-older), abs(bar.low-older)))
    return sum(tr)/period

def scan(bars, lookback=20, atr_period=14, min_sweep=.07,
         min_reclaim=.025, min_wick=.25, min_score=.45, sl_buffer=.08):
    """Returns events after each bar close, as (bar_index, side, score, entry, sl, tp1,tp2,tp3).
    The last list element is ASSUMED closed; caller in live mode must omit forming bar.
    """
    out=[]
    for i in range(max(lookback, atr_period+1), len(bars)):
        older=bars[i-lookback:i]
        upper=max(x.high for x in older)
        lower=min(x.low for x in older)
        atr=atr_previous(bars, i, atr_period)
        if atr is None or atr<=0 or upper<=lower:
            continue
        bar=bars[i]
        candle=max(bar.high-bar.low,1e-9)
        uw=bar.high-max(bar.open,bar.close)
        lw=min(bar.open,bar.close)-bar.low
        eup=bar.high-upper
        edn=lower-bar.low
        rsell=upper-bar.close
        rbuy=bar.close-lower
        sell=(eup>=min_sweep*atr and rsell>=min_reclaim*atr
              and bar.close<bar.open and uw/candle>=min_wick)
        buy=(edn>=min_sweep*atr and rbuy>=min_reclaim*atr
             and bar.close>bar.open and lw/candle>=min_wick)
        if buy==sell:
            continue
        excursion=edn if buy else eup
        reclaim=rbuy if buy else rsell
        wick=lw if buy else uw
        score=(.35*clamp01(excursion/(.65*atr))+
               .35*clamp01((wick/candle)/.60)+
               .30*clamp01(reclaim/(.65*atr)))
        if score<min_score:
            continue
        entry=bar.close
        stop=bar.low-sl_buffer*atr if buy else bar.high+sl_buffer*atr
        risk=entry-stop if buy else stop-entry
        if risk<=0:
            continue
        direction=1 if buy else -1
        out.append((i,"BUY" if buy else "SELL",round(score,8),entry,stop,
                    entry+direction*risk,entry+direction*1.5*risk,
                    entry+direction*2*risk))
    return out
