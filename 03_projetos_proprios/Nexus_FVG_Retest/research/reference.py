from dataclasses import dataclass

@dataclass(frozen=True)
class Bar:
    open:float
    high:float
    low:float
    close:float

def atr_older(bars,i,period=14):
    if i<period+1: return 0
    acc=0.0
    for j in range(i-period,i):
        b=bars[j]
        prev=bars[j-1].close
        acc+=max(b.high-b.low,abs(b.high-prev),abs(b.low-prev))
    return acc/period

def detect(bars,period=14,age=30,gapmin=.12,touch=.06,
           reclaim=.02,maxpierce=.30):
    """Only completed bars accepted; caller omits forming candle."""
    events=[]
    for i in range(age+period+4,len(bars)):
        current=bars[i]
        atr=atr_older(bars,i,period)
        if atr<=0: continue
        for j in range(i-1,max(-1,i-age-1),-1):
            if j<period+1 or j-2<0: continue
            third=bars[j]
            first=bars[j-2]
            atrgap=atr_older(bars,j,period)
            if atrgap<=0: continue
            bull=third.low-first.high
            bear=first.low-third.high
            direction=0
            if bull>=gapmin*atrgap and bull>0:
                near=third.low
                far=first.high
                fresh=all(b.low>near for b in bars[j+1:i])
                if (fresh and current.low<=near+touch*atr and
                    current.high>=far and current.low>=far-maxpierce*atr and
                    current.close>=near+reclaim*atr and
                    current.close>current.open):
                    direction=1
            if not direction and bear>=gapmin*atrgap and bear>0:
                near=third.high
                far=first.low
                fresh=all(b.high<near for b in bars[j+1:i])
                if (fresh and current.high>=near-touch*atr and
                    current.low<=far and current.high<=far+maxpierce*atr and
                    current.close<=near-reclaim*atr and
                    current.close<current.open):
                    direction=-1
            if direction:
                events.append((i,"BUY" if direction==1 else "SELL",j,near,far))
                break
    return events
