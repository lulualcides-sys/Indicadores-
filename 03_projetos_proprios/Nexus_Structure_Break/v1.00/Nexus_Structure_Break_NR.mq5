//+------------------------------------------------------------------+
//| Nexus Confirmed Structure NR v1.00 — independent MQL5 indicator   |
//| Confirm pivots using RIGHT bars that have ALREADY CLOSED.         |
//| BOS/CHoCH only at break candle close. Never backdate arrows.       |
//+------------------------------------------------------------------+
#property copyright "Independent implementation 2026"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots 4
#property indicator_label1 "Confirmed structure BUY"
#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrLimeGreen
#property indicator_width1 2
#property indicator_label2 "Confirmed structure SELL"
#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrTomato
#property indicator_width2 2
#property indicator_label3 "Confirmed prior swing high"
#property indicator_type3 DRAW_LINE
#property indicator_color3 clrRoyalBlue
#property indicator_style3 STYLE_DOT
#property indicator_label4 "Confirmed prior swing low"
#property indicator_type4 DRAW_LINE
#property indicator_color4 clrOrange
#property indicator_style4 STYLE_DOT

input int    InpLeftBars       = 3;     // Older-side pivot comparison
input int    InpRightBars      = 3;     // Newer-side confirmation bars, all CLOSED
input int    InpATRPeriod      = 14;
input double InpBreakATR       = 0.03;  // Closed candle beyond confirmed pivot
input double InpMinBodyFraction= 0.20;  // Directional candle body quality
input double InpStopBufferATR  = 0.08;
input int    InpMaxSpreadPoints= 0;
input double InpTP1R           = 1.00;
input double InpTP2R           = 1.50;
input double InpTP3R           = 2.00;
input int    InpMaxHistoryBars = 4000;
input int    InpDrawRecentBars = 140;
input bool   InpAlerts         = false;

double BuyBuffer[],SellBuffer[],HighLevel[],LowLevel[];
string g_prefix="";
datetime g_seenOpen=0,g_lastClosedProcessed=0,g_alerted=0;

double ATRBefore(const int i,const int n,
                 const double &hi[],const double &lo[],const double &cl[])
  {
   if(i+InpATRPeriod+1>=n) return 0.0;
   double sum=0.0;
   for(int j=i+1;j<=i+InpATRPeriod;j++)
     {
      double tr=hi[j]-lo[j];
      tr=MathMax(tr,MathAbs(hi[j]-cl[j+1]));
      tr=MathMax(tr,MathAbs(lo[j]-cl[j+1]));
      sum+=tr;
     }
   return sum/(double)InpATRPeriod;
  }

bool IsPivotHigh(const int c,const int right,const int left,
                 const double &high[])
  {
   for(int k=1;k<=left;k++) if(high[c]<=high[c+k]) return false;
   for(int k=1;k<=right;k++) if(high[c]<=high[c-k]) return false;
   return true;
  }

bool IsPivotLow(const int c,const int right,const int left,
                const double &low[])
  {
   for(int k=1;k<=left;k++) if(low[c]>=low[c+k]) return false;
   for(int k=1;k<=right;k++) if(low[c]>=low[c-k]) return false;
   return true;
  }

void Level(const string name,const datetime from,const datetime to,
           const double v,const color col)
  {
   if(ObjectFind(0,name)>=0) return;
   if(!ObjectCreate(0,name,OBJ_TREND,0,from,v,to,v)) return;
   ObjectSetInteger(0,name,OBJPROP_COLOR,col);
   ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_DOT);
   ObjectSetInteger(0,name,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
  }

void DrawEvent(const datetime barStart,const int dir,
               const bool change,const double entry,
               const double stop)
  {
   const int seconds=PeriodSeconds(_Period);
   const datetime from=barStart+seconds,to=from+10*seconds;
   const double risk=(double)dir*(entry-stop);
   if(risk<=0.0) return;
   const string id=g_prefix+IntegerToString((long)barStart)+"_";
   Level(id+"ENTRY",from,to,entry,clrDodgerBlue);
   Level(id+"SL",from,to,stop,clrFireBrick);
   Level(id+"TP1",from,to,entry+dir*InpTP1R*risk,clrLimeGreen);
   Level(id+"TP2",from,to,entry+dir*InpTP2R*risk,clrLimeGreen);
   Level(id+"TP3",from,to,entry+dir*InpTP3R*risk,clrDarkGreen);
   const string name=id+"TEXT";
   if(ObjectFind(0,name)<0 && ObjectCreate(0,name,OBJ_TEXT,0,from,entry))
     {
      ObjectSetString(0,name,OBJPROP_TEXT,
                      (change ? "CHoCH " : "BOS ")+(dir==1 ? "BUY" : "SELL"));
      ObjectSetInteger(0,name,OBJPROP_COLOR,(dir==1 ? clrLimeGreen : clrTomato));
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,9);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
     }
  }

