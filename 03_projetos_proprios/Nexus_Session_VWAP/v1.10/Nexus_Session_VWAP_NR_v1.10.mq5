//+------------------------------------------------------------------+
//| Nexus Session VWAP Reclaim NR v1.10 — direction-state MQL5 indicator  |
//| Closed candles, daily server-time anchor, tick-volume VWAP.       |
//| No future bars; no trading orders.                                |
//+------------------------------------------------------------------+
#property copyright "Independent implementation 2026"
#property version "1.10"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots 5
#property indicator_label1 "VWAP BUY confirmed"
#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrLimeGreen
#property indicator_width1 2
#property indicator_label2 "VWAP SELL confirmed"
#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrTomato
#property indicator_width2 2
#property indicator_label3 "Daily VWAP (closed bars)"
#property indicator_type3 DRAW_LINE
#property indicator_color3 clrDodgerBlue
#property indicator_width3 2
#property indicator_label4 "VWAP upper band"
#property indicator_type4 DRAW_LINE
#property indicator_color4 clrSlateGray
#property indicator_style4 STYLE_DOT
#property indicator_label5 "VWAP lower band"
#property indicator_type5 DRAW_LINE
#property indicator_color5 clrSlateGray
#property indicator_style5 STYLE_DOT

input bool   InpPreferRealVolume = false; // Real volume if provided; otherwise tick volume
input int    InpMinSessionBars   = 5;     // Minimum completed bars since anchor
input int    InpRVOLPeriod      = 20;    // Prior CLOSED bars, not including signal
input double InpMinRVOL         = 0.0;   // 0 disables volume threshold
input int    InpATRPeriod       = 14;
input double InpBandSigma       = 1.50;  // Weighted population stdev multiplier
input double InpMinVectorScore  = 0.42;  // Heuristic only; not probability
input int    InpMaxSpreadPoints = 0;     // 0 disables
input double InpStopBufferATR   = 0.08;
input double InpTP1R            = 1.00;
input double InpTP2R            = 1.50;
input double InpTP3R            = 2.00;
input int    InpMaxHistoryBars  = 4500;
input int    InpDrawPlanBars    = 0;   // 0 = clean chart, no ENTRY/SL/TP lines by default
input bool   InpAlerts          = false;
// Anti-spam: one signal per CONFIRMED change in direction.
input int    InpConfirmCloses    = 2;     // Consecutive CLOSED candles on new VWAP side
input int    InpMinBarsBetweenSignals = 8; // Spacing between any two arrows
input double InpSideDistanceATR  = 0.12;  // Hysteresis: minimum close-to-VWAP distance

double BuyBuffer[],SellBuffer[],VwapBuffer[],UpperBuffer[],LowerBuffer[];
string g_prefix="";
datetime g_seenOpen=0,g_lastClosedProcessed=0,g_alerted=0;

double Clamp01(const double x)
  {
   return MathMax(0.0,MathMin(1.0,x));
  }

double BarWeight(const int j,const long &tick_volume[],const long &volume[])
  {
   if(InpPreferRealVolume && volume[j]>0)
      return (double)volume[j];
   return MathMax(1.0,(double)tick_volume[j]);
  }

// ATR from bars STRICTLY older than index i, including older previous close.
double ATRBefore(const int i,const int total,
                 const double &high[],const double &low[],const double &close[])
  {
   if(i+InpATRPeriod+1>=total) return 0.0;
   double s=0.0;
   for(int j=i+1;j<=i+InpATRPeriod;j++)
     {
      double tr=high[j]-low[j];
      tr=MathMax(tr,MathAbs(high[j]-close[j+1]));
      tr=MathMax(tr,MathAbs(low[j]-close[j+1]));
      s+=tr;
     }
   return s/(double)InpATRPeriod;
  }

double RVOLBefore(const int i,const int total,
                  const long &tick_volume[],const long &volume[])
  {
   if(i+InpRVOLPeriod>=total) return 0.0;
   double s=0.0;
   for(int j=i+1;j<=i+InpRVOLPeriod;j++)
      s+=BarWeight(j,tick_volume,volume);
   if(s<=0.0) return 0.0;
   return BarWeight(i,tick_volume,volume)/(s/InpRVOLPeriod);
  }

void Level(const string name,const datetime from,const datetime to,
           const double value,const color c)
  {
   if(ObjectFind(0,name)>=0) return;
   if(!ObjectCreate(0,name,OBJ_TREND,0,from,value,to,value)) return;
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);
   ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_DOT);
   ObjectSetInteger(0,name,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
  }

