#!/usr/bin/env python3
"""Exploratory historical backtest on real XAUUSD OHLCV; NOT MetaTrader 5 execution."""
import sys,math,json,hashlib,urllib.request,importlib.util
from pathlib import Path
import pandas as pd
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent/"results";OUT.mkdir(exist_ok=True)
CSV_COMMIT="adcd99e7e0abee51e9a5eef123935e68a8d8aa30"
URL="https://raw.githubusercontent.com/getdata-finance/xauusd-1m-ohlcv-metals-historical-data/"+CSV_COMMIT+"/XAUUSD_1m.csv"
COST_USD_OZ=0.60
MAX_HOLD=12
PERIODS={"M1":1,"M5":5,"M30":30,"H1":60}
MODEL_NAMES={"Liquidity Sweep":("Nexus_Liquidity_Sweep","scan"),"FVG Retest":("Nexus_FVG_Retest","detect"),"Session VWAP":("Nexus_Session_VWAP","calc"),"Structure Break":("Nexus_Structure_Break","detect"),"Clean Signals AUTO":("Nexus_Clean_Signals","detect")}
def download():
    req=urllib.request.Request(URL,headers={"User-Agent":"XAUUSD-Indicator-Research/1.0"})
    with urllib.request.urlopen(req,timeout=120) as f:blob=f.read()
    if len(blob)<1000000 or not blob.startswith(b"datetime,"):raise ValueError("Public OHLCV dataset unavailable")
    p=OUT.parent/"raw_sample_tmp.csv";p.write_bytes(blob)
    df=pd.read_csv(p,parse_dates=["datetime"]);p.unlink()
    df["datetime"]=pd.to_datetime(df["datetime"],utc=True)
    for col in ("open","high","low","close","volume"):df[col]=pd.to_numeric(df[col],errors="raise")
    df=df.sort_values("datetime").drop_duplicates("datetime").set_index("datetime")
    if not ((df.high>=df[["open","close","low"]].max(axis=1))&(df.low<=df[["open","close","high"]].min(axis=1))).all():raise ValueError("invalid OHLC prices")
    return df,hashlib.sha256(blob).hexdigest()
def getbars(df,m):
    if m!=1:
        count=df.close.resample(str(m)+"min").count()
        df=df.resample(str(m)+"min").agg({"open":"first","high":"max","low":"min","close":"last","volume":"sum"})
        df=df[count>=m].dropna()
    return list(df.reset_index()[["datetime","open","high","low","close","volume"]].itertuples(index=False,name=None))
def prior_atr(b,i,n=14):
    if i<n+1:return 0.
    return sum(max(b[j][2]-b[j][3],abs(b[j][2]-b[j-1][4]),abs(b[j][3]-b[j-1][4])) for j in range(i-n,i))/n