int OnInit()
  {
   if(InpLeftBars<1 || InpLeftBars>20 || InpRightBars<1 || InpRightBars>20 ||
      InpATRPeriod<2 || InpBreakATR<0.0 ||
      InpMinBodyFraction<0.0 || InpMinBodyFraction>1.0 ||
      InpStopBufferATR<0.0 || InpMaxSpreadPoints<0 ||
      InpTP1R<=0.0 || InpTP2R<=InpTP1R || InpTP3R<=InpTP2R ||
      InpMaxHistoryBars<100 || InpDrawRecentBars<0)
      return INIT_PARAMETERS_INCORRECT;
   SetIndexBuffer(0,BuyBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SellBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,HighLevel,INDICATOR_DATA);
   SetIndexBuffer(3,LowLevel,INDICATOR_DATA);
   ArraySetAsSeries(BuyBuffer,true);
   ArraySetAsSeries(SellBuffer,true);
   ArraySetAsSeries(HighLevel,true);
   ArraySetAsSeries(LowLevel,true);
   PlotIndexSetInteger(0,PLOT_ARROW,233);
   PlotIndexSetInteger(1,PLOT_ARROW,234);
   for(int p=0;p<4;p++)
      PlotIndexSetDouble(p,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   IndicatorSetString(INDICATOR_SHORTNAME,"Nexus Structure Break NR 1.00");
   g_prefix="NSTR_"+IntegerToString((long)ChartID())+"_";
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
   const int need=MathMax(InpLeftBars+InpRightBars+1,InpATRPeriod+2);
   if(rates_total<need+10) return 0;
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
      ArrayInitialize(HighLevel,EMPTY_VALUE);
      ArrayInitialize(LowLevel,EMPTY_VALUE);
      ObjectsDeleteAll(0,g_prefix,0,-1);
     }
   BuyBuffer[0]=EMPTY_VALUE;
   SellBuffer[0]=EMPTY_VALUE;
   HighLevel[0]=EMPTY_VALUE;
   LowLevel[0]=EMPTY_VALUE;

   const int oldest=MathMin(InpMaxHistoryBars,rates_total-need-1);
   double lastHigh=0.0,lastLow=0.0;
   bool highUsed=false,lowUsed=false;
   int trend=0;
   bool newestBuy=false,newestSell=false;
   for(int i=oldest;i>=1;i--)
     {
      const int candidate=i+InpRightBars;
      // The candidate swing becomes known NOW, after its R RIGHT candles
      // (newer in time, lower series index) have fully closed.
      if(candidate+InpLeftBars<rates_total)
        {
         if(IsPivotHigh(candidate,InpRightBars,InpLeftBars,high))
           {
            lastHigh=high[candidate];
            highUsed=false;
           }
         if(IsPivotLow(candidate,InpRightBars,InpLeftBars,low))
           {
            lastLow=low[candidate];
            lowUsed=false;
           }
        }
      if(!rebuild && time[i]<=lastClosed) continue;
      BuyBuffer[i]=EMPTY_VALUE;
      SellBuffer[i]=EMPTY_VALUE;
      HighLevel[i]=(lastHigh>0.0 ? lastHigh : EMPTY_VALUE);
      LowLevel[i]=(lastLow>0.0 ? lastLow : EMPTY_VALUE);
      if(lastHigh<=0.0 || lastLow<=0.0) continue;
      if(InpMaxSpreadPoints>0 && spread[i]>InpMaxSpreadPoints) continue;
      const double atr=ATRBefore(i,rates_total,high,low,close);
      if(atr<=0.0) continue;
      const double body=(close[i]-open[i])/
                        MathMax(high[i]-low[i],_Point);
      const bool breakUp=(!highUsed && body>=InpMinBodyFraction &&
                          close[i]>=lastHigh+InpBreakATR*atr &&
                          close[i+1]<=lastHigh);
      const bool breakDn=(!lowUsed && body<=-InpMinBodyFraction &&
                          close[i]<=lastLow-InpBreakATR*atr &&
                          close[i+1]>=lastLow);
      if(breakUp==breakDn) continue;
      const int dir=(breakUp ? 1 : -1);
      const bool change=(trend!=0 && trend!=dir);
      trend=dir;
      if(breakUp) highUsed=true;
      else        lowUsed=true;
      const double entry=close[i]; // reference, not executed fill
      const double sl=(dir==1 ? low[i]-InpStopBufferATR*atr :
                                high[i]+InpStopBufferATR*atr);
      const double risk=dir*(entry-sl);
      if(risk<=2*_Point) continue;
      const double offset=MathMax(0.16*atr,3*_Point);
      if(breakUp) BuyBuffer[i]=low[i]-offset;
      else        SellBuffer[i]=high[i]+offset;
      if(i<=InpDrawRecentBars) DrawEvent(time[i],dir,change,entry,sl);
      if(i==1 && !rebuild)
        {
         newestBuy=breakUp;newestSell=breakDn;
        }
     }
   g_lastClosedProcessed=time[1];
   if(InpAlerts && !rebuild && (newestBuy||newestSell) &&
      g_alerted!=time[1])
     {
      g_alerted=time[1];
      Alert("Nexus Structure ",_Symbol," ",EnumToString(_Period)," ",
            (newestBuy ? "BUY" : "SELL")," confirmed on closed candle");
     }
   return rates_total;
  }
//+------------------------------------------------------------------+