void DrawPlan(const datetime closedTime,const int dir,
              const double entry,const double stop,const double score)
  {
   // Entry/SL/TP become visible only at open of NEXT candle.
   const int sec=PeriodSeconds(_Period);
   const datetime from=closedTime+sec,to=from+8*sec;
   const double risk=(double)dir*(entry-stop);
   if(risk<=0.0) return;
   const string id=g_prefix+IntegerToString((long)closedTime)+"_";
   Level(id+"ENTRY",from,to,entry,clrDodgerBlue);
   Level(id+"SL",from,to,stop,clrFireBrick);
   Level(id+"TP1",from,to,entry+dir*InpTP1R*risk,clrLimeGreen);
   Level(id+"TP2",from,to,entry+dir*InpTP2R*risk,clrLimeGreen);
   Level(id+"TP3",from,to,entry+dir*InpTP3R*risk,clrDarkGreen);
   const string label=id+"LABEL";
   if(ObjectFind(0,label)<0 && ObjectCreate(0,label,OBJ_TEXT,0,from,entry))
     {
      ObjectSetString(0,label,OBJPROP_TEXT,
                      (dir==1 ? "VWAP BUY " : "VWAP SELL ")+DoubleToString(score,2));
      ObjectSetInteger(0,label,OBJPROP_COLOR,(dir==1 ? clrLimeGreen : clrTomato));
      ObjectSetInteger(0,label,OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,label,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,label,OBJPROP_SELECTABLE,false);
     }
  }

int OnInit()
  {
   if(InpMinSessionBars<2 || InpRVOLPeriod<2 || InpATRPeriod<2 ||
      InpMinRVOL<0.0 || InpBandSigma<=0.0 ||
      InpMinVectorScore<0.0 || InpMinVectorScore>1.0 ||
      InpStopBufferATR<0.0 || InpMaxSpreadPoints<0 ||
      InpTP1R<=0.0 || InpTP2R<=InpTP1R || InpTP3R<=InpTP2R ||
      InpMaxHistoryBars<100 || InpDrawPlanBars<0 ||
      InpConfirmCloses<1 || InpConfirmCloses>5 ||
      InpMinBarsBetweenSignals<0 || InpMinBarsBetweenSignals>200 ||
      InpSideDistanceATR<0.0 || InpSideDistanceATR>3.0)
      return INIT_PARAMETERS_INCORRECT;
   SetIndexBuffer(0,BuyBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SellBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,VwapBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,UpperBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,LowerBuffer,INDICATOR_DATA);
   ArraySetAsSeries(BuyBuffer,true);
   ArraySetAsSeries(SellBuffer,true);
   ArraySetAsSeries(VwapBuffer,true);
   ArraySetAsSeries(UpperBuffer,true);
   ArraySetAsSeries(LowerBuffer,true);
   PlotIndexSetInteger(0,PLOT_ARROW,233);
   PlotIndexSetInteger(1,PLOT_ARROW,234);
   for(int p=0;p<5;p++)
      PlotIndexSetDouble(p,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   IndicatorSetString(INDICATOR_SHORTNAME,"Nexus Session VWAP Reclaim NR 1.10");
   g_prefix="NVWAP110_"+IntegerToString((long)ChartID())+"_";
   return INIT_SUCCEEDED;
  }
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0,g_prefix,0,-1);
  }

