//+------------------------------------------------------------------+
//| Nexus EMA Trend Pullback NR v1.00                                  |
//| 2 EMAs + confirmed fast-EMA retest + closed-bar continuation.      |
//| Independent source, arrows only after close, no trading orders.   |
//+------------------------------------------------------------------+
#property copyright "Independent implementation 2026"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2
#property indicator_label1 "TREND PULLBACK BUY"
#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrLimeGreen
#property indicator_width1 2
#property indicator_label2 "TREND PULLBACK SELL"
#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrTomato
#property indicator_width2 2

input int InpFastEMA=20;
input int InpSlowEMA=50;
input int InpATRPeriod=14;
input double InpTouchToleranceATR=0.10;
input double InpMaxTouchDistanceATR=0.50;
input double InpResumeDistanceATR=0.05;
input double InpMinBodyFraction=0.20;
input int InpCooldownBars=2;
input int InpMaxSpreadPoints=0;
input int InpMaxHistoryBars=5000;
input bool InpAlerts=false;

double BuyBuffer[],SellBuffer[];
datetime g_open=0,g_lastClosed=0,g_alerted=0;

double ATRBefore(const int i,const int total,const double &hi[],
                 const double &lo[],const double &cl[])
  {
   if(i+InpATRPeriod+1>=total) return 0.0;
   double sum=0.0;
   for(int j=i+1;j<=i+InpATRPeriod;j++)
     {
      double tr=hi[j]-lo[j];
      tr=MathMax(tr,MathAbs(hi[j]-cl[j+1]));
      tr=MathMax(tr,MathAbs(lo[j]-cl[j+1]));
      sum+=tr;
     }
   return sum/InpATRPeriod;
  }

int OnInit()
  {
   if(InpFastEMA<2 || InpSlowEMA<=InpFastEMA ||
      InpSlowEMA>400 || InpATRPeriod<2 ||
      InpTouchToleranceATR<0.0 || InpMaxTouchDistanceATR<=0.0 ||
      InpResumeDistanceATR<0.0 ||
      InpMinBodyFraction<0.0 || InpMinBodyFraction>1.0 ||
      InpCooldownBars<0 || InpCooldownBars>50 ||
      InpMaxSpreadPoints<0 || InpMaxHistoryBars<200)
      return INIT_PARAMETERS_INCORRECT;
   SetIndexBuffer(0,BuyBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SellBuffer,INDICATOR_DATA);
   ArraySetAsSeries(BuyBuffer,true);
   ArraySetAsSeries(SellBuffer,true);
   PlotIndexSetInteger(0,PLOT_ARROW,233);
   PlotIndexSetInteger(1,PLOT_ARROW,234);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   IndicatorSetString(INDICATOR_SHORTNAME,"Nexus EMA Trend Pullback NR v1.00");
   return INIT_SUCCEEDED;
  }

int OnCalculate(const int total,const int prevCalculated,const datetime &time[],
                const double &open[],const double &high[],const double &low[],
                const double &close[],const long &tickVolume[],
                const long &realVolume[],const int &spread[])
  {
   const int needed=MathMax(InpSlowEMA+10,InpATRPeriod+2);
   if(total<needed+3) return 0;
   ArraySetAsSeries(time,true);ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);ArraySetAsSeries(spread,true);
   const bool rebuild=(prevCalculated==0 || g_open==0);
   if(!rebuild && time[0]==g_open) return total;
   const datetime previousClosed=g_lastClosed;
   g_open=time[0];
   if(rebuild)
     {
      ArrayInitialize(BuyBuffer,EMPTY_VALUE);
      ArrayInitialize(SellBuffer,EMPTY_VALUE);
     }
   BuyBuffer[0]=EMPTY_VALUE;SellBuffer[0]=EMPTY_VALUE;
   const int oldest=MathMin(InpMaxHistoryBars,total-InpATRPeriod-3);
   const double fastAlpha=2.0/(InpFastEMA+1.0);
   const double slowAlpha=2.0/(InpSlowEMA+1.0);
   double emaFast=close[oldest],emaSlow=close[oldest];
   int processed=0,lastSignal=-1000000000;
   bool newestBuy=false,newestSell=false;
   for(int i=oldest;i>=1;i--)
     {
      // State is replayed from old to new for identical incremental/full logic.
      // Record prior EMA (at i+1) BEFORE adding closed candle i.
      const double previousFast=emaFast,previousSlow=emaSlow;
      emaFast=fastAlpha*close[i]+(1.0-fastAlpha)*emaFast;
      emaSlow=slowAlpha*close[i]+(1.0-slowAlpha)*emaSlow;
      processed++;

      if(!rebuild && time[i]<=previousClosed)
        {
         // Reconstruct cooldown from confirmed arrows without rewriting them.
         if(BuyBuffer[i]!=EMPTY_VALUE || SellBuffer[i]!=EMPTY_VALUE)
            lastSignal=i;
         continue;
        }
      BuyBuffer[i]=EMPTY_VALUE;SellBuffer[i]=EMPTY_VALUE;
      if(processed<InpSlowEMA+8 || i>=oldest) continue;

      const double atr=ATRBefore(i,total,high,low,close);
      if(atr<=0.0) continue;
      if(InpMaxSpreadPoints>0 && spread[i]>InpMaxSpreadPoints) continue;
      const double candle=MathMax(high[i]-low[i],_Point);
      const double body=(close[i]-open[i])/candle;
      const bool touchedLong=(low[i+1]<=previousFast+InpTouchToleranceATR*atr &&
                             close[i+1]>=previousFast-InpMaxTouchDistanceATR*atr);
      const bool touchedShort=(high[i+1]>=previousFast-InpTouchToleranceATR*atr &&
                              close[i+1]<=previousFast+InpMaxTouchDistanceATR*atr);
      const bool buy=(emaFast>emaSlow && emaSlow>previousSlow &&
                      touchedLong &&
                      close[i]>emaFast+InpResumeDistanceATR*atr &&
                      body>=InpMinBodyFraction);
      const bool sell=(emaFast<emaSlow && emaSlow<previousSlow &&
                       touchedShort &&
                       close[i]<emaFast-InpResumeDistanceATR*atr &&
                       body<=-InpMinBodyFraction);
      if(buy==sell) continue;
      if(lastSignal-i<=InpCooldownBars) continue;
      const double offset=MathMax(0.15*atr,3*_Point);
      if(buy) BuyBuffer[i]=low[i]-offset;
      else SellBuffer[i]=high[i]+offset;
      lastSignal=i;
      if(i==1 && !rebuild) {newestBuy=buy;newestSell=sell;}
     }
   g_lastClosed=time[1];
   if(InpAlerts && !rebuild && (newestBuy || newestSell) && g_alerted!=time[1])
     {
      g_alerted=time[1];
      Alert("Nexus Trend Pullback ",_Symbol," ",EnumToString(_Period),
            " ",(newestBuy ? "BUY" : "SELL")," confirmed");
     }
   return total;
  }
//+------------------------------------------------------------------+