def h1_proxy(b):
    """UTC-hour, retest-required original Python proxy of v1.30; NOT compiled MQL5."""
    cap=lambda x:max(0.,min(1.,x))
    hour=None;hi=-1e90;lo=1e90;seen=0;ready=True;status=0;direction=0;break_i=-1;touched=False;score=0.
    events=[]
    for i,row in enumerate(b):
        h=row[0].floor("h")
        if h!=hour:
            hour=h;hi=-1e90;lo=1e90;seen=0;ready=True;status=0;direction=0;break_i=-1;touched=False;score=0.
        minute=row[0].minute
        if minute<3:
            if minute!=seen:ready=False
            hi=max(hi,row[2]);lo=min(lo,row[3]);seen+=1;continue
        if not ready or seen!=3 or hi<=lo or status in (2,3,4):continue
        if status==1 and (i-break_i>12 or minute>48):status=4;continue
        a=prior_atr(b,i);width=hi-lo
        if not a or not .15<=width/a<=4.:continue
        if status==0:
            if minute>48:continue
            direction=1 if row[4]>hi+.08*a else -1 if row[4]<lo-.08*a else 0
            if direction==0:continue
            if (row[4]-hi if direction==1 else lo-row[4])>.9*width:status=4;continue
            edge=hi if direction==1 else lo
            quality=cap((abs(row[4]-row[1])/max(row[2]-row[3],1e-9)-.25)/.65)
            moment=cap(direction*(row[4]-b[i-5][4])/(1.5*a))
            regime=cap((width/a)/.85)*cap(1.85/(width/a))
            score=.30*cap(direction*(row[4]-edge)/(.42*a))+.25*quality+.30*moment+.15*regime
            if score<.53:continue
            status=1;break_i=i;touched=False;continue
        if status==1:
            if (direction==1 and row[4]<hi-.35*width) or (direction==-1 and row[4]>lo+.35*width):status=4;continue
            if (direction==1 and row[2]>hi+.9*width) or (direction==-1 and row[3]<lo-.9*width):status=4;continue
            edge=hi if direction==1 else lo
            if (direction==1 and row[3]<=edge+.15*a) or (direction==-1 and row[2]>=edge-.15*a):touched=True
            ok=touched and ((direction==1 and row[4]>hi+.032*a and row[4]>row[1]) or
                            (direction==-1 and row[4]<lo-.032*a and row[4]<row[1]))
            if not ok:continue
        stop=lo-.08*a if direction==1 else hi+.08*a
        if direction*(row[4]-stop)<=0:status=4;continue
        events.append((i,"BUY" if direction==1 else "SELL",stop))
        status=2 if direction==1 else 3
    return events