int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],
                const double &high[],const double &low[],
                const double &close[],const long &tick_volume[],
                const long &volume[],const int &spread[])
  {
   const int need=MathMax(InpATRPeriod+2,InpRVOLPeriod+1);
   if(rates_total<need+InpMinSessionBars+10) return 0;
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(tick_volume,true);
   ArraySetAsSeries(volume,true);
   ArraySetAsSeries(spread,true);
   const bool rebuild=(prev_calculated==0 || g_seenOpen==0);
   if(!rebuild && time[0]==g_seenOpen) return rates_total;
   const datetime previouslyClosed=g_lastClosedProcessed;
   g_seenOpen=time[0];
   if(rebuild)
     {
      ArrayInitialize(BuyBuffer,EMPTY_VALUE);
      ArrayInitialize(SellBuffer,EMPTY_VALUE);
      ArrayInitialize(VwapBuffer,EMPTY_VALUE);
      ArrayInitialize(UpperBuffer,EMPTY_VALUE);
      ArrayInitialize(LowerBuffer,EMPTY_VALUE);
      ObjectsDeleteAll(0,g_prefix,0,-1);
     }
   BuyBuffer[0]=EMPTY_VALUE;
   SellBuffer[0]=EMPTY_VALUE;
   VwapBuffer[0]=EMPTY_VALUE;
   UpperBuffer[0]=EMPTY_VALUE;
   LowerBuffer[0]=EMPTY_VALUE;
   const int oldest=MathMin(InpMaxHistoryBars,rates_total-need-1);
   datetime day=0;
   double w=0.0,s=0.0,s2=0.0,priorVWAP=0.0;
   int count=0;
   bool latestBuy=false,latestSell=false;
   // Rebuild an event state from older CLOSED candles on every new bar.
   // This keeps incremental and full-history decisions consistent.
   int observedSide=0;    // Last known side outside the VWAP dead-zone
   int pendingSide=0;     // Side awaiting confirmation
   int pendingCloses=0;
   int activeDirection=0; // Last emitted BUY=+1 or SELL=-1; persists across days
   int lastArrowIndex=100000000;
   for(int i=oldest;i>=1;i--)
     {
      // At candle i close, only candles i and older are in VWAP.
      const datetime d=(datetime)(((long)time[i]/86400)*86400);
      if(d!=day)
        {
         day=d;
         w=0.0;s=0.0;s2=0.0;
         count=0;priorVWAP=0.0;
         // Daily VWAP resets; a new session must establish its own sides.
         observedSide=0;
         pendingSide=0;
         pendingCloses=0;
        }
      const bool hadPrevious=(count>0);
      if(hadPrevious) priorVWAP=s/w;
      const double typ=(high[i]+low[i]+close[i])/3.0;
      const double vol=BarWeight(i,tick_volume,volume);
      w+=vol;s+=typ*vol;s2+=typ*typ*vol;
      count++;
      const double vwap=s/w;
      const double deviation=MathSqrt(MathMax(0.0,s2/w-vwap*vwap));
      const double upper=vwap+InpBandSigma*deviation;
      const double lower=vwap-InpBandSigma*deviation;

      // Recreate state for all closed bars, but NEVER rewrite historical
      // buffers after ordinary new-bar updates. This prevents signal flicker.
      const bool writable=(rebuild || time[i]>previouslyClosed);
      if(writable)
        {
         BuyBuffer[i]=EMPTY_VALUE;
         SellBuffer[i]=EMPTY_VALUE;
         VwapBuffer[i]=vwap;
         UpperBuffer[i]=upper;
         LowerBuffer[i]=lower;
        }

      if(!hadPrevious || count<InpMinSessionBars) continue;
      const double atr=ATRBefore(i,rates_total,high,low,close);
      if(atr<=0.0) continue;

      // A neutral dead-zone prevents many BUY/SELL toggles at the blue line.
      int side=0;
      const double distance=InpSideDistanceATR*atr;
      if(close[i]>vwap+distance) side=1;
      else if(close[i]<vwap-distance) side=-1;

      if(side==0)
        {
         // Do not qualify a move that only touched the line.
         pendingSide=0;
         pendingCloses=0;
         continue;
        }
      if(observedSide==0)
        {
         // First known side is context, NOT a new trade signal.
         observedSide=side;
         continue;
        }
      if(side!=observedSide)
        {
         observedSide=side;
         pendingSide=side;
         pendingCloses=1;
        }
      else if(pendingSide==side)
         pendingCloses++;

      if(pendingSide!=side || pendingCloses<InpConfirmCloses)
         continue;

      // Consume the candidate once; no repeated arrows in the same trend.
      pendingSide=0;
      pendingCloses=0;
      if(side==activeDirection) continue;
      if(lastArrowIndex-i<InpMinBarsBetweenSignals) continue;
      if(InpMaxSpreadPoints>0 && spread[i]>InpMaxSpreadPoints) continue;
      const double rvol=RVOLBefore(i,rates_total,tick_volume,volume);
      if(InpMinRVOL>0.0 && rvol<InpMinRVOL) continue;

      // Third check: body direction and original quality heuristic.
      const int dir=side;
      const double body=dir*(close[i]-open[i]);
      if(body<=0.0) continue;
      const double quality=body/MathMax(_Point,high[i]-low[i]);
      const double displacement=dir*(close[i]-vwap);
      const double score=
         0.40*Clamp01(quality/0.70)+
         0.35*Clamp01(displacement/(0.60*atr))+
         0.25*Clamp01(rvol/1.80);
      if(score<InpMinVectorScore) continue;
      const double stop=(dir==1 ? low[i]-InpStopBufferATR*atr :
                                  high[i]+InpStopBufferATR*atr);
      const double risk=dir*(close[i]-stop);
      if(risk<=2*_Point) continue;

      // Exactly one state transition, one arrow, and one optional plan.
      activeDirection=dir;
      lastArrowIndex=i;
      if(writable)
        {
         const double shift=MathMax(0.15*atr,3*_Point);
         if(dir==1)
           {
            BuyBuffer[i]=low[i]-shift;
            SellBuffer[i]=EMPTY_VALUE;
           }
         else
           {
            SellBuffer[i]=high[i]+shift;
            BuyBuffer[i]=EMPTY_VALUE;
           }
         if(i<=InpDrawPlanBars) DrawPlan(time[i],dir,close[i],stop,score);
         if(i==1 && !rebuild)
           {
            latestBuy=(dir==1);
            latestSell=(dir==-1);
           }
        }
     }
   g_lastClosedProcessed=time[1];
   if(InpAlerts && !rebuild && (latestBuy||latestSell) &&
      g_alerted!=time[1])
     {
      g_alerted=time[1];
      Alert("Nexus VWAP ",_Symbol," ",EnumToString(_Period)," ",
            (latestBuy ? "BUY" : "SELL")," on closed candle");
     }
   return rates_total;
  }
//+------------------------------------------------------------------+
