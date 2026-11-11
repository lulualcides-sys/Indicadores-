//+------------------------------------------------------------------+
//| Nexus Three-Candle Reversal NR v1.00                              |
//| Independent 3-candle exhaustion + midpoint reclaim pattern.       |
//| Completed bars only, no centered pivots, no future information.   |
//+------------------------------------------------------------------+
#property copyright "Independent implementation, 2026"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2
#property indicator_label1 "3C BUY confirmed"
#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrLimeGreen
#property indicator_width1 2
#property indicator_label2 "3C SELL confirmed"
#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrTomato
#property indicator_width2 2

input int InpATRPeriod=14;
input double InpConfirmATR=0.03;
input double InpMinSignalBody=0.24;
input double InpMinFirstBodyATR=0.15;
input int InpCooldownBars=2;
input int InpMaxHistoryBars=4500;
input bool InpAlerts=false;

double BuyBuffer[],SellBuffer[];
datetime g_lastSeenOpen=0,g_lastClosed=0,g_lastSignaled=0,g_alerted=0;

double PriorATR(const int i,const int count,
                const double &hi[],const double &lo[],const double &cl[])
  {
   if(i+InpATRPeriod+1>=count) return 0.0;
   double trSum=0.0;
   for(int j=i+1;j<=i+InpATRPeriod;j++)
     {
      double tr=hi[j]-lo[j];
      tr=MathMax(tr,MathAbs(hi[j]-cl[j+1]));
      tr=MathMax(tr,MathAbs(lo[j]-cl[j+1]));
      trSum+=tr;
     }
   return trSum/InpATRPeriod;
  }

int OnInit()
  {
   if(InpATRPeriod<2 || InpATRPeriod>100 || InpConfirmATR<0.0 ||
      InpMinSignalBody<0.0 || InpMinSignalBody>1.0 ||
      InpMinFirstBodyATR<0.0 || InpCooldownBars<0 ||
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
   IndicatorSetString(INDICATOR_SHORTNAME,"Nexus Three Candle Reversal NR 1.00");
   return INIT_SUCCEEDED;
  }

int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],
                const double &high[],const double &low[],
                const double &close[],const long &tick_volume[],
                const long &volume[],const int &spread[])
  {
   if(rates_total<InpATRPeriod+8) return 0;
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
      g_lastSignaled=0;
     }
   BuyBuffer[0]=EMPTY_VALUE;
   SellBuffer[0]=EMPTY_VALUE;
   const int oldest=MathMin(InpMaxHistoryBars,rates_total-InpATRPeriod-3);
   bool alertBuy=false,alertSell=false;
   for(int i=oldest;i>=1;i--)
     {
      if(!rebuild && time[i]<=previousClosed) continue;
      BuyBuffer[i]=EMPTY_VALUE;
      SellBuffer[i]=EMPTY_VALUE;
      const double atr=PriorATR(i,rates_total,high,low,close);
      if(atr<=0) continue;
      const double mid=(open[i+2]+close[i+2])/2.0;
      const double firstBody=MathAbs(open[i+2]-close[i+2]);
      if(firstBody<InpMinFirstBodyATR*atr) continue;
      const double candle=MathMax(high[i]-low[i],_Point);
      const double body=(close[i]-open[i])/candle;
      // Two CLOSED setup candles: reversal requires a NEW price extreme.
      // Signal occurs at close of third candle i, never on setup bar.
      const bool buy=
         open[i+2]>close[i+2] &&
         low[i+1]<low[i+2] &&
         close[i+1]<=close[i+2] &&
         close[i]>mid+InpConfirmATR*atr &&
         close[i]>open[i] &&
         body>=InpMinSignalBody;
      const bool sell=
         open[i+2]<close[i+2] &&
         high[i+1]>high[i+2] &&
         close[i+1]>=close[i+2] &&
         close[i]<mid-InpConfirmATR*atr &&
         close[i]<open[i] &&
         body<=-InpMinSignalBody;
      if(buy==sell) continue;
      if(g_lastSignaled>0)
        {
         const int prevIndex=iBarShift(_Symbol,_Period,g_lastSignaled,false);
         if(prevIndex>=i && prevIndex-i<=InpCooldownBars) continue;
        }
      const double offset=MathMax(0.16*atr,3*_Point);
      if(buy) BuyBuffer[i]=low[i]-offset;
      else SellBuffer[i]=high[i]+offset;
      g_lastSignaled=time[i];
      if(i==1 && !rebuild) {alertBuy=buy;alertSell=sell;}
     }
   g_lastClosed=time[1];
   if(InpAlerts && !rebuild && (alertBuy||alertSell) && g_alerted!=time[1])
     {
      g_alerted=time[1];
      Alert("Nexus Three Candle ",_Symbol," ",EnumToString(_Period),
            " ",(alertBuy?"BUY":"SELL")," confirmed on close");
     }
   return rates_total;
  }
//+------------------------------------------------------------------+
