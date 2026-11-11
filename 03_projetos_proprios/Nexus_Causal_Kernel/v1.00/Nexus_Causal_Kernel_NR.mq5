//+------------------------------------------------------------------+
//| Nexus Causal Kernel Reclaim NR v1.00                             |
//| Independent one-sided Gaussian kernel + deviation envelope.      |
//| Only candle-close signals: never centered/symmetric regression.  |
//+------------------------------------------------------------------+
#property copyright "Independent implementation, 2026"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2
#property indicator_label1 "Kernel BUY confirmed"
#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrLimeGreen
#property indicator_width1 2
#property indicator_label2 "Kernel SELL confirmed"
#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrTomato
#property indicator_width2 2

input int InpKernelWindow=40;
input double InpBandwidth=9.0;
input double InpEnvelopeMultiplier=2.0;
input int InpATRPeriod=14;
input double InpMinEnvelopeATR=0.20;
input double InpMinBodyFraction=0.12;
input int InpCooldownBars=2;
input int InpMaxHistoryBars=4000;
input bool InpAlerts=false;

double BuyBuffer[],SellBuffer[];
datetime g_lastSeenOpen=0,g_lastClosed=0,g_lastSignal=0,g_alerted=0;

// Each kernel estimate uses this CLOSED candle and only older candles.
// In MQL5 series indexing, positive k points into the PAST, never the future.
bool KernelAt(const int i,const int count,const double &close[],
              double &basis,double &mad)
  {
   if(i+InpKernelWindow>count) return false;
   double weightSum=0.0,weightedPrice=0.0;
   for(int k=0;k<InpKernelWindow;k++)
     {
      const double x=(double)k/InpBandwidth;
      const double w=MathExp(-0.5*x*x);
      weightSum+=w;
      weightedPrice+=w*close[i+k];
     }
   if(weightSum<=0.0) return false;
   basis=weightedPrice/weightSum;
   double deviations=0.0;
   for(int k=0;k<InpKernelWindow;k++)
     {
      const double x=(double)k/InpBandwidth;
      const double w=MathExp(-0.5*x*x);
      deviations+=w*MathAbs(close[i+k]-basis);
     }
   mad=deviations/weightSum;
   return true;
  }

double PriorATR(const int i,const int total,
                const double &hi[],const double &lo[],
                const double &cl[])
  {
   if(i+InpATRPeriod+1>=total) return 0.0;
   double sum=0.0;
   for(int k=i+1;k<=i+InpATRPeriod;k++)
     {
      double tr=hi[k]-lo[k];
      tr=MathMax(tr,MathAbs(hi[k]-cl[k+1]));
      tr=MathMax(tr,MathAbs(lo[k]-cl[k+1]));
      sum+=tr;
     }
   return sum/InpATRPeriod;
  }

int OnInit()
  {
   if(InpKernelWindow<8 || InpKernelWindow>250 ||
      InpBandwidth<=0.0 || InpBandwidth>200 ||
      InpEnvelopeMultiplier<=0.0 || InpEnvelopeMultiplier>20 ||
      InpATRPeriod<2 || InpATRPeriod>100 ||
      InpMinEnvelopeATR<0.0 || InpMinBodyFraction<0.0 ||
      InpMinBodyFraction>1.0 || InpCooldownBars<0 ||
      InpCooldownBars>100 || InpMaxHistoryBars<100)
      return INIT_PARAMETERS_INCORRECT;
   SetIndexBuffer(0,BuyBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SellBuffer,INDICATOR_DATA);
   ArraySetAsSeries(BuyBuffer,true);
   ArraySetAsSeries(SellBuffer,true);
   PlotIndexSetInteger(0,PLOT_ARROW,233);
   PlotIndexSetInteger(1,PLOT_ARROW,234);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   IndicatorSetString(INDICATOR_SHORTNAME,"Nexus Causal Kernel NR 1.00");
   return INIT_SUCCEEDED;
  }

int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],
                const double &high[],const double &low[],
                const double &close[],const long &tick_volume[],
                const long &volume[],const int &spread[])
  {
   const int need=MathMax(InpKernelWindow+1,InpATRPeriod+2);
   if(rates_total<need+4) return 0;
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   const bool rebuild=(prev_calculated==0 || g_lastSeenOpen==0);
   if(!rebuild && time[0]==g_lastSeenOpen) return rates_total;
   const datetime previousClosed=g_lastClosed;
   g_lastSeenOpen=time[0];
   if(rebuild)
     {
      ArrayInitialize(BuyBuffer,EMPTY_VALUE);
      ArrayInitialize(SellBuffer,EMPTY_VALUE);
      g_lastSignal=0;
     }
   BuyBuffer[0]=EMPTY_VALUE;
   SellBuffer[0]=EMPTY_VALUE;
   const int oldest=MathMin(InpMaxHistoryBars,rates_total-need-2);
   bool newBuy=false,newSell=false;
   for(int i=oldest;i>=1;i--)
     {
      if(!rebuild && time[i]<=previousClosed) continue;
      BuyBuffer[i]=EMPTY_VALUE;SellBuffer[i]=EMPTY_VALUE;
      double basis=0,mad=0,prevBasis=0,prevMAD=0;
      if(!KernelAt(i,rates_total,close,basis,mad) ||
         !KernelAt(i+1,rates_total,close,prevBasis,prevMAD)) continue;
      const double atr=PriorATR(i,rates_total,high,low,close);
      const double prevATR=PriorATR(i+1,rates_total,high,low,close);
      if(atr<=0.0 || prevATR<=0.0) continue;
      const double width=MathMax(InpEnvelopeMultiplier*mad,
                                 InpMinEnvelopeATR*atr);
      const double prevWidth=MathMax(InpEnvelopeMultiplier*prevMAD,
                                     InpMinEnvelopeATR*prevATR);
      const double lowBand=basis-width,upperBand=basis+width;
      const double prevLowBand=prevBasis-prevWidth;
      const double prevUpperBand=prevBasis+prevWidth;
      const double candle=MathMax(high[i]-low[i],_Point);
      const double body=(close[i]-open[i])/candle;
      // A previously confirmed extreme is required. No live-bar bounces.
      const bool buy=(close[i+1]<prevLowBand &&
                      close[i]>lowBand && body>=InpMinBodyFraction);
      const bool sell=(close[i+1]>prevUpperBand &&
                       close[i]<upperBand && body<=-InpMinBodyFraction);
      if(buy==sell) continue;
      // Minimum bar distance since last signal, including across new ticks.
      if(g_lastSignal>0)
        {
         const int previousIdx=iBarShift(_Symbol,_Period,g_lastSignal,false);
         if(previousIdx>=i && previousIdx-i<=InpCooldownBars) continue;
        }
      const double offset=MathMax(0.15*atr,3*_Point);
      if(buy) BuyBuffer[i]=low[i]-offset;
      else SellBuffer[i]=high[i]+offset;
      g_lastSignal=time[i];
      if(i==1 && !rebuild) {newBuy=buy;newSell=sell;}
     }
   g_lastClosed=time[1];
   if(InpAlerts && !rebuild && (newBuy||newSell) && g_alerted!=time[1])
     {
      g_alerted=time[1];
      Alert("Nexus Causal Kernel ",_Symbol," ",EnumToString(_Period),
            " ",(newBuy?"BUY":"SELL")," confirmed on closed candle");
     }
   return rates_total;
  }
//+------------------------------------------------------------------+