def python_signals(name,bars):
    if name=="H1 Vector Factor":return h1_proxy(bars)
    folder,fn=MODEL_NAMES[name]
    path=ROOT/"03_projetos_proprios"/folder/"research"/"reference.py"
    sp=importlib.util.spec_from_file_location("bt_"+folder,path)
    mod=importlib.util.module_from_spec(sp);sys.modules[sp.name]=mod;sp.loader.exec_module(mod)
    if name=="Session VWAP":
        inp=[mod.Bar(int(x[0].value//86400000000000),*x[1:]) for x in bars]
    else:
        inp=[mod.Bar(x[1],x[2],x[3],x[4]) for x in bars]
    raw=getattr(mod,fn)(inp);events=[]
    for event in raw:
        i,side=event[:2]
        if name=="Liquidity Sweep":stop=event[4]
        elif name=="Clean Signals AUTO":stop=event[5]
        else:
            a=prior_atr(bars,i);stop=(bars[i][3]-.08*a) if side=="BUY" else (bars[i][2]+.08*a)
        events.append((i,side,stop))
    return events
def run_trades(bars,events,split):
    deals=[];busy=-1;overlap=0
    for i,side,stop in events:
        if i+1>=len(bars):continue
        if i+1<=busy:overlap+=1;continue
        direction=1 if side=="BUY" else -1;entry=bars[i+1][1];risk=direction*(entry-stop)
        if risk<=.01 or not math.isfinite(risk):continue
        target=entry+direction*risk;last=min(len(bars)-1,i+MAX_HOLD)
        exitprice=bars[last][4];exitindex=last;why="TIME"
        for j in range(i+1,last+1):
            b=bars[j]
            if (direction==1 and b[1]<=stop) or (direction==-1 and b[1]>=stop):
                exitprice=b[1];exitindex=j;why="GAP_STOP";break
            if (b[3]<=stop if direction==1 else b[2]>=stop):
                exitprice=stop;exitindex=j;why="STOP";break
            if (b[2]>=target if direction==1 else b[3]<=target):
                exitprice=target;exitindex=j;why="TP1";break
        deals.append({"i":i,"r":(direction*(exitprice-entry)-COST_USD_OZ)/risk,
                      "test":i>=split,"reason":why})
        busy=exitindex
    return deals,overlap
def metrics(items):
    n=len(items)
    if not n:return {"trades":0,"wins_pct":None,"pf":None,"net_r":None,"avg_r":None,"mdd_r":None}
    rs=[x["r"] for x in items];g=sum(max(0,x) for x in rs);loss=-sum(min(0,x) for x in rs)
    equity=0.;high=0.;dd=0.
    for r in rs:equity+=r;high=max(high,equity);dd=max(dd,high-equity)
    return {"trades":n,"wins_pct":round(100*sum(r>0 for r in rs)/n,2),
            "pf":round(g/loss,3) if loss else None,"net_r":round(sum(rs),2),
            "avg_r":round(sum(rs)/n,4),"mdd_r":round(dd,2)}
def main():
    df,digest=download()
    results={"source":URL,"sha256":digest,"raw_m1":len(df),"first":str(df.index.min()),
             "last":str(df.index.max()),"cost_model":"0.40 USD/oz total spread plus 0.10 USD/oz slippage per side, NO commission",
             "holding_bars":MAX_HOLD,"rows":[]}
    for tf,minutes in PERIODS.items():
        bars=getbars(df,minutes);split=int(len(bars)*.7)
        print("TIMEFRAME",tf,"BARS",len(bars),flush=True)
        for name in ["H1 Vector Factor"]+list(MODEL_NAMES):
            if name=="H1 Vector Factor" and tf!="M1":
                item={"indicator":name,"tf":tf,"status":"NOT SUPPORTED (M1-only)", "signals":None,
                      "whole":metrics([]),"test":metrics([]),"train":metrics([])}
            else:
                events=python_signals(name,bars);trades,overlap=run_trades(bars,events,split)
                item={"indicator":name,"tf":tf,"status":"Python proxy (not MT5 compiled)",
                      "signals":len(events),"overlap_skipped":overlap,
                      "whole":metrics(trades),
                      "train":metrics([x for x in trades if not x["test"]]),
                      "test":metrics([x for x in trades if x["test"]])}
            results["rows"].append(item);print("ROW",json.dumps(item,ensure_ascii=False),flush=True)
    (OUT/"resultados.json").write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding="utf-8")
    head=["Indicador","TF","Sinais","Trades totais","N teste","Acerto % teste","PF teste","R líquido teste","Média R teste","DD teste R"]
    table="| "+" | ".join(head)+" |\n| "+" | ".join(["---"]*len(head))+" |\n"
    def fmt(x):return "—" if x is None else str(x)
    for row in results["rows"]:
        t=row["test"]
        vals=[row["indicator"],row["tf"],fmt(row["signals"]),str(row["whole"]["trades"]),
              str(t["trades"]),fmt(t["wins_pct"]),fmt(t["pf"]),fmt(t["net_r"]),
              fmt(t["avg_r"]),fmt(t["mdd_r"])]
        table+="| "+" | ".join(vals)+" |\n"
    md="# Backtest exploratório XAUUSD — seis indicadores\n\n"
    md+="**Não é o MetaTrader 5 Strategy Tester**. Executados modelos Python de referência e um proxy H1 M1 sobre OHLC histórico. Nenhum código MQL5 compilado foi executado.\n\n"
    md+="Dados públicos: "+URL+"\n\nSHA256: "+digest+"; M1: "+str(len(df))+" barras; intervalo UTC "+str(df.index.min())+" a "+str(df.index.max())+".\n\n"
    md+="Regras: entrada na ABERTURA da vela seguinte, TP1 1R, stop do indicador (quando publicado na referência Python) ou stop além de extremo da vela do sinal com 0,08 ATR; limite 12 candles, uma posição por indicador, colisão intrabar SL primeiro. CUSTOS HIPOTÉTICOS: US$0,40/oz de spread total + US$0,10/oz de slippage por lado (US$0,60/oz por rodada), comissão não incluída. Resultados em R não composto, NÃO representam % da banca. Últimos 30% cronológicos tratados como teste sem otimização.\n\n"
    md+="## Resultado fora da amostra\n\n"+table+"\n"
    md+="Limitações: bid/ask e ticks ausentes, spreads variáveis não observados, fuso UTC em vez do broker, proxy do MQL5, sem execução no MetaEditor. H1 Vector Factor é exclusivamente M1. Dados não comprovam lucro futuro.\n"
    (OUT/"RELATORIO.md").write_text(md,encoding="utf-8")
    print("REPORT\n"+table,flush=True)
if __name__=="__main__":main()
