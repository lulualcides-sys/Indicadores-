//+------------------------------------------------------------------+
//| H1 VECTOR FOREX MTF v1.50 - hourly M1 range, five chart periods   |
//| Original factor weights + breakout/retest, three TP targets.      |
//| Signals confirmed on CLOSED M1, entered at NEXT chart-bar OPEN.    |
//| VIRTUAL ONLY: no trading orders. Forex BID chart/spread estimated.  |
//+------------------------------------------------------------------+
#property copyright "Nexus - independent original indicator (2026)"
#property version   "1.50"
#property description "H1 opening range M1 source, M1/M5/M15/M30/H1 chart, TP1 TP2 TP3, panel, sound"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2
#property indicator_label1 "Confirmed BUY at entry open"
#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrLimeGreen
#property indicator_width1 1
#property indicator_label2 "Confirmed SELL at entry open"
#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrTomato
#property indicator_width2 1

// Hourly engine on M1 bars: preserved rules/weights from Vector Factor v1.30.
input int    InpOpeningBars          = 3;
input int    InpATRPeriod            = 14;
input int    InpMomentumBars         = 5;
input double InpMinBreakATR          = 0.08;
input double InpMinScore             = 0.53;
input double InpMinChannelATR        = 0.15;
input double InpMaxChannelATR        = 4.00;
input double InpMaxExtensionChannel  = 0.90;
input bool   InpRequireRetest        = true;
input double InpRetestToleranceATR   = 0.15;
input int    InpRetestMaxMinutes     = 12;
input int    InpLastEntryMinute      = 48;
input double InpSLBufferATR          = 0.08;
input int    InpMaxSpreadPoints      = 0;   // 0 disables filter
input double InpMaxSpreadATR         = 0.00;
input double InpDirectionalBodyGate  = 0.00;

// Restore the THREE original take-profit levels, with 1/3 size each.
input double InpTP1R                 = 1.00;
input double InpTP2R                 = 1.50;
input double InpTP3R                 = 2.00;
input int    InpMaxHoldingBars       = 45;  // Bars of the selected chart TF
input int    InpHistoryHours         = 96;
input int    InpVisibleOutcomeBars   = 180;
input int    InpMinBarsBetweenArrows = 8;
input double InpArrowDistanceATR     = 0.70;
input bool   InpShowActiveTPs        = true;
input bool   InpShowLastClosedTPs    = true;  // Keep last trade TP1/TP2/TP3 visible
input bool   InpShowPanel            = true;
input bool   InpShowOutcomeLabels    = true;
input bool   InpShowExitTags         = false;
input bool   InpSoundAlert           = true;
input string InpSoundFile            = "alert.wav";
input bool   InpPopupAlert           = false;
input bool   InpPushNotification     = false;

#define W_BREAK   0.30
#define W_BODY    0.25
#define W_TREND   0.30
#define W_REGIME  0.15

double BuyBuffer[],SellBuffer[];
string g_prefix="";
datetime g_lastOpen=0,g_lastBeep=0;

struct M1Signal
  {
   datetime ready; // Earliest allowed time: CLOSE of triggering M1 bar.
   int dir;
   double stop;
   double atr;
  };

struct VirtualTrade
  {
   bool active;
   int dir;
   datetime entryTime;
   int entryIndex;
   double entry,stop,tp1,tp2,tp3,atr,arrowY;
   double realized; // Realized points from THREE equally-sized virtual portions.
   bool done1,done2,done3;
   int barsHeld;
  };

double Clamp01(const double v) {return MathMax(0.0,MathMin(1.0,v));}

double ATRfromM1(const MqlRates &bars[],const int j)
  {
   if(j<InpATRPeriod+1) return 0.0;
   double sum=0.0;
   for(int k=j-1;k>=j-InpATRPeriod;k--)
     {
      double tr=bars[k].high-bars[k].low;
      tr=MathMax(tr,MathAbs(bars[k].high-bars[k-1].close));
      tr=MathMax(tr,MathAbs(bars[k].low-bars[k-1].close));
      sum+=tr;
     }
   return sum/(double)InpATRPeriod;
  }

