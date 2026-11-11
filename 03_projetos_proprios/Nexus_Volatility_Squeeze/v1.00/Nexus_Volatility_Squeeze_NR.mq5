//+------------------------------------------------------------------+
//| Nexus Volatility Squeeze Break NR v1.00                            |
//| Independent MT5 indicator: closed-bar BB / ATR-Keltner release.   |
//| BUY/SELL arrow only AFTER close; no future bars, no orders.       |
//+------------------------------------------------------------------+
#property copyright "Independent implementation 2026"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2
#property indicator_label1 "SQUEEZE BUY confirmed"
#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrLimeGreen
#property indicator_width1 2
#property indicator_label2 "SQUEEZE SELL confirmed"
#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrTomato
#property indicator_width2 2

input int InpBBPeriod=20;               // Rolling mean/stdev of closed prices
input double InpBBDeviation=2.0;        // Bollinger half-width = multiplier * stdev
input int InpATRPeriod=20;              // Wilder-like TR simple average
input double InpKeltnerATRMultiplier=1.5;
input int InpBreakLookback=12;          // Prior CLOSED bar high/low
input double InpMinBreakATR=0.02;       // Min close distance beyond prior range
input double InpMinBodyFraction=0.20;  // Closed candle body fraction
input int InpMaxSpreadPoints=0;        // 0=off; broker historical spread estimate
input int InpMaxHistoryBars=4000;
input bool InpAlerts=false;

double BuyBuffer[],SellBuffer[];
datetime g_open=0,g_lastClosed=0,g_alerted=0;

double ATRPast(const int i,const int total,
               const double &hi[],const double &lo[],const double &cl[])
  {
   if(i+InpATRPeriod>=total) return 0.0;
   double sum=0.0;
   for(int j=i;j<i+InpATRPeriod;j++)
     {
      double tr=hi[j]-lo[j];
      tr=MathMax(tr,MathAbs(hi[j]-cl[j+1]));
      tr=MathMax(tr,MathAbs(lo[j]-cl[j+1]));
      sum+=tr;
     }
   return sum/InpATRPeriod;
  }

double BollingerHalfWidth(const int i,const int total,const double &cl[])
  {
   if(i+InpBBPeriod>total) return 0.0;
   double mean=0.0;
   for(int j=i;j<i+InpBBPeriod;j++) mean+=cl[j];
   mean/=InpBBPeriod;
   double var=0.0;
   for(int j=i;j<i+InpBBPeriod;j++)
      var+=MathPow(cl[j]-mean,2.0);
   return InpBBDeviation*MathSqrt(var/InpBBPeriod);
  }

void PriorBreakRange(const int i,const double &hi[],const double &lo[],
                     double &top,double &bottom)
  {
   top=-DBL_MAX;bottom=DBL_MAX;
   for(int j=i+1;j<=i+InpBreakLookback;j++)
     {
      top=MathMax(top,hi[j]);
      bottom=MathMin(bottom,lo[j]);
     }
  }

int OnInit()
  {
   if(InpBBPeriod<5 || InpBBDeviation<=0.0 || InpATRPeriod<5 ||
      InpKeltnerATRMultiplier<=0.0 || InpBreakLookback<2 ||
      InpMinBreakATR<0.0 || InpMinBodyFraction<0.0 ||
      InpMinBodyFraction>1.0 || InpMaxSpreadPoints<0 ||
      InpMaxHistoryBars<100) return INIT_PARAMETERS_INCORRECT;
   SetIndexBuffer(0,BuyBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SellBuffer,INDICATOR_DATA);
   ArraySetAsSeries(BuyBuffer,true);
   ArraySetAsSeries(SellBuffer,true);
   PlotIndexSetInteger(0,PLOT_ARROW,233);
   PlotIndexSetInteger(1,PLOT_ARROW,234);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   IndicatorSetString(INDICATOR_SHORTNAME,"Nexus Squeeze Break NR v1.00");
   return INIT_SUCCEEDED;
  }

int OnCalculate(const int total,const int prevCalculated,const datetime &time[],
                const double &open[],const double &high[],const double &low[],
                const double &close[],const long &tickVolume[],
                const long &realVolume[],const int &spread[])
  {
   const int warmup=MathMax(MathMax(InpBBPeriod,InpATRPeriod)+1,InpBreakLookback);
   if(total<warmup+8) return 0;
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
   BuyBuffer[0]=EMPTY_VALUE;
   SellBuffer[0]=EMPTY_VALUE;
   const int oldest=MathMin(InpMaxHistoryBars,total-warmup-2);
   bool lastBuy=false,lastSell=false;
   for(int i=oldest;i>=1;i--)
     {
      // Historical confirmed buffers are never overwritten during normal ticks.
      if(!rebuild && time[i]<=previousClosed) continue;
      BuyBuffer[i]=EMPTY_VALUE;SellBuffer[i]=EMPTY_VALUE;

      const double atrNow=ATRPast(i,total,high,low,close);
      const double atrBefore=ATRPast(i+1,total,high,low,close);
      if(atrNow<=0 || atrBefore<=0) continue;
      const bool wasCompressed=(BollingerHalfWidth(i+1,total,close) <=
                                InpKeltnerATRMultiplier*atrBefore);
      const bool releasedNow=(BollingerHalfWidth(i,total,close) >
                              InpKeltnerATRMultiplier*atrNow);
      if(!wasCompressed || !releasedNow) continue;
      if(InpMaxSpreadPoints>0 && spread[i]>InpMaxSpreadPoints) continue;

      double top=0.0,bottom=0.0;
      PriorBreakRange(i,high,low,top,bottom);
      if(top<=bottom) continue;
      const double candle=MathMax(high[i]-low[i],_Point);
      const double body=(close[i]-open[i])/candle;
      const bool buy=(close[i]>top+InpMinBreakATR*atrBefore &&
                      body>=InpMinBodyFraction);
      const bool sell=(close[i]<bottom-InpMinBreakATR*atrBefore &&
                       body<=-InpMinBodyFraction);
      if(buy==sell) continue;
      const double offset=MathMax(0.18*atrBefore,3*_Point);
      if(buy) BuyBuffer[i]=low[i]-offset;
      else SellBuffer[i]=high[i]+offset;
      if(i==1 && !rebuild) {lastBuy=buy;lastSell=sell;}
     }
   g_lastClosed=time[1];
   if(InpAlerts && !rebuild && (lastBuy || lastSell) && g_alerted!=time[1])
     {
      g_alerted=time[1];
      Alert("Nexus Squeeze ",_Symbol," ",EnumToString(_Period)," ",
            (lastBuy ? "BUY" : "SELL")," confirmed at candle close");
     }
   return total;
  }
//+------------------------------------------------------------------+
