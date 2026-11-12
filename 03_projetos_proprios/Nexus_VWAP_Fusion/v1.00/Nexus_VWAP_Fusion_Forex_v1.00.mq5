//+------------------------------------------------------------------+
//| NEXUS VWAP FUSION — independent experimental indicator v1.00     |
//| VWAP reclaim + optional EMA trend pullback + structure/RVOL score|
//| CLOSED-bar signals; next-candle OPEN virtual fills only.         |
//| NOT a trading EA. P&L is hypothetical gross points, not USD.     |
//+------------------------------------------------------------------+
#property copyright "Nexus independent research 2026"
#property version "1.00"
#property description "Experimental VWAP Fusion: causal signals; virtual 3-part TP and SL; no trading orders"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots 5
#property indicator_label1 "Fusion BUY (entry on next open)"
#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrLimeGreen
#property indicator_width1 1
#property indicator_label2 "Fusion SELL (entry on next open)"
#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrTomato
#property indicator_width2 1
#property indicator_label3 "Daily VWAP (closed bars)"
#property indicator_type3 DRAW_LINE
#property indicator_color3 clrDodgerBlue
#property indicator_width3 2
#property indicator_label4 "VWAP Upper"
#property indicator_type4 DRAW_LINE
#property indicator_color4 clrSlateGray
#property indicator_style4 STYLE_DOT
#property indicator_label5 "VWAP Lower"
#property indicator_type5 DRAW_LINE
#property indicator_color5 clrSlateGray
#property indicator_style5 STYLE_DOT

enum ENUM_FUSION_SIGNAL_MODE
  {
   FUSION_BOTH=0,              // Reclaim + trend retest
   FUSION_RECLAIM_ONLY=1,      // Confirmed VWAP side change
   FUSION_TREND_RETEST_ONLY=2  // VWAP touch in EMA trend
  };
input ENUM_FUSION_SIGNAL_MODE InpSignalMode=FUSION_BOTH;
input bool InpRealVolumePreferred=false;
input int InpMinSessionBars=5;
input int InpATRPeriod=14;
input int InpRVOLPeriod=20;
input int InpFastEMA=21;
input int InpSlowEMA=55;
input int InpStructureBars=12;
input int InpConfirmCloses=2;
input double InpSideDistanceATR=0.12;
input double InpRetestDistanceATR=0.16;
input double InpMinQuality=0.48;
input int InpCooldownBars=8;
input bool InpOnePerDirection=true;
input double InpBandSigma=1.50;
input double InpStopBufferATR=0.08;
input double InpTP1R=1.00;
input double InpTP2R=1.50;
input double InpTP3R=2.00;
input int InpMaxHoldingBars=48;
input int InpHistoryBars=5000;
input int InpVisibleResultBars=180;
input int InpMaxSpreadPoints=0;  // 0 = disabled; historical spread otherwise used
input bool InpSimulateSpread=true;
input bool InpShowBands=false;
input bool InpShowLastClosedPlan=true;
input bool InpShowOutcomeLabels=true;
input bool InpShowExitTags=false;
input bool InpShowPanel=true;
input double InpArrowOffsetATR=0.80;
input bool InpSoundAlert=true;
input string InpSoundFile="alert.wav";
input bool InpPopupAlert=false;
input bool InpPushNotification=false;

double BuyBuf[],SellBuf[],VWAPBuf[],UpperBuf[],LowerBuf[];
string g_prefix="";
datetime g_seenBar=0,g_alertedEntry=0;

struct FusionTrade
  {
   bool active;
   int dir;
   int entryShift;
   datetime signalTime,entryTime;
   double entry,stop,tp1,tp2,tp3,atr,arrowPrice;
   int nextTP,barsHeld;
   double realized;
  };

double Clamp01(const double v)
  {return MathMax(0.0,MathMin(1.0,v));}

double VolumeAt(const int i,const long &ticks[],const long &real[])
  {
   if(InpRealVolumePreferred && real[i]>0) return (double)real[i];
   return MathMax(1.0,(double)ticks[i]);
  }