double M1FactorScore(const MqlRates &bars[],const int j,const int dir,
                     const double boundary,const double width,const double atr)
  {
   if(atr<=0.0 || width<=0.0 || j<InpMomentumBars) return 0.0;
   const double beyond=(dir==1 ? bars[j].close-boundary : boundary-bars[j].close);
   const double fb=Clamp01(beyond/(0.42*atr));
   const double candle=MathMax(bars[j].high-bars[j].low,_Point);
   const double body=MathAbs(bars[j].close-bars[j].open)/candle;
   const double fbody=Clamp01((body-0.25)/0.65);
   const double momentum=(double)dir*(bars[j].close-bars[j-InpMomentumBars].close);
   const double fm=Clamp01(momentum/(1.5*atr));
   const double ratio=width/atr;
   const double fregime=Clamp01(ratio/0.85)*Clamp01(1.85/ratio);
   return W_BREAK*fb+W_BODY*fbody+W_TREND*fm+W_REGIME*fregime;
  }

void AddM1Signal(M1Signal &events[],const datetime ready,const int dir,
                 const double stop,const double atr)
  {
   const int n=ArraySize(events);
   ArrayResize(events,n+1,128);
   events[n].ready=ready;
   events[n].dir=dir;
   events[n].stop=NormalizeDouble(stop,_Digits);
   events[n].atr=atr;
  }

// The same three fully CLOSED M1 candles determine the H1 opening range on
// every host period. Each emitted event has a first-known timestamp.
int BuildM1Signals(M1Signal &events[],const datetime oldestChartTime,
                   const datetime currentChartOpen)
  {
   ArrayResize(events,0);
   MqlRates bars[];
   ArraySetAsSeries(bars,false); // CopyRates stores oldest bar first in memory.
   const datetime from=oldestChartTime-7200;
   const datetime until=currentChartOpen-60; // Exclude the OPEN M1 bar.
   if(until<=from) return -1;
   const int total=CopyRates(_Symbol,PERIOD_M1,from,until,bars);
   if(total<InpATRPeriod+InpOpeningBars+10) return -1;
   ArraySetAsSeries(bars,false);

   datetime hour=0,brokeAt=0;
   double upper=-1.e100,lower=1.e100;
   int collected=0,phase=0,dir=0;
   bool openingValid=true,touched=false;
   for(int j=0;j<total;j++)
     {
      const datetime stamp=bars[j].time;
      if(stamp+60>currentChartOpen) break; // STRICT confirmed M1 only.
      const datetime h=(datetime)(((long)stamp/3600)*3600);
      if(h!=hour)
        {
         hour=h;upper=-1.e100;lower=1.e100;collected=0;
         phase=0;dir=0;touched=false;openingValid=true;brokeAt=0;
        }
      const int minute=(int)((stamp-h)/60);
      if(minute<InpOpeningBars)
        {
         // A missing first-minute bar INVALIDATES this hourly opening range.
         if(minute!=collected) openingValid=false;
         upper=MathMax(upper,bars[j].high);
         lower=MathMin(lower,bars[j].low);
         collected++;
         continue;
        }
      if(!openingValid || collected!=InpOpeningBars || upper<=lower) continue;
      if(phase==2 || phase==3 || phase==4) continue;
      if(phase==1 && ((int)((stamp-brokeAt)/60)>InpRetestMaxMinutes ||
                      minute>InpLastEntryMinute))
        {phase=4;continue;}
      const double atr=ATRfromM1(bars,j);
      if(atr<=0.0) continue;
      const double width=upper-lower;
      if(width/atr<InpMinChannelATR || width/atr>InpMaxChannelATR) continue;
      if(InpMaxSpreadPoints>0 && bars[j].spread>InpMaxSpreadPoints) continue;
      if(InpMaxSpreadATR>0.0 && (double)bars[j].spread*_Point>InpMaxSpreadATR*atr) continue;

      if(phase==0)
        {
         if(minute>InpLastEntryMinute) continue;
         int d=0;
         if(bars[j].close>upper+InpMinBreakATR*atr) d=1;
         else if(bars[j].close<lower-InpMinBreakATR*atr) d=-1;
         if(d==0) continue;
         if(InpDirectionalBodyGate>0.0)
           {
            const double body=(double)d*(bars[j].close-bars[j].open)/
                             MathMax(_Point,bars[j].high-bars[j].low);
            if(body<InpDirectionalBodyGate) continue;
           }
         const double extension=(d==1 ? bars[j].close-upper : lower-bars[j].close);
         if(extension>InpMaxExtensionChannel*width) {phase=4;continue;}
         const double score=M1FactorScore(bars,j,d,(d==1?upper:lower),width,atr);
         if(score<InpMinScore) continue;
         dir=d;brokeAt=stamp;
         if(!InpRequireRetest)
           {
            phase=(d==1?2:3);
            const double sl=(d==1 ? lower-InpSLBufferATR*atr : upper+InpSLBufferATR*atr);
            AddM1Signal(events,stamp+60,d,sl,atr);
           }
         else {phase=1;touched=false;}
         continue;
        }
      if(phase==1)
        {
         if((int)((stamp-brokeAt)/60)>InpRetestMaxMinutes || minute>InpLastEntryMinute)
           {phase=4;continue;}
         if((dir==1 && bars[j].close<upper-0.35*width) ||
            (dir==-1 && bars[j].close>lower+0.35*width)) {phase=4;continue;}
         if((dir==1 && bars[j].high>upper+InpMaxExtensionChannel*width) ||
            (dir==-1 && bars[j].low<lower-InpMaxExtensionChannel*width))
           {phase=4;continue;}
         const double boundary=(dir==1 ? upper : lower);
         if((dir==1 && bars[j].low<=boundary+InpRetestToleranceATR*atr) ||
            (dir==-1 && bars[j].high>=boundary-InpRetestToleranceATR*atr)) touched=true;
         const bool confirmed=touched &&
            ((dir==1 && bars[j].close>upper+0.40*InpMinBreakATR*atr &&
              bars[j].close>bars[j].open) ||
             (dir==-1 && bars[j].close<lower-0.40*InpMinBreakATR*atr &&
              bars[j].close<bars[j].open));
         if(!confirmed) continue;
         phase=(dir==1?2:3);
         const double sl=(dir==1 ? lower-InpSLBufferATR*atr : upper+InpSLBufferATR*atr);
         AddM1Signal(events,stamp+60,dir,sl,atr);
        }
     }
   return ArraySize(events);
  }

