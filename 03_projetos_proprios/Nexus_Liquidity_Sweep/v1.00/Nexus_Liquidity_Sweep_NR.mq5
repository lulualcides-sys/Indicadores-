//+------------------------------------------------------------------+
//| Nexus Liquidity Sweep Radar NR v1.00 (independent implementation)  |
//| Closed-bar liquidity sweeps of previous-N-bar extremes.           |
//| NOT a copy of a third-party indicator. No trading orders.         |
//+------------------------------------------------------------------+
#property copyright "Independent implementation, 2026"
#property version "1.00"
#property description "Non-repaint confirmed liquidity sweep: previous closed range, rejection wick, vector score, BUY/SELL, R-targets"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots 4
#property indicator_label1 "BUY confirmed"
#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrLimeGreen
#property indicator_width1 2
#property indicator_label2 "SELL confirmed"
#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrTomato
#property indicator_width2 2
#property indicator_label3 "Previous closed range high"
#property indicator_type3 DRAW_LINE
#property indicator_color3 clrRoyalBlue
#property indicator_style3 STYLE_DOT
#property indicator_label4 "Previous closed range low"
#property indicator_type4 DRAW_LINE
#property indicator_color4 clrOrange
#property indicator_style4 STYLE_DOT

input int    InpLookbackBars     = 20;    // Prior CLOSED bars for range (5..300)
input int    InpATRPeriod       = 14;    // ATR built from bars OLDER than signal
input double InpMinSweepATR     = 0.07;  // Wick beyond previous high/low, ATR multiples
input double InpMinReclaimATR   = 0.025; // Close back INSIDE prior range, ATR multiples
input double InpMinWickFraction = 0.25;  // Rejecting wick / total candle range
input double InpMinVectorScore  = 0.45;  // Heuristic score, NOT win probability
input double InpStopBufferATR   = 0.08;  // SL beyond sweeping candle's extreme
input double InpMaxSpreadATR    = 0.00;  // 0 disables cost-to-ATR filter
input int    InpMaxSpreadPoints = 0;     // 0 disables spread-points filter
input double InpTP1R            = 1.00;  // Visual targets; NOT trade execution
input double InpTP2R            = 1.50;
input double InpTP3R            = 2.00;
input int    InpMaxBars         = 3000;  // Historical processing cap
input int    InpDrawPlanBars    = 160;   // Draw latest signal plans only
input bool   InpAlerts          = false; // Alert once for most recent closed candle

double BuyBuffer[], SellBuffer[], UpperBuffer[], LowerBuffer[];
datetime g_seenOpen=0, g_lastClosedProcessed=0, g_alerted=0;
string g_prefix="";

double Clamp01(const double x)
  {
   if(x<=0.0) return 0.0;
   if(x>=1.0) return 1.0;
   return x;
  }

// At signal bar i (i>=1), true-range data start at i+1, i.e. earlier in time.
double PreviousATR(const int i,const int n,
                   const double &high[],const double &low[],
                   const double &close[])
  {
   if(i+InpATRPeriod+1>=n) return 0.0;
   double sum=0.0;
   for(int j=i+1;j<=i+InpATRPeriod;j++)
     {
      double tr=high[j]-low[j];
      tr=MathMax(tr,MathAbs(high[j]-close[j+1]));
      tr=MathMax(tr,MathAbs(low[j]-close[j+1]));
      sum+=tr;
     }
   return sum/(double)InpATRPeriod;
  }

// Range from PREVIOUS closed candles only. No future bars or pivots with
// hidden confirmation delays are consulted.
void PriorRange(const int i,const double &high[],const double &low[],
                double &upper,double &lower)
  {
   upper=-DBL_MAX;
   lower= DBL_MAX;
   for(int j=i+1;j<=i+InpLookbackBars;j++)
     {
      if(high[j]>upper) upper=high[j];
      if(low[j]<lower)  lower=low[j];
     }
  }

