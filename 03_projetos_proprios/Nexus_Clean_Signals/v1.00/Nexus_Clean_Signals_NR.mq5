//+------------------------------------------------------------------+
//| Nexus Clean Signals NR 1.00 -- independent MT5 indicator          |
//| Signals only when a candle has closed. No order placement.        |
//| Three modes: AUTO (ER), BREAKOUT and LIQUIDITY SWEEP.              |
//+------------------------------------------------------------------+
#property copyright "Independent implementation 2026"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2
#property indicator_label1 "BUY confirmed"
#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrLimeGreen
#property indicator_width1 2
#property indicator_label2 "SELL confirmed"
#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrTomato
#property indicator_width2 2

enum ENUM_NCS_MODE { NCS_AUTO=0, NCS_BREAKOUT=1, NCS_SWEEP=2 };
enum ENUM_NCS_VIEW { NCS_CLEAN=0, NCS_LAST_PLAN=1 };

input ENUM_NCS_MODE InpMode          = NCS_AUTO;
input ENUM_NCS_VIEW InpView          = NCS_CLEAN;
input bool InpShowDashboard          = true;   // Only one compact corner label
input bool InpAlerts                 = false;  // Alerts only when latest bar closes
input int  InpRangeBars              = 18;     // Prior CLOSED bars for range
input int  InpATRPeriod              = 14;     // ATR from strictly OLDER bars
input int  InpERPeriod               = 12;     // Kaufman efficiency from OLDER bars
input double InpRangingER            = 0.25;   // AUTO prefers sweeps below this
input double InpTrendingER           = 0.43;   // AUTO prefers breaks above this
input double InpMinBreakATR          = 0.07;
input double InpMinSweepATR          = 0.06;
input double InpMinReclaimATR        = 0.02;
input double InpMinBodyFraction      = 0.22;
input double InpMinWickFraction      = 0.28;
input double InpMinScore             = 0.43;   // Heuristic, not probability
input int    InpCooldownBars         = 1;
input int    InpMaxSpreadPoints      = 0;      // 0 disables filter
input double InpStopBufferATR        = 0.08;
input double InpTP1R                 = 1.00;
input double InpTP2R                 = 1.50;
input double InpTP3R                 = 2.00;
input int    InpMaxHistoryBars       = 3500;
input int    InpPlanMaxAgeBars       = 90;

double BuyBuffer[], SellBuffer[];
datetime g_seenBarOpen=0, g_lastClosed=0, g_lastAlerted=0;
string g_prefix="";

double Clip01(const double x)
  {
   return MathMax(0.0,MathMin(1.0,x));
  }

double ATRBefore(const int i,const int total,
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
   return sum/(double)InpATRPeriod;
  }

// Kaufman ER: completed candles strictly OLDER than the signal candle.
double ERBefore(const int i,const int total,const double &cl[])
  {
   if(i+InpERPeriod+1>=total) return 0.0;
   const double net=MathAbs(cl[i+1]-cl[i+InpERPeriod+1]);
   double path=0.0;
   for(int k=i+1;k<=i+InpERPeriod;k++)
      path+=MathAbs(cl[k]-cl[k+1]);
   if(path<=0.0) return 0.0;
   return Clip01(net/path);
  }

void PriorRange(const int i,const double &hi[],const double &lo[],
                double &top,double &bottom)
  {
   top=-1.0e100;
   bottom=1.0e100;
   for(int k=i+1;k<=i+InpRangeBars;k++)
     {
      if(hi[k]>top) top=hi[k];
      if(lo[k]<bottom) bottom=lo[k];
     }
  }

string ModeName()
  {
   if(InpMode==NCS_BREAKOUT) return "BREAKOUT";
   if(InpMode==NCS_SWEEP) return "SWEEP";
   return "AUTO";
  }