void OnChartText(const string id,const datetime when,const double price,
                 const string label,const color c,const int fontSize=8)
  {
   if(!ObjectCreate(0,id,OBJ_TEXT,0,when,price)) return;
   ObjectSetString(0,id,OBJPROP_TEXT,label);
   ObjectSetString(0,id,OBJPROP_FONT,"Tahoma");
   ObjectSetInteger(0,id,OBJPROP_FONTSIZE,fontSize);
   ObjectSetInteger(0,id,OBJPROP_COLOR,c);
   ObjectSetInteger(0,id,OBJPROP_ANCHOR,ANCHOR_CENTER);
   ObjectSetInteger(0,id,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,id,OBJPROP_SELECTABLE,false);
  }

void HUD(const string key,const int y,const string label,const color c,const int size=9)
  {
   const string name=g_prefix+"HUD_"+key;
   if(!ObjectCreate(0,name,OBJ_LABEL,0,0,0)) return;
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,16);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
   ObjectSetString(0,name,OBJPROP_FONT,"Tahoma");
   ObjectSetString(0,name,OBJPROP_TEXT,label);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
  }

void ChartLevel(const string key,const datetime from,const datetime to,
                const double price,const color c,const ENUM_LINE_STYLE style)
  {
   if(!ObjectCreate(0,g_prefix+"L_"+key,OBJ_TREND,0,from,price,to,price)) return;
   const string name=g_prefix+"L_"+key;
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);
   ObjectSetInteger(0,name,OBJPROP_STYLE,style);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
   ObjectSetInteger(0,name,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
  }

void ActiveLevels(const VirtualTrade &t,const datetime now)
  {
   if(!t.active || !InpShowActiveTPs) return;
   const int seconds=PeriodSeconds(_Period);
   const datetime end=now+(datetime)(5*seconds);
   ChartLevel("ENTRY",t.entryTime,end,t.entry,clrDodgerBlue,STYLE_DOT);
   ChartLevel("STOP",t.entryTime,end,t.stop,clrTomato,STYLE_DASH);
   ChartLevel("TP1",t.entryTime,end,t.tp1,(t.done1?clrGray:clrLimeGreen),STYLE_DASH);
   ChartLevel("TP2",t.entryTime,end,t.tp2,(t.done2?clrGray:clrLimeGreen),STYLE_DASH);
   ChartLevel("TP3",t.entryTime,end,t.tp3,(t.done3?clrGray:clrGreen),STYLE_DASH);
   OnChartText(g_prefix+"T_ENTRY",end,t.entry,"ENT "+DoubleToString(t.entry,_Digits),clrDodgerBlue,8);
   OnChartText(g_prefix+"T_STOP",end,t.stop,"SL "+DoubleToString(t.stop,_Digits),clrTomato,8);
   OnChartText(g_prefix+"T_TP1",end,t.tp1,"TP1 "+DoubleToString(t.tp1,_Digits),clrLimeGreen,8);
   OnChartText(g_prefix+"T_TP2",end,t.tp2,"TP2 "+DoubleToString(t.tp2,_Digits),clrLimeGreen,8);
   OnChartText(g_prefix+"T_TP3",end,t.tp3,"TP3 "+DoubleToString(t.tp3,_Digits),clrGreen,8);
  }