// ATR and RVOL are based on CLOSED historical bars older than candle i.
double PreviousATR(const int i,const int n,const double &hi[],
                   const double &lo[],const double &cl[])
  {
   if(i+InpATRPeriod+1>=n) return 0.0;
   double total=0.0;
   for(int j=i+1;j<=i+InpATRPeriod;j++)
     {
      double tr=hi[j]-lo[j];
      tr=MathMax(tr,MathAbs(hi[j]-cl[j+1]));
      tr=MathMax(tr,MathAbs(lo[j]-cl[j+1]));
      total+=tr;
     }
   return total/(double)InpATRPeriod;
  }

double RelativeVolume(const int i,const int n,const long &ticks[],const long &real[])
  {
   if(i+InpRVOLPeriod>=n) return 1.0;
   double total=0.0;
   for(int j=i+1;j<=i+InpRVOLPeriod;j++)
      total+=VolumeAt(j,ticks,real);
   return (total>0.0 ? VolumeAt(i,ticks,real)/(total/InpRVOLPeriod) : 1.0);
  }

// Uses ONLY prior CLOSED candles for structural breakout comparison.
double StructureScore(const int i,const int n,const int dir,
                      const double &hi[],const double &lo[],const double &cl[])
  {
   if(i+InpStructureBars>=n) return 0.4;
   double upper=hi[i+1],lower=lo[i+1];
   for(int j=i+2;j<=i+InpStructureBars;j++)
     {
      upper=MathMax(upper,hi[j]);
      lower=MathMin(lower,lo[j]);
     }
   if(dir==1 && cl[i]>upper) return 1.0;
   if(dir==-1 && cl[i]<lower) return 1.0;
   return 0.4;
  }

int ServerDay(const datetime tm)
  {
   MqlDateTime d;
   TimeToStruct(tm,d);
   return d.year*1000+d.day_of_year;
  }

void PlotText(const string suffix,const datetime at,const double price,
              const string label,const color ink,const int size=8)
  {
   string id=g_prefix+suffix;
   if(!ObjectCreate(0,id,OBJ_TEXT,0,at,price)) return;
   ObjectSetString(0,id,OBJPROP_TEXT,label);
   ObjectSetString(0,id,OBJPROP_FONT,"Tahoma");
   ObjectSetInteger(0,id,OBJPROP_FONTSIZE,size);
   ObjectSetInteger(0,id,OBJPROP_ANCHOR,ANCHOR_CENTER);
   ObjectSetInteger(0,id,OBJPROP_COLOR,ink);
   ObjectSetInteger(0,id,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,id,OBJPROP_HIDDEN,true);
  }

void HUD(const string key,const int y,const string label,const color ink,const int size=9)
  {
   const string id=g_prefix+"HUD_"+key;
   if(!ObjectCreate(0,id,OBJ_LABEL,0,0,0)) return;
   ObjectSetInteger(0,id,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,id,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0,id,OBJPROP_XDISTANCE,15);
   ObjectSetInteger(0,id,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,id,OBJPROP_COLOR,ink);
   ObjectSetInteger(0,id,OBJPROP_FONTSIZE,size);
   ObjectSetString(0,id,OBJPROP_FONT,"Tahoma");
   ObjectSetString(0,id,OBJPROP_TEXT,label);
   ObjectSetInteger(0,id,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,id,OBJPROP_SELECTABLE,false);
  }

