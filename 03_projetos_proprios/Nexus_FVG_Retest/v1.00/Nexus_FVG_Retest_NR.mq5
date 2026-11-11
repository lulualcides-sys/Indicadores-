//+------------------------------------------------------------------+
//| Nexus FVG Retest NR v1.00 — original closed-bar implementation     |
//| First retest of a confirmed 3-candle fair-value gap.              |
//| NOT vendor source, not an automated trading robot.                |
//+------------------------------------------------------------------+
#property copyright "Independent implementation - 2026"
#property version "1.00"
#property description "FVG retest: immutable confirmed BUY/SELL arrows, entry/SL/TP visual plans. No live-bar signals."
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2
#property indicator_label1 "FVG BUY confirmed"
#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrAqua
#property indicator_width1 2
#property indicator_label2 "FVG SELL confirmed"
#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrOrangeRed
#property indicator_width2 2

input int    InpATRPeriod          = 14;
input int    InpMaxGapAgeBars      = 30;    // Search fresh gaps within N CLOSED bars
input double InpMinGapATR          = 0.12;  // FVG size relative to ATR at formation
input double InpTouchToleranceATR  = 0.06;  // Near touch at first retest
input double InpMinReclaimATR      = 0.02;  // Close past near edge
input double InpMaxPierceATR       = 0.30;  // Maximum pierce of far edge allowed
input double InpStopBufferATR      = 0.08;
input int    InpMaxSpreadPoints    = 0;     // 0=disable
input double InpTP1R               = 1.00;
input double InpTP2R               = 1.50;
input double InpTP3R               = 2.00;
input int    InpHistoryBars        = 3000;
input int    InpDrawLastBars       = 140;
input bool   InpAlerts             = false;

double BuyBuffer[],SellBuffer[];
string g_prefix="";
datetime g_seenOpen=0, g_lastClosedProcessed=0, g_alerted=0;

// Signal ATR uses only OLDER candles than candidate bar, not bar zero.
double PreviousATR(const int i,const int total,
                   const double &hi[],const double &lo[],const double &cl[])
  {
   if(i+InpATRPeriod+1>=total) return 0.0;
   double sum=0.0;
   for(int k=i+1;k<=i+InpATRPeriod;k++)
     {
      double r=hi[k]-lo[k];
      r=MathMax(r,MathAbs(hi[k]-cl[k+1]));
      r=MathMax(r,MathAbs(lo[k]-cl[k+1]));
      sum+=r;
     }
   return sum/(double)InpATRPeriod;
  }

void Level(const string name,const datetime from,const datetime to,
           const double price,const color col)
  {
   if(ObjectFind(0,name)>=0) return;
   if(!ObjectCreate(0,name,OBJ_TREND,0,from,price,to,price)) return;
   ObjectSetInteger(0,name,OBJPROP_COLOR,col);
   ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_DASH);
   ObjectSetInteger(0,name,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
  }

void Plan(const datetime barStart,const int dir,const double entry,
          const double sl,const double zoneNear,const double zoneFar)
  {
   const int seconds=PeriodSeconds(_Period);
   const datetime from=barStart+seconds; // available after candle closed
   const datetime to=from+8*seconds;
   const double risk=(double)dir*(entry-sl);
   if(risk<=0.0) return;
   const string id=g_prefix+IntegerToString((long)barStart)+"_";
   Level(id+"ENTRY",from,to,entry,clrDodgerBlue);
   Level(id+"SL",from,to,sl,clrFireBrick);
   Level(id+"TP1",from,to,entry+(double)dir*InpTP1R*risk,clrLime);
   Level(id+"TP2",from,to,entry+(double)dir*InpTP2R*risk,clrLimeGreen);
   Level(id+"TP3",from,to,entry+(double)dir*InpTP3R*risk,clrDarkGreen);
   Level(id+"FVG_NEAR",from,to,zoneNear,clrSlateGray);
   Level(id+"FVG_FAR",from,to,zoneFar,clrSlateGray);
   const string label=id+"TAG";
   if(ObjectFind(0,label)<0 && ObjectCreate(0,label,OBJ_TEXT,0,from,entry))
     {
      ObjectSetString(0,label,OBJPROP_TEXT,(dir==1 ? "FVG BUY" : "FVG SELL"));
      ObjectSetInteger(0,label,OBJPROP_COLOR,(dir==1 ? clrAqua : clrOrangeRed));
      ObjectSetInteger(0,label,OBJPROP_FONTSIZE,9);
      ObjectSetInteger(0,label,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,label,OBJPROP_HIDDEN,true);
     }
  }