void LastClosedLevels(const VirtualTrade &t,const datetime exitTime)
  {
   if(!InpShowLastClosedTPs) return;
   const int seconds=PeriodSeconds(_Period);
   const datetime end=(exitTime>t.entryTime ? exitTime : t.entryTime+(datetime)seconds);
   ChartLevel("LAST_ENTRY",t.entryTime,end,t.entry,clrSlateGray,STYLE_DOT);
   ChartLevel("LAST_STOP",t.entryTime,end,t.stop,clrFireBrick,STYLE_DOT);
   ChartLevel("LAST_TP1",t.entryTime,end,t.tp1,clrSeaGreen,STYLE_DOT);
   ChartLevel("LAST_TP2",t.entryTime,end,t.tp2,clrSeaGreen,STYLE_DOT);
   ChartLevel("LAST_TP3",t.entryTime,end,t.tp3,clrGreen,STYLE_DOT);
   OnChartText(g_prefix+"LAST_TP1_TEXT",end,t.tp1,"TP1",clrSeaGreen,7);
   OnChartText(g_prefix+"LAST_TP2_TEXT",end,t.tp2,"TP2",clrSeaGreen,7);
   OnChartText(g_prefix+"LAST_TP3_TEXT",end,t.tp3,"TP3",clrGreen,7);
  }

void CloseTrade(const VirtualTrade &t,const datetime when,const double points,
                const string reason,int &green,int &red,int &neutral,double &net)
  {
   net+=points;
   if(points>0.5) green++;
   else if(points<-0.5) red++;
   else neutral++;
   if(!InpShowOutcomeLabels || t.entryIndex>InpVisibleOutcomeBars) return;
   const int rounded=(int)MathRound(points);
   string result="0 pts";
   color ink=clrSilver;
   if(rounded>0) {result="+"+IntegerToString(rounded)+" pts";ink=clrLimeGreen;}
   else if(rounded<0) {result="x "+IntegerToString(rounded)+" pts";ink=clrTomato;}
   // Keep labels outside candles: BUY below; SELL above its small arrow.
   const double dy=MathMax(0.38*t.atr,8*_Point);
   const double y=(t.dir==1 ? t.arrowY-dy : t.arrowY+dy);
   OnChartText(g_prefix+"RES_"+IntegerToString((long)t.entryTime),
               t.entryTime,y,result,ink,8);
   if(InpShowExitTags)
      OnChartText(g_prefix+"EXIT_"+IntegerToString((long)t.entryTime),when,
                  t.entry,reason,ink,8);
  }