void DrawLevel(const string key,const datetime from,const datetime to,
               const double price,const color col,const ENUM_LINE_STYLE style)
  {
   if(ObjectFind(0,key)>=0) return;
   if(!ObjectCreate(0,key,OBJ_TREND,0,from,price,to,price)) return;
   ObjectSetInteger(0,key,OBJPROP_COLOR,col);
   ObjectSetInteger(0,key,OBJPROP_STYLE,style);
   ObjectSetInteger(0,key,OBJPROP_WIDTH,1);
   ObjectSetInteger(0,key,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(0,key,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,key,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,key,OBJPROP_HIDDEN,true);
  }

void DrawPlan(const datetime closedBar,const bool buy,
              const double entry,const double stop,const double score)
  {
   // A candle opens at closedBar and becomes confirmed only at the next bar.
   // Plan drawings therefore start at closedBar+PeriodSeconds, never earlier.
   const int barSeconds=PeriodSeconds(_Period);
   const datetime when=closedBar+barSeconds;
   const datetime until=when+8*barSeconds;
   const string key=g_prefix+IntegerToString((long)closedBar)+"_";
   const double direction=(buy ? 1.0 : -1.0);
   const double risk=direction*(entry-stop);
   if(risk<=0.0) return;
   const color c=(buy ? clrLimeGreen : clrTomato);
   DrawLevel(key+"ENTRY",when,until,entry,clrDodgerBlue,STYLE_SOLID);
   DrawLevel(key+"SL",when,until,stop,clrFireBrick,STYLE_DASH);
   DrawLevel(key+"TP1",when,until,entry+direction*InpTP1R*risk,clrLimeGreen,STYLE_DASH);
   DrawLevel(key+"TP2",when,until,entry+direction*InpTP2R*risk,clrLimeGreen,STYLE_DOT);
   DrawLevel(key+"TP3",when,until,entry+direction*InpTP3R*risk,clrDarkGreen,STYLE_DOT);
   const string title=key+"LABEL";
   if(ObjectFind(0,title)<0 && ObjectCreate(0,title,OBJ_TEXT,0,when,entry))
     {
      ObjectSetString(0,title,OBJPROP_TEXT,
                      (buy ? "BUY " : "SELL ")+DoubleToString(score,2));
      ObjectSetInteger(0,title,OBJPROP_COLOR,c);
      ObjectSetInteger(0,title,OBJPROP_FONTSIZE,9);
      ObjectSetInteger(0,title,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,title,OBJPROP_HIDDEN,true);
     }
  }

int OnInit()
  {
   if(InpLookbackBars<5 || InpLookbackBars>300 || InpATRPeriod<2 ||
      InpMinSweepATR<0.0 || InpMinReclaimATR<0.0 ||
      InpMinWickFraction<0.0 || InpMinWickFraction>1.0 ||
      InpMinVectorScore<0.0 || InpMinVectorScore>1.0 ||
      InpStopBufferATR<0.0 || InpMaxSpreadATR<0.0 ||
      InpMaxSpreadPoints<0 || InpTP1R<=0.0 ||
      InpTP2R<=InpTP1R || InpTP3R<=InpTP2R ||
      InpMaxBars<100 || InpDrawPlanBars<0)
     {
      Print("Nexus Liquidity Sweep NR: invalid parameters");
      return INIT_PARAMETERS_INCORRECT;
     }
   SetIndexBuffer(0,BuyBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SellBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,UpperBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,LowerBuffer,INDICATOR_DATA);
   ArraySetAsSeries(BuyBuffer,true);
   ArraySetAsSeries(SellBuffer,true);
   ArraySetAsSeries(UpperBuffer,true);
   ArraySetAsSeries(LowerBuffer,true);
   PlotIndexSetInteger(0,PLOT_ARROW,233);
   PlotIndexSetInteger(1,PLOT_ARROW,234);
   for(int plot=0;plot<4;plot++)
      PlotIndexSetDouble(plot,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   IndicatorSetString(INDICATOR_SHORTNAME,"Nexus Liquidity Sweep NR v1.00");
   g_prefix="NLS_"+IntegerToString((long)ChartID())+"_";
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
   const int need=MathMax(InpLookbackBars,InpATRPeriod+1);
   if(rates_total<need+3) return 0;
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(spread,true);

   const bool rebuild=(prev_calculated==0 || g_seenOpen==0);
   if(!rebuild && time[0]==g_seenOpen) return rates_total;
   const datetime previousClosed=g_lastClosedProcessed;
   g_seenOpen=time[0];
   if(rebuild)
     {
      ArrayInitialize(BuyBuffer,EMPTY_VALUE);
      ArrayInitialize(SellBuffer,EMPTY_VALUE);
      ArrayInitialize(UpperBuffer,EMPTY_VALUE);
      ArrayInitialize(LowerBuffer,EMPTY_VALUE);
      ObjectsDeleteAll(0,g_prefix,0,-1);
     }
   // Live bar is always blank: no candidate arrows or lines from incomplete OHLC.
   BuyBuffer[0]=EMPTY_VALUE;
   SellBuffer[0]=EMPTY_VALUE;
   UpperBuffer[0]=EMPTY_VALUE;
   LowerBuffer[0]=EMPTY_VALUE;

   const int oldest=MathMin(InpMaxBars,rates_total-need-1);
   bool newestBuy=false,newestSell=false;
   for(int i=oldest;i>=1;i--)
     {
      // Closed historical outputs are write-once during routine new-bar updates.
      if(!rebuild && time[i]<=previousClosed) continue;
      BuyBuffer[i]=EMPTY_VALUE;
      SellBuffer[i]=EMPTY_VALUE;
      UpperBuffer[i]=EMPTY_VALUE;
      LowerBuffer[i]=EMPTY_VALUE;

      double upper=0.0,lower=0.0;
      PriorRange(i,high,low,upper,lower);
      if(upper<=lower) continue;
      UpperBuffer[i]=upper;
      LowerBuffer[i]=lower;
      const double atr=PreviousATR(i,rates_total,high,low,close);
      if(atr<=0.0) continue;
      // Historical bar spread supplied by broker may be a quote approximation.
      if(InpMaxSpreadPoints>0 && spread[i]>InpMaxSpreadPoints) continue;
      if(InpMaxSpreadATR>0.0 && (double)spread[i]*_Point>InpMaxSpreadATR*atr)
         continue;

      const double candle=MathMax(high[i]-low[i],_Point);
      const double upperWick=high[i]-MathMax(open[i],close[i]);
      const double lowerWick=MathMin(open[i],close[i])-low[i];
      const double excursionUp=high[i]-upper;
      const double excursionDown=lower-low[i];
      const double reclaimSell=upper-close[i];
      const double reclaimBuy=close[i]-lower;
      const bool sell=(excursionUp>=InpMinSweepATR*atr &&
                       reclaimSell>=InpMinReclaimATR*atr &&
                       close[i]<open[i] &&
                       upperWick/candle>=InpMinWickFraction);
      const bool buy=(excursionDown>=InpMinSweepATR*atr &&
                      reclaimBuy>=InpMinReclaimATR*atr &&
                      close[i]>open[i] &&
                      lowerWick/candle>=InpMinWickFraction);
      if(buy==sell) continue; // neither or ambiguous both-sided candle
      const double excursion=(buy ? excursionDown : excursionUp);
      const double reclaim=(buy ? reclaimBuy : reclaimSell);
      const double wick=(buy ? lowerWick : upperWick);
      // Heuristic three-factor vector; the result is NOT probability.
      const double score=
         0.35*Clamp01(excursion/(0.65*atr))+
         0.35*Clamp01((wick/candle)/0.60)+
         0.30*Clamp01(reclaim/(0.65*atr));
      if(score<InpMinVectorScore) continue;
      const double entry=close[i]; // signal reference; not executed fill
      const double stop=(buy ? low[i]-InpStopBufferATR*atr :
                               high[i]+InpStopBufferATR*atr);
      const double risk=(buy ? entry-stop : stop-entry);
      if(risk<=2*_Point) continue;
      const double offset=MathMax(0.18*atr,3*_Point);
      if(buy) BuyBuffer[i]=low[i]-offset;
      else    SellBuffer[i]=high[i]+offset;
      if(i<=InpDrawPlanBars)
         DrawPlan(time[i],buy,entry,stop,score);
      if(i==1 && !rebuild)
        {
         newestBuy=buy;
         newestSell=!buy;
        }
     }
   g_lastClosedProcessed=time[1];
   if(InpAlerts && !rebuild && (newestBuy||newestSell) &&
      g_alerted!=time[1])
     {
      g_alerted=time[1];
      Alert("Nexus Sweep ",_Symbol," ",EnumToString(_Period)," ",
            (newestBuy ? "BUY" : "SELL"),
            " confirmed (previous candle closed at ",
            DoubleToString(close[1],_Digits),")");
     }
   return rates_total;
  }
//+------------------------------------------------------------------+