int OnInit()
  {
   if(InpATRPeriod<2 || InpMaxGapAgeBars<2 || InpMaxGapAgeBars>250 ||
      InpMinGapATR<0.0 || InpTouchToleranceATR<0.0 ||
      InpMinReclaimATR<0.0 || InpMaxPierceATR<0.0 ||
      InpStopBufferATR<0.0 || InpMaxSpreadPoints<0 ||
      InpTP1R<=0.0 || InpTP2R<=InpTP1R || InpTP3R<=InpTP2R ||
      InpHistoryBars<100 || InpDrawLastBars<0)
     {
      Print("Nexus FVG Retest NR: invalid parameters");
      return INIT_PARAMETERS_INCORRECT;
     }
   SetIndexBuffer(0,BuyBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SellBuffer,INDICATOR_DATA);
   ArraySetAsSeries(BuyBuffer,true);
   ArraySetAsSeries(SellBuffer,true);
   PlotIndexSetInteger(0,PLOT_ARROW,233);
   PlotIndexSetInteger(1,PLOT_ARROW,234);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   IndicatorSetString(INDICATOR_SHORTNAME,"Nexus FVG Retest NR v1.00");
   g_prefix="NFVG_"+IntegerToString((long)ChartID())+"_";
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
   const int minNeeded=InpATRPeriod+InpMaxGapAgeBars+6;
   if(rates_total<minNeeded) return 0;
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(spread,true);
   const bool rebuild=(prev_calculated==0 || g_seenOpen==0);
   if(!rebuild && time[0]==g_seenOpen) return rates_total;
   const datetime lastClosed=g_lastClosedProcessed;
   g_seenOpen=time[0];
   if(rebuild)
     {
      ArrayInitialize(BuyBuffer,EMPTY_VALUE);
      ArrayInitialize(SellBuffer,EMPTY_VALUE);
      ObjectsDeleteAll(0,g_prefix,0,-1);
     }
   BuyBuffer[0]=EMPTY_VALUE;
   SellBuffer[0]=EMPTY_VALUE;
   // i+InpMaxGapAgeBars+InpATRPeriod+3 must stay within the known OHLC arrays.
   const int oldest=MathMin(InpHistoryBars,rates_total-(InpMaxGapAgeBars+InpATRPeriod+4));
   bool newestBuy=false,newestSell=false;
   for(int i=oldest;i>=1;i--)
     {
      // Never revise a previously confirmed bar during routine new-bar calls.
      if(!rebuild && time[i]<=lastClosed) continue;
      BuyBuffer[i]=EMPTY_VALUE;
      SellBuffer[i]=EMPTY_VALUE;
      if(InpMaxSpreadPoints>0 && spread[i]>InpMaxSpreadPoints) continue;
      const double atrSignal=PreviousATR(i,rates_total,high,low,close);
      if(atrSignal<=0.0) continue;

      int dir=0;
      double zoneNear=0.0,zoneFar=0.0;
      // j is the THIRD FVG candle, and j>i means it closed BEFORE the signal.
      for(int j=i+1;j<=i+InpMaxGapAgeBars;j++)
        {
         const double atrGap=PreviousATR(j,rates_total,high,low,close);
         if(atrGap<=0.0) continue;
         const double bullSize=low[j]-high[j+2];
         const double bearSize=low[j+2]-high[j];
         if(bullSize>=InpMinGapATR*atrGap && bullSize>_Point)
           {
            const double nearEdge=low[j];  // bullish gap [high[j+2],low[j]]
            const double farEdge=high[j+2];
            bool fresh=true;
            for(int k=j-1;k>i;k--)
               if(low[k]<=nearEdge) {fresh=false;break;}
            if(fresh && low[i]<=nearEdge+InpTouchToleranceATR*atrSignal &&
               high[i]>=farEdge && low[i]>=farEdge-InpMaxPierceATR*atrSignal &&
               close[i]>=nearEdge+InpMinReclaimATR*atrSignal &&
               close[i]>open[i])
              {dir=1;zoneNear=nearEdge;zoneFar=farEdge;break;}
           }
         if(bearSize>=InpMinGapATR*atrGap && bearSize>_Point)
           {
            const double nearEdge=high[j]; // bearish gap [high[j],low[j+2]]
            const double farEdge=low[j+2];
            bool fresh=true;
            for(int k=j-1;k>i;k--)
               if(high[k]>=nearEdge) {fresh=false;break;}
            if(fresh && high[i]>=nearEdge-InpTouchToleranceATR*atrSignal &&
               low[i]<=farEdge && high[i]<=farEdge+InpMaxPierceATR*atrSignal &&
               close[i]<=nearEdge-InpMinReclaimATR*atrSignal &&
               close[i]<open[i])
              {dir=-1;zoneNear=nearEdge;zoneFar=farEdge;break;}
           }
        }
      if(dir==0) continue;
      const double entry=close[i]; // reference on closed bar, not fill
      const double stop=(dir==1 ? low[i]-InpStopBufferATR*atrSignal :
                                high[i]+InpStopBufferATR*atrSignal);
      if((double)dir*(entry-stop)<=2*_Point) continue;
      const double shift=MathMax(0.16*atrSignal,3*_Point);
      if(dir==1) BuyBuffer[i]=low[i]-shift;
      else       SellBuffer[i]=high[i]+shift;
      if(i<=InpDrawLastBars) Plan(time[i],dir,entry,stop,zoneNear,zoneFar);
      if(i==1 && !rebuild)
        {
         newestBuy=(dir==1);
         newestSell=(dir==-1);
        }
     }
   g_lastClosedProcessed=time[1];
   if(InpAlerts && !rebuild && (newestBuy||newestSell) && g_alerted!=time[1])
     {
      g_alerted=time[1];
      Alert("Nexus FVG ",_Symbol," ",EnumToString(_Period)," ",
            (newestBuy ? "BUY" : "SELL")," confirmed on closed bar");
     }
   return rates_total;
  }
//+------------------------------------------------------------------+