int OnInit()
  {
   if(_Period!=PERIOD_M1 && _Period!=PERIOD_M5 && _Period!=PERIOD_M15 &&
      _Period!=PERIOD_M30 && _Period!=PERIOD_H1)
     {
      Print("H1 Vector: grafico aceito M1/M5/M15/M30/H1. Fonte de dados M1 obrigatoria.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(InpOpeningBars<1 || InpOpeningBars>10 || InpATRPeriod<2 || InpMomentumBars<1 ||
      InpRetestMaxMinutes<1 || InpLastEntryMinute<=InpOpeningBars ||
      InpLastEntryMinute>59 || InpHistoryHours<12 || InpHistoryHours>336 ||
      InpMinScore<0.0 || InpMinScore>1.0 ||
      InpMinChannelATR<=0.0 || InpMaxChannelATR<=InpMinChannelATR ||
      InpMaxExtensionChannel<=0.0 || InpMinBreakATR<0.0 ||
      InpRetestToleranceATR<0.0 || InpSLBufferATR<0.0 ||
      InpMaxSpreadPoints<0 || InpMaxSpreadATR<0.0 ||
      InpDirectionalBodyGate<0.0 || InpDirectionalBodyGate>1.0 ||
      InpTP1R<=0.0 || InpTP2R<=InpTP1R || InpTP3R<=InpTP2R ||
      InpMaxHoldingBars<1 || InpMaxHoldingBars>1000 ||
      InpMinBarsBetweenArrows<0 || InpMinBarsBetweenArrows>500 ||
      InpVisibleOutcomeBars<0 || InpArrowDistanceATR<0.25) return INIT_PARAMETERS_INCORRECT;

   SetIndexBuffer(0,BuyBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SellBuffer,INDICATOR_DATA);
   ArraySetAsSeries(BuyBuffer,true);ArraySetAsSeries(SellBuffer,true);
   PlotIndexSetInteger(0,PLOT_ARROW,233);
   PlotIndexSetInteger(1,PLOT_ARROW,234);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   IndicatorSetString(INDICATOR_SHORTNAME,"H1 Vector Forex MTF v1.50 | TP1/TP2/TP3");
   g_prefix="H1VF150_"+IntegerToString((long)ChartID())+"_"+
            IntegerToString((long)GetTickCount())+"_";
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {ObjectsDeleteAll(0,g_prefix,0,-1);}

int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],
                const double &high[],const double &low[],
                const double &close[],const long &tick_volume[],
                const long &volume[],const int &spread[])
  {
   if(rates_total<5) return 0;
   ArraySetAsSeries(time,true);ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);ArraySetAsSeries(spread,true);
   const bool freshStart=(g_lastOpen==0 || prev_calculated==0);
   if(!freshStart && time[0]==g_lastOpen) return rates_total;

   const datetime windowStart=time[0]-(datetime)(InpHistoryHours*3600);
   int oldest=1;
   while(oldest<rates_total-2 && time[oldest]>=windowStart) oldest++;
   if(oldest>=rates_total-2) oldest=rates_total-3;
   if(oldest<2) return 0;
   M1Signal signals[];
   const int count=BuildM1Signals(signals,time[oldest],time[0]);
   if(count<0)
     {
      // M1 history is an explicit prerequisite. Avoid guessing opening range
      // from larger bars and silently changing the actual strategy.
      if(InpShowPanel)
         HUD("WAIT",16,"H1 VECTOR: aguardando historico M1",clrTomato,9);
      return prev_calculated;
     }
   g_lastOpen=time[0];
   ArrayInitialize(BuyBuffer,EMPTY_VALUE);
   ArrayInitialize(SellBuffer,EMPTY_VALUE);
   ObjectsDeleteAll(0,g_prefix,0,-1);

   int nextSignal=0;
   VirtualTrade t;t.active=false;
   VirtualTrade lastCompleted;lastCompleted.active=false;
   datetime lastExit=0;
   bool hasLastCompleted=false;
   int lastDir=0,lastEntryIndex=100000000;
   int greens=0,reds=0,neutrals=0;
   double netPoints=0.0;
   int soundDir=0;
   const int seconds=PeriodSeconds(_Period);

   // Process host chart candles chronologically; a M1 event is actionable
   // ONLY when its ready time is <= host candle's open timestamp.
   for(int i=oldest;i>=0;i--)
     {
      const datetime tOpen=time[i];
      const datetime priorOpen=(i+1<rates_total ? time[i+1] : tOpen);
      // Decide this chart candle's entry from M1 signals already CONFIRMED.
      int event=-1;
      while(nextSignal<count && signals[nextSignal].ready<=tOpen)
        {
         if(signals[nextSignal].ready>priorOpen && event<0) event=nextSignal;
         nextSignal++;
        }
      if(event>=0 && !t.active && signals[event].dir!=lastDir &&
         lastEntryIndex-i>=InpMinBarsBetweenArrows)
        {
         const M1Signal e=signals[event];
         const double sp=(double)MathMax(0,spread[i])*_Point;
         const double entry=(e.dir==1 ? open[i]+sp : open[i]);
         const double risk=e.dir*(entry-e.stop);
         // Delayed chart-timeframe entries can invalidate the previous M1 SL.
         if(risk>MathMax(4*_Point,0.10*e.atr))
           {
            t.active=true;t.dir=e.dir;t.entryTime=tOpen;t.entryIndex=i;
            t.entry=entry;t.stop=e.stop;t.atr=e.atr;t.barsHeld=0;
            t.tp1=NormalizeDouble(entry+e.dir*InpTP1R*risk,_Digits);
            t.tp2=NormalizeDouble(entry+e.dir*InpTP2R*risk,_Digits);
            t.tp3=NormalizeDouble(entry+e.dir*InpTP3R*risk,_Digits);
            t.done1=false;t.done2=false;t.done3=false;t.realized=0.0;
            const double pad=MathMax(InpArrowDistanceATR*e.atr,7*_Point);
            t.arrowY=(e.dir==1 ? open[i]-pad : open[i]+pad);
            if(e.dir==1) BuyBuffer[i]=t.arrowY;
            else SellBuffer[i]=t.arrowY;
            lastDir=e.dir;lastEntryIndex=i;
            if(i==0 && !freshStart && g_lastBeep!=tOpen)
              {g_lastBeep=tOpen;soundDir=e.dir;}
           }
        }
      if(i==0) break; // Current host candle is OPEN, not closed.

      if(t.active)
        {
         t.barsHeld++;
         const double sp=(double)MathMax(0,spread[i])*_Point;
         const double h=(t.dir==1 ? high[i] : high[i]+sp);
         const double l=(t.dir==1 ? low[i] : low[i]+sp);
         const double o=(t.dir==1 ? open[i] : open[i]+sp);
         const double c=(t.dir==1 ? close[i] : close[i]+sp);
         const bool hitStop=(t.dir==1 ? l<=t.stop : h>=t.stop);
         bool finished=false;
         string reason="";
         // Conservative OHLC ambiguity: STOP wins over any same-bar targets.
         if(hitStop)
           {
            const double exitPx=(t.dir==1 ? MathMin(o,t.stop) : MathMax(o,t.stop));
            const int units=(t.done1?0:1)+(t.done2?0:1)+(t.done3?0:1);
            t.realized+=((double)units/3.0)*t.dir*(exitPx-t.entry)/_Point;
            finished=true;reason="SL";
           }
         else
           {
            if(!t.done1 && (t.dir==1 ? h>=t.tp1 : l<=t.tp1))
              {t.done1=true;t.realized+=(t.dir*(t.tp1-t.entry)/_Point)/3.0;}
            if(!t.done2 && (t.dir==1 ? h>=t.tp2 : l<=t.tp2))
              {t.done2=true;t.realized+=(t.dir*(t.tp2-t.entry)/_Point)/3.0;}
            if(!t.done3 && (t.dir==1 ? h>=t.tp3 : l<=t.tp3))
              {t.done3=true;t.realized+=(t.dir*(t.tp3-t.entry)/_Point)/3.0;}
            if(t.done1 && t.done2 && t.done3)
              {finished=true;reason="TP3";}
            else if(t.barsHeld>=InpMaxHoldingBars)
              {
               const int units=(t.done1?0:1)+(t.done2?0:1)+(t.done3?0:1);
               t.realized+=((double)units/3.0)*t.dir*(c-t.entry)/_Point;
               finished=true;reason="TIME";
              }
           }
         if(finished)
           {
            CloseTrade(t,time[i],t.realized,reason,greens,reds,neutrals,netPoints);
            lastCompleted=t;lastExit=time[i];hasLastCompleted=true;
            t.active=false;
           }
        }
     }
   ActiveLevels(t,time[0]);
   if(!t.active && hasLastCompleted)
      LastClosedLevels(lastCompleted,lastExit);
   if(InpShowPanel)
     {
      HUD("TITLE",15,"H1 VECTOR | FOREX "+EnumToString(_Period),clrWhite,9);
      HUD("GREEN",37,"GREEN: "+IntegerToString(greens),clrLimeGreen,9);
      HUD("RED",56,"RED: "+IntegerToString(reds),clrTomato,9);
      const int net=(int)MathRound(netPoints);
      HUD("TOTAL",78,"TOTAL: "+(net>=0?"+":"")+IntegerToString(net)+" pts",
          (net>=0?clrLimeGreen:clrTomato),10);
      const double pipFactor=(_Digits==3 || _Digits==5 ? 10.0 : 1.0);
      HUD("PIPS",98,"~ "+DoubleToString(netPoints/pipFactor,1)+" pips",
          clrSilver,8);
      HUD("OPS",116,"Fechadas: "+IntegerToString(greens+reds+neutrals)+
          " | Aberta: "+(t.active?"1":"0"),clrSilver,8);
      HUD("NOTE",134,"Simulado | 3 partes / TP1 TP2 TP3 | "+
          IntegerToString(InpHistoryHours)+"h",clrSilver,7);
     }
   if(soundDir!=0)
     {
      if(InpSoundAlert) PlaySound(InpSoundFile);
      const string msg="H1 VECTOR FOREX "+_Symbol+" "+EnumToString(_Period)+
                        (soundDir==1?" BUY":" SELL")+" confirmado / entrada abertura";
      if(InpPopupAlert) Alert(msg);
      if(InpPushNotification) SendNotification(msg);
     }
   ChartRedraw(0);
   return rates_total;
  }
//+------------------------------------------------------------------+