// NO repaint: one tiny label with current CLOSED-candle context only.
void UpdateDashboard(const string message)
  {
   const string key=g_prefix+"DASH";
   if(!InpShowDashboard)
     {
      if(ObjectFind(0,key)>=0) ObjectDelete(0,key);
      return;
     }
   if(ObjectFind(0,key)<0)
     {
      if(!ObjectCreate(0,key,OBJ_LABEL,0,0,0)) return;
      ObjectSetInteger(0,key,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
      ObjectSetInteger(0,key,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
      ObjectSetInteger(0,key,OBJPROP_XDISTANCE,12);
      ObjectSetInteger(0,key,OBJPROP_YDISTANCE,22);
      ObjectSetInteger(0,key,OBJPROP_COLOR,clrSilver);
      ObjectSetInteger(0,key,OBJPROP_FONTSIZE,9);
      ObjectSetInteger(0,key,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,key,OBJPROP_HIDDEN,true);
     }
   ObjectSetString(0,key,OBJPROP_TEXT,message);
  }

void Horizontal(const string name,const datetime t0,const datetime t1,
                const double price,const color col,const ENUM_LINE_STYLE style)
  {
   if(ObjectFind(0,name)>=0) return;
   if(!ObjectCreate(0,name,OBJ_TREND,0,t0,price,t1,price)) return;
   ObjectSetInteger(0,name,OBJPROP_COLOR,col);
   ObjectSetInteger(0,name,OBJPROP_STYLE,style);
   ObjectSetInteger(0,name,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
  }

// Last-plan view only: replace old plan when a new CLOSED candle confirms a signal.
// Arrows are stored in indicator buffers and are NEVER removed by plan cleanup.
void DrawLatestPlan(const datetime availableAt,const int direction,
                    const double entry,const double sl,const string kind)
  {
   const string prefix=g_prefix+"PLAN_";
   ObjectsDeleteAll(0,prefix,0,-1);
   if(InpView!=NCS_LAST_PLAN || direction==0) return;
   const double risk=(double)direction*(entry-sl);
   if(risk<=0.0) return;
   const datetime till=availableAt+12*PeriodSeconds(_Period);
   Horizontal(prefix+"ENTRY",availableAt,till,entry,clrDodgerBlue,STYLE_SOLID);
   Horizontal(prefix+"SL",availableAt,till,sl,clrFireBrick,STYLE_DASH);
   Horizontal(prefix+"TP1",availableAt,till,entry+direction*InpTP1R*risk,clrLimeGreen,STYLE_DOT);
   Horizontal(prefix+"TP2",availableAt,till,entry+direction*InpTP2R*risk,clrLimeGreen,STYLE_DOT);
   Horizontal(prefix+"TP3",availableAt,till,entry+direction*InpTP3R*risk,clrDarkGreen,STYLE_DOT);
   const string tag=prefix+"TEXT";
   if(ObjectCreate(0,tag,OBJ_TEXT,0,availableAt,entry))
     {
      ObjectSetString(0,tag,OBJPROP_TEXT,kind);
      ObjectSetInteger(0,tag,OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,tag,OBJPROP_COLOR,(direction>0 ? clrLimeGreen : clrTomato));
      ObjectSetInteger(0,tag,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,tag,OBJPROP_SELECTABLE,false);
     }
  }

int OnInit()
  {
   if(InpRangeBars<3 || InpRangeBars>300 ||
      InpATRPeriod<2 || InpERPeriod<2 || InpERPeriod>200 ||
      InpRangingER<0.0 || InpTrendingER>1.0 ||
      InpRangingER>=InpTrendingER ||
      InpMinBreakATR<0.0 || InpMinSweepATR<0.0 ||
      InpMinReclaimATR<0.0 ||
      InpMinBodyFraction<0.0 || InpMinBodyFraction>1.0 ||
      InpMinWickFraction<0.0 || InpMinWickFraction>1.0 ||
      InpMinScore<0.0 || InpMinScore>1.0 ||
      InpCooldownBars<0 || InpCooldownBars>100 ||
      InpMaxSpreadPoints<0 || InpStopBufferATR<0.0 ||
      InpTP1R<=0.0 || InpTP2R<=InpTP1R || InpTP3R<=InpTP2R ||
      InpMaxHistoryBars<100 || InpPlanMaxAgeBars<0)
      return INIT_PARAMETERS_INCORRECT;
   SetIndexBuffer(0,BuyBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SellBuffer,INDICATOR_DATA);
   ArraySetAsSeries(BuyBuffer,true);
   ArraySetAsSeries(SellBuffer,true);
   PlotIndexSetInteger(0,PLOT_ARROW,233);
   PlotIndexSetInteger(1,PLOT_ARROW,234);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   IndicatorSetString(INDICATOR_SHORTNAME,"Nexus Clean Signals NR 1.00");
   g_prefix="NCS_"+IntegerToString((long)ChartID())+"_";
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
   const int need=MathMax(InpRangeBars,
                  MathMax(InpATRPeriod+1,InpERPeriod+1));
   if(rates_total<need+10) return 0;
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(spread,true);

   const bool rebuild=(prev_calculated==0 || g_seenBarOpen==0);
   if(!rebuild && time[0]==g_seenBarOpen)
      return rates_total;
   const datetime previouslyClosed=g_lastClosed;
   g_seenBarOpen=time[0];
   if(rebuild)
     {
      ArrayInitialize(BuyBuffer,EMPTY_VALUE);
      ArrayInitialize(SellBuffer,EMPTY_VALUE);
      ObjectsDeleteAll(0,g_prefix,0,-1);
     }
   BuyBuffer[0]=EMPTY_VALUE;
   SellBuffer[0]=EMPTY_VALUE;
   const int oldest=MathMin(InpMaxHistoryBars,rates_total-need-1);
   int lastSignalIndex=-1;
   int directionLast=0;
   double lastEntry=0.0,lastStop=0.0,lastScore=0.0;
   string lastKind="NONE";
   bool currentBuy=false,currentSell=false;
   for(int i=oldest;i>=1;i--)
     {
      // Recompute past context for deterministic cooldown without rewriting old arrows.
      double top=0.0,bottom=0.0;
      PriorRange(i,high,low,top,bottom);
      const double atr=ATRBefore(i,rates_total,high,low,close);
      if(atr<=0.0 || top<=bottom)
        {
         if(rebuild || time[i]>previouslyClosed)
           {
            BuyBuffer[i]=EMPTY_VALUE;
            SellBuffer[i]=EMPTY_VALUE;
           }
         continue;
        }
      const double er=ERBefore(i,rates_total,close);
      const double candle=MathMax(high[i]-low[i],_Point);
      const double body=(close[i]-open[i])/candle;
      const double upperWick=high[i]-MathMax(open[i],close[i]);
      const double lowerWick=MathMin(open[i],close[i])-low[i];
      const bool allowBreak=(InpMode==NCS_BREAKOUT ||
                            (InpMode==NCS_AUTO && er>=InpRangingER));
      const bool allowSweep=(InpMode==NCS_SWEEP ||
                            (InpMode==NCS_AUTO && er<=InpTrendingER));
      int dir=0;
      string kind="";
      double score=0.0;
      // Breakout signals require a fully CLOSED candle beyond the PRIOR range.
      if(allowBreak && close[i]>top+InpMinBreakATR*atr &&
         body>=InpMinBodyFraction)
        {
         dir=1;kind="BREAKOUT";
         score=0.50*Clip01(body/0.65)+
               0.35*Clip01((close[i]-top)/(0.55*atr))+
               0.15*Clip01(er/0.6);
        }
      else if(allowBreak && close[i]<bottom-InpMinBreakATR*atr &&
              body<=-InpMinBodyFraction)
        {
         dir=-1;kind="BREAKOUT";
         score=0.50*Clip01((-body)/0.65)+
               0.35*Clip01((bottom-close[i])/(0.55*atr))+
               0.15*Clip01(er/0.6);
        }
      else if(allowSweep && low[i]<bottom-InpMinSweepATR*atr &&
              close[i]>bottom+InpMinReclaimATR*atr &&
              body>0.0 && lowerWick/candle>=InpMinWickFraction)
        {
         dir=1;kind="SWEEP";
         score=0.50*Clip01((lowerWick/candle)/0.6)+
               0.35*Clip01((close[i]-bottom)/(0.55*atr))+
               0.15*Clip01((1.0-er)/0.75);
        }
      else if(allowSweep && high[i]>top+InpMinSweepATR*atr &&
              close[i]<top-InpMinReclaimATR*atr &&
              body<0.0 && upperWick/candle>=InpMinWickFraction)
        {
         dir=-1;kind="SWEEP";
         score=0.50*Clip01((upperWick/candle)/0.6)+
               0.35*Clip01((top-close[i])/(0.55*atr))+
               0.15*Clip01((1.0-er)/0.75);
        }
      if(score<InpMinScore || (InpMaxSpreadPoints>0 && spread[i]>InpMaxSpreadPoints))
         dir=0;
      // Cooldown is an explicit presentation/entry policy, not fake hindsight.
      if(lastSignalIndex>=0 && (lastSignalIndex-i)<=InpCooldownBars)
         dir=0;

      if(rebuild || time[i]>previouslyClosed)
        {
         BuyBuffer[i]=EMPTY_VALUE;
         SellBuffer[i]=EMPTY_VALUE;
        }
      if(dir==0) continue;
      const double entry=close[i];
      const double sl=(dir==1 ? low[i]-InpStopBufferATR*atr :
                               high[i]+InpStopBufferATR*atr);
      const double risk=(double)dir*(entry-sl);
      if(risk<=2*_Point) continue;
      const double offset=MathMax(0.17*atr,3.0*_Point);
      // Write ONCE on routine bars. Rebuild allowed only on initial load/history reset.
      if(rebuild || time[i]>previouslyClosed)
        {
         if(dir==1) BuyBuffer[i]=low[i]-offset;
         else SellBuffer[i]=high[i]+offset;
         if(i==1 && !rebuild)
           {
            currentBuy=(dir==1);
            currentSell=(dir==-1);
           }
        }
      lastSignalIndex=i;
      directionLast=dir;
      lastEntry=entry;
      lastStop=sl;
      lastScore=score;
      lastKind=kind;
     }
   g_lastClosed=time[1];
   if(InpView==NCS_LAST_PLAN && lastSignalIndex>=1 &&
      lastSignalIndex<=InpPlanMaxAgeBars)
      // time[lastSignalIndex-1] is the opening time of the SUCCESSOR bar.
      DrawLatestPlan(time[lastSignalIndex-1],directionLast,
                     lastEntry,lastStop,lastKind);
   else
      ObjectsDeleteAll(0,g_prefix+"PLAN_",0,-1);
   const double currentER=ERBefore(1,rates_total,close);
   string state="WAIT";
   if(directionLast!=0)
     {
      const string age=(lastSignalIndex==1 ? "CONFIRMED " :
                        "LAST "+IntegerToString(lastSignalIndex)+" bars ago ");
      state=age+(directionLast>0 ? "BUY " : "SELL ")+lastKind+
            " "+DoubleToString(lastScore,2);
     }
   const string info="NEXUS CLEAN  |  "+_Symbol+"  |  "+ModeName()+
                     "  |  ER "+DoubleToString(currentER,2)+
                     "  |  "+state;
   UpdateDashboard(info);
   if(InpAlerts && !rebuild && (currentBuy||currentSell) &&
      g_lastAlerted!=time[1])
     {
      g_lastAlerted=time[1];
      Alert("Nexus Clean ",_Symbol," ",EnumToString(_Period)," ",
            (currentBuy ? "BUY" : "SELL")," ",lastKind,
            " confirmed on closed bar");
     }
   return rates_total;
  }
//+------------------------------------------------------------------+