void Level(const string key,const datetime from,const datetime to,
           const double price,const color c,const ENUM_LINE_STYLE ls)
  {
   const string id=g_prefix+"LINE_"+key;
   if(!ObjectCreate(0,id,OBJ_TREND,0,from,price,to,price)) return;
   ObjectSetInteger(0,id,OBJPROP_COLOR,c);
   ObjectSetInteger(0,id,OBJPROP_STYLE,ls);
   ObjectSetInteger(0,id,OBJPROP_WIDTH,1);
   ObjectSetInteger(0,id,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(0,id,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,id,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,id,OBJPROP_HIDDEN,true);
  }

void DrawPlan(const FusionTrade &t,const datetime now,const bool lastPlan)
  {
   if(!t.active && !lastPlan) return;
   int seconds=PeriodSeconds(_Period);
   if(seconds<=0) seconds=60;
   const datetime to=now+(datetime)(seconds*4);
   const datetime from=(lastPlan ? now : t.entryTime); // short segment for archived levels
   const color tpInk=(lastPlan ? clrSeaGreen : clrLimeGreen);
   const color slInk=(lastPlan ? clrIndianRed : clrTomato);
   const string lab=(lastPlan ? "ULTIMO " : "");
   Level("EN",from,to,t.entry,clrDodgerBlue,STYLE_DOT);
   Level("SL",from,to,t.stop,slInk,STYLE_DOT);
   Level("T1",from,to,t.tp1,tpInk,STYLE_DASH);
   Level("T2",from,to,t.tp2,tpInk,STYLE_DASH);
   Level("T3",from,to,t.tp3,tpInk,STYLE_DASH);
   PlotText("EN_TX",to,t.entry,lab+"ENTRADA "+DoubleToString(t.entry,_Digits),clrDodgerBlue,8);
   PlotText("SL_TX",to,t.stop,lab+"SL "+DoubleToString(t.stop,_Digits),slInk,8);
   PlotText("T1_TX",to,t.tp1,lab+"TP1 "+DoubleToString(t.tp1,_Digits),tpInk,8);
   PlotText("T2_TX",to,t.tp2,lab+"TP2 "+DoubleToString(t.tp2,_Digits),tpInk,8);
   PlotText("T3_TX",to,t.tp3,lab+"TP3 "+DoubleToString(t.tp3,_Digits),tpInk,8);
  }

void FinishTrade(const FusionTrade &t,const datetime at,const double exitPrice,
                 const double points,const bool timedOut,
                 int &greens,int &reds,int &neutral,double &netPoints,
                 double &grossPositive,double &grossNegative,
                 double &peakBalance,double &maxDrawdown,
                 FusionTrade &lastClosed,bool &haveLast)
  {
   // One completed trade = one GREEN or RED. Each of three parts contributes
   // exactly 1/3 position; points are full-lot-equivalent, NOT a sum of 3 lots.
   const double pt=(double)MathRound(points*10.0)/10.0;
   if(pt>0.0) {greens++;grossPositive+=pt;}
   else if(pt<0.0) {reds++;grossNegative-=pt;}
   else neutral++;
   netPoints+=pt;
   peakBalance=MathMax(peakBalance,netPoints);
   maxDrawdown=MathMax(maxDrawdown,peakBalance-netPoints);
   lastClosed=t;
   lastClosed.active=false;
   haveLast=true;
   if(t.entryShift>InpVisibleResultBars) return;
   if(InpShowOutcomeLabels)
     {
      string mark="0 pts";
      color c=clrSilver;
      if(pt>0.0) {mark="+"+DoubleToString(pt,1)+" pts";c=clrLimeGreen;}
      else if(pt<0.0) {mark="x "+DoubleToString(pt,1)+" pts";c=clrTomato;}
      if(timedOut) mark+=" T";
      const double spacing=InpArrowOffsetATR*t.atr+0.36*t.atr;
      const double py=t.entry-t.dir*spacing;
      PlotText("RESULT_"+IntegerToString((long)t.entryTime),t.entryTime,py,mark,c,7);
     }
   if(InpShowExitTags)
     {
      string endLabel=(timedOut ? "TIME" : (pt>0.0 ? "TP" : "SL"));
      PlotText("EXIT_"+IntegerToString((long)t.entryTime),at,
               exitPrice+t.dir*0.20*t.atr,endLabel,
               (pt>0.0 ? clrLimeGreen : pt<0.0 ? clrTomato : clrSilver),7);
     }
  }

int OnInit()
  {
   if(InpMinSessionBars<2 || InpATRPeriod<2 || InpRVOLPeriod<2 ||
      InpFastEMA<2 || InpSlowEMA<=InpFastEMA || InpStructureBars<2 ||
      InpConfirmCloses<1 || InpConfirmCloses>5 ||
      InpCooldownBars<0 || InpCooldownBars>300 ||
      InpSideDistanceATR<0 || InpRetestDistanceATR<0 ||
      InpMinQuality<0 || InpMinQuality>1.0 || InpBandSigma<=0 ||
      InpStopBufferATR<0 || InpTP1R<=0 ||
      InpTP2R<=InpTP1R || InpTP3R<=InpTP2R ||
      InpMaxHoldingBars<1 || InpMaxHoldingBars>2000 ||
      InpHistoryBars<300 || InpVisibleResultBars<1 ||
      InpMaxSpreadPoints<0 || InpArrowOffsetATR<0.2)
      return INIT_PARAMETERS_INCORRECT;
   SetIndexBuffer(0,BuyBuf,INDICATOR_DATA);
   SetIndexBuffer(1,SellBuf,INDICATOR_DATA);
   SetIndexBuffer(2,VWAPBuf,INDICATOR_DATA);
   SetIndexBuffer(3,UpperBuf,INDICATOR_DATA);
   SetIndexBuffer(4,LowerBuf,INDICATOR_DATA);
   ArraySetAsSeries(BuyBuf,true);
   ArraySetAsSeries(SellBuf,true);
   ArraySetAsSeries(VWAPBuf,true);
   ArraySetAsSeries(UpperBuf,true);
   ArraySetAsSeries(LowerBuf,true);
   PlotIndexSetInteger(0,PLOT_ARROW,233);
   PlotIndexSetInteger(1,PLOT_ARROW,234);
   for(int p=0;p<5;p++) PlotIndexSetDouble(p,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   IndicatorSetString(INDICATOR_SHORTNAME,"NEXUS VWAP FUSION EXPERIMENTAL v1.00");
   g_prefix="NEX_FUSION_"+IntegerToString((long)ChartID())+"_"+
            IntegerToString((long)GetTickCount())+"_";
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0,g_prefix,0,-1);
  }

int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],
                const double &high[],const double &low[],const double &close[],
                const long &tick_volume[],const long &volume[],const int &spread[])
  {
   const int warmup=MathMax(InpSlowEMA,MathMax(InpATRPeriod+2,InpRVOLPeriod+2));
   if(rates_total<warmup+InpMinSessionBars+15) return 0;
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(tick_volume,true);
   ArraySetAsSeries(volume,true);
   ArraySetAsSeries(spread,true);
   const bool initial=(g_seenBar==0 || prev_calculated==0);
   if(!initial && time[0]==g_seenBar) return rates_total;
   const bool newlyOpened=(!initial && time[0]!=g_seenBar);
   g_seenBar=time[0];
   ArrayInitialize(BuyBuf,EMPTY_VALUE);
   ArrayInitialize(SellBuf,EMPTY_VALUE);
   ArrayInitialize(VWAPBuf,EMPTY_VALUE);
   ArrayInitialize(UpperBuf,EMPTY_VALUE);
   ArrayInitialize(LowerBuf,EMPTY_VALUE);
   ObjectsDeleteAll(0,g_prefix,0,-1);

   const int oldest=MathMin(InpHistoryBars,rates_total-InpATRPeriod-2);
   int currentDay=-1,sessionBars=0;
   bool firstPartialSession=true; // oldest analyzed day may be truncated
   double weights=0.0,weightedPrice=0.0,weightedPriceSquared=0.0;
   double previousVWAP=0.0;
   int observedSide=0,pendingSide=0,pendingCloses=0;
   int lastDirection=0,lastEntryShift=100000000;
   bool pendingEntry=false;
   int pendingDirection=0;
   double pendingStop=0.0,pendingATR=0.0;
   datetime pendingSignal=0;
   double emaFast=0.0,emaSlow=0.0;
   const double alphaFast=2.0/(InpFastEMA+1.0);
   const double alphaSlow=2.0/(InpSlowEMA+1.0);
   FusionTrade trade,lastClosed;
   trade.active=false;
   bool haveLast=false;
   int greens=0,reds=0,neutral=0;
   double net=0.0,positive=0.0,negative=0.0,peak=0.0,maxDD=0.0;
   bool alertNow=false;
   int alertDirection=0;

   for(int i=oldest;i>=0;i--)
     {
      // Entry only at next bar's OPEN. Signal candle was fully closed.
      if(pendingEntry)
        {
         pendingEntry=false;
         const double spr=(InpSimulateSpread ? MathMax(0,spread[i])*_Point : 0.0);
         const double fill=(pendingDirection>0 ? open[i]+spr : open[i]);
         const double risk=pendingDirection*(fill-pendingStop);
         if(!trade.active && risk>MathMax(3*_Point,0.15*pendingATR) &&
            risk<=4.0*pendingATR &&
            (InpMaxSpreadPoints==0 || spread[i]<=InpMaxSpreadPoints))
           {
            trade.active=true;
            trade.dir=pendingDirection;
            trade.entryShift=i;
            trade.entryTime=time[i];
            trade.signalTime=pendingSignal;
            trade.entry=NormalizeDouble(fill,_Digits);
            trade.stop=NormalizeDouble(pendingStop,_Digits);
            const double r=pendingDirection*(trade.entry-trade.stop);
            trade.tp1=NormalizeDouble(trade.entry+pendingDirection*InpTP1R*r,_Digits);
            trade.tp2=NormalizeDouble(trade.entry+pendingDirection*InpTP2R*r,_Digits);
            trade.tp3=NormalizeDouble(trade.entry+pendingDirection*InpTP3R*r,_Digits);
            trade.atr=pendingATR;
            trade.nextTP=0;
            trade.barsHeld=0;
            trade.realized=0.0;
            trade.arrowPrice=trade.entry-pendingDirection*InpArrowOffsetATR*pendingATR;
            lastDirection=pendingDirection;
            lastEntryShift=i;
            if(trade.dir>0) BuyBuf[i]=trade.arrowPrice;
            else SellBuf[i]=trade.arrowPrice;
            if(i==0 && newlyOpened && g_alertedEntry!=time[i])
              {
               alertNow=true;
               alertDirection=pendingDirection;
               g_alertedEntry=time[i];
              }
           }
        }
      if(i==0) break; // The current candle cannot produce outcomes or signals.

      // Simulated execution on CLOSED candles. Ask-side exits for SELL.
      if(trade.active)
        {
         trade.barsHeld++;
         const double cost=(InpSimulateSpread ? MathMax(0,spread[i])*_Point : 0.0);
         const double candleHigh=(trade.dir>0 ? high[i] : high[i]+cost);
         const double candleLow=(trade.dir>0 ? low[i] : low[i]+cost);
         const double candleOpen=(trade.dir>0 ? open[i] : open[i]+cost);
         const bool stopHit=(trade.dir>0 ? candleLow<=trade.stop : candleHigh>=trade.stop);
         const bool tp1Hit=(trade.dir>0 ? candleHigh>=trade.tp1 : candleLow<=trade.tp1);
         const bool tp2Hit=(trade.dir>0 ? candleHigh>=trade.tp2 : candleLow<=trade.tp2);
         const bool tp3Hit=(trade.dir>0 ? candleHigh>=trade.tp3 : candleLow<=trade.tp3);
         bool finished=false,timedOut=false;
         double exitPrice=0.0;
         if(stopHit)
           {
            // If stop and TP touch inside one OHLC, assume STOP first.
            // A gap beyond stop uses OPEN as a worse executable fill.
            exitPrice=(trade.dir>0 ? MathMin(candleOpen,trade.stop) :
                                     MathMax(candleOpen,trade.stop));
            const int partsLeft=3-trade.nextTP;
            trade.realized+=(double)partsLeft/3.0*
                            trade.dir*(exitPrice-trade.entry)/_Point;
            finished=true;
           }
         else
           {
            if(trade.nextTP<=0 && tp1Hit)
              {
               trade.realized+=trade.dir*(trade.tp1-trade.entry)/(_Point*3.0);
               trade.nextTP=1;
              }
            if(trade.nextTP<=1 && tp2Hit)
              {
               // If price gaps directly to TP2, TP1 is handled first above.
               trade.realized+=trade.dir*(trade.tp2-trade.entry)/(_Point*3.0);
               trade.nextTP=2;
              }
            if(trade.nextTP<=2 && tp3Hit)
              {
               trade.realized+=trade.dir*(trade.tp3-trade.entry)/(_Point*3.0);
               trade.nextTP=3;
               finished=true;
               exitPrice=trade.tp3;
              }
            if(!finished && trade.barsHeld>=InpMaxHoldingBars)
              {
               exitPrice=(trade.dir>0 ? close[i] : close[i]+cost);
               trade.realized+=(3-trade.nextTP)/3.0*
                               trade.dir*(exitPrice-trade.entry)/_Point;
               timedOut=true;
               finished=true;
              }
           }
         if(finished)
           {
            FinishTrade(trade,time[i],exitPrice,trade.realized,timedOut,
                        greens,reds,neutral,net,positive,negative,
                        peak,maxDD,lastClosed,haveLast);
            trade.active=false;
           }
        }

      // Update EMA only on CLOSED candles; evaluate before/after on this bar.
      if(emaFast==0.0) {emaFast=close[i];emaSlow=close[i];}
      else
        {
         emaFast=alphaFast*close[i]+(1.0-alphaFast)*emaFast;
         emaSlow=alphaSlow*close[i]+(1.0-alphaSlow)*emaSlow;
        }

      const int day=ServerDay(time[i]);
      if(day!=currentDay)
        {
         if(currentDay!=-1) firstPartialSession=false;
         currentDay=day;
         sessionBars=0;
         weights=0.0;weightedPrice=0.0;weightedPriceSquared=0.0;
         previousVWAP=0.0;
         observedSide=0;pendingSide=0;pendingCloses=0;
        }
      const double typical=(high[i]+low[i]+close[i])/3.0;
      const double v=VolumeAt(i,tick_volume,volume);
      weights+=v;
      weightedPrice+=v*typical;
      weightedPriceSquared+=v*typical*typical;
      sessionBars++;
      const double vwap=weightedPrice/weights;
      const double variance=MathMax(0.0,weightedPriceSquared/weights-vwap*vwap);
      const double dev=MathSqrt(variance);
      VWAPBuf[i]=vwap;
      if(InpShowBands)
        {
         UpperBuf[i]=vwap+InpBandSigma*dev;
         LowerBuf[i]=vwap-InpBandSigma*dev;
        }
      const double atr=PreviousATR(i,rates_total,high,low,close);
      // Avoid signals based on a partial VWAP day at the left history edge.
      if(firstPartialSession || atr<=0.0 || sessionBars<InpMinSessionBars)
        {
         previousVWAP=vwap;
         continue;
        }
      int side=0;
      if(close[i]>vwap+InpSideDistanceATR*atr) side=1;
      else if(close[i]<vwap-InpSideDistanceATR*atr) side=-1;

      bool reclaim=false;
      int candidateDir=0;
      if(side==0)
        {
         pendingSide=0;
         pendingCloses=0;
        }
      else if(observedSide==0)
        {
         observedSide=side;
        }
      else
        {
         if(side!=observedSide)
           {
            observedSide=side;
            pendingSide=side;
            pendingCloses=1;
           }
         else if(pendingSide==side)
            pendingCloses++;
         if(pendingSide==side && pendingCloses>=InpConfirmCloses)
           {
            reclaim=true;
            candidateDir=side;
            pendingSide=0;
            pendingCloses=0;
           }
        }

      bool retest=false;
      if(i+1<rates_total && previousVWAP>0.0 && side!=0)
        {
         const bool aligned=(side==1 ? emaFast>emaSlow : emaFast<emaSlow);
         const bool priorSide=(side==1 ? close[i+1]>previousVWAP :
                                         close[i+1]<previousVWAP);
         const bool touched=(side==1 ? low[i+1]<=previousVWAP+InpRetestDistanceATR*atr :
                                       high[i+1]>=previousVWAP-InpRetestDistanceATR*atr);
         const bool candleOK=side*(close[i]-open[i])>0.0;
         retest=(aligned && priorSide && touched && candleOK);
         if(retest && candidateDir==0) candidateDir=side;
        }
      previousVWAP=vwap;
      if(InpSignalMode==FUSION_RECLAIM_ONLY && !reclaim) continue;
      if(InpSignalMode==FUSION_TREND_RETEST_ONLY && !retest) continue;
      if(candidateDir==0 || trade.active || pendingEntry) continue;
      if(InpOnePerDirection && candidateDir==lastDirection) continue;
      if(lastEntryShift-i<InpCooldownBars) continue;
      if(InpMaxSpreadPoints>0 && spread[i]>InpMaxSpreadPoints) continue;

      const double body=candidateDir*(close[i]-open[i]);
      if(body<=0.0) continue;
      const double candleSize=MathMax(_Point,high[i]-low[i]);
      const double rvol=RelativeVolume(i,rates_total,tick_volume,volume);
      const double trendAlignment=(candidateDir*(emaFast-emaSlow)>0.0 ? 1.0 : 0.35);
      const double displacement=candidateDir*(close[i]-vwap);
      const double score=0.30*Clamp01((body/candleSize)/0.65)+
                         0.20*Clamp01(rvol/1.50)+
                         0.20*trendAlignment+
                         0.20*Clamp01(displacement/(0.6*atr))+
                         0.10*StructureScore(i,rates_total,candidateDir,high,low,close);
      if(score<InpMinQuality) continue;
      const double spreadCost=(InpSimulateSpread ? MathMax(0,spread[i])*_Point : 0.0);
      const double sl=(candidateDir>0 ? low[i]-InpStopBufferATR*atr :
                                       high[i]+InpStopBufferATR*atr+spreadCost);
      if(candidateDir*(close[i]-sl)<=2*_Point) continue;
      pendingDirection=candidateDir;
      pendingStop=sl;
      pendingATR=atr;
      pendingSignal=time[i];
      pendingEntry=true;
     }

   if(trade.active) DrawPlan(trade,time[0],false);
   else if(haveLast && InpShowLastClosedPlan) DrawPlan(lastClosed,time[0],true);
   if(InpShowPanel)
     {
      HUD("TITLE",13,"NEXUS VWAP FUSION  /  SIM",clrWhite,9);
      HUD("GREEN",34,"GREEN  "+IntegerToString(greens),clrLimeGreen,9);
      HUD("RED",53,"RED  "+IntegerToString(reds),clrTomato,9);
      const string pt=(net>=0.0 ? "+" : "")+DoubleToString(net,1)+" pts";
      HUD("TOTAL",73,"TOTAL  "+pt,(net>=0.0 ? clrLimeGreen : clrTomato),10);
      const int closed=greens+reds+neutral;
      const double winPct=(closed>0 ? 100.0*greens/closed : 0.0);
      string pf="n/d";
      if(negative>0.0) pf=DoubleToString(positive/negative,2);
      HUD("METRICS",94,"Acerto "+DoubleToString(winPct,1)+"%   PF "+pf,clrSilver,8);
      HUD("DD",111,"DD max "+DoubleToString(maxDD,1)+" pts",clrSilver,8);
      HUD("TRADES",128,"Fechadas "+IntegerToString(closed)+"   Aberta "+(trade.active ? "1":"0"),clrSilver,8);
      HUD("NOTE",146,"Sem comissao/slippage | "+IntegerToString(oldest)+" barras",clrSilver,7);
     }
   if(alertNow)
     {
      if(InpSoundAlert) PlaySound(InpSoundFile);
      const string msg="NEXUS VWAP FUSION "+_Symbol+" "+EnumToString(_Period)+
                       " "+(alertDirection>0 ? "BUY" : "SELL")+" | entrada nova";
      if(InpPopupAlert) Alert(msg);
      if(InpPushNotification) SendNotification(msg);
     }
   ChartRedraw(0);
   return rates_total;
  }
//+------------------------------------------------------------------+
