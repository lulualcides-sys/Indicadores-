//+------------------------------------------------------------------+
//| H1 Vector Factor M1 - Independent indicator inspired by the      |
//| public visual behavior of an hourly opening-range MT5 indicator. |
//| NOT source code or a proven signal-equivalent copy of Bull H1M1. |
//| For analytical/educational use; no orders are placed.            |
//+------------------------------------------------------------------+
#property copyright "Independent, original implementation - 2026"
#property version   "1.20"
#property description "NON-REPAINT: closed-candle H1 opening range, factor breakout/retest, permanent BUY/SELL arrows, TP/SL, alerts"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_label1  "BUY confirmed"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLimeGreen
#property indicator_width1  2
#property indicator_label2  "SELL confirmed"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrFireBrick
#property indicator_width2  2

// NO-REPAINT RULE: only completed bars (index >= 1) may trigger signals.
// Historical confirmed arrow buffer values are never overwritten on routine ticks.
// The opening range is defined by the first fully closed N M1 bars
// after the start of each hour, in broker server time.
input int    InpOpeningBars         = 3;     // M1 candles used to construct the opening range (1..10)
input int    InpATRPeriod           = 14;    // ATR bars, from PREVIOUS closed M1 candles
input int    InpMomentumBars        = 5;     // Lookback for momentum factor
input double InpMinBreakATR         = 0.08;  // Minimum breakout close beyond channel / ATR
input double InpMinScore            = 0.53;  // Factor weighted score threshold (0..1)
input double InpMinChannelATR       = 0.15;  // Smallest channel width relative to ATR
input double InpMaxChannelATR       = 4.00;  // Largest channel width relative to ATR
input double InpMaxExtensionChannel = 0.90;  // Cancel if price extends this many channel widths
input bool   InpRequireRetest       = true;  // Wait for pullback/retest instead of immediate signal
input double InpRetestToleranceATR  = 0.15;  // Distance to breakout level that counts as a touch
input int    InpRetestMaxMinutes    = 12;    // Cancel pending signal after N minutes
input int    InpLastEntryMinute     = 48;    // New candidates blocked after minute N of hour
input double InpTP1R                = 1.00;  // TP1 multiple of initial stop distance (R)
input double InpTP2R                = 1.50;  // TP2 multiple of R
input double InpTP3R                = 2.00;  // TP3 multiple of R
input double InpSLBufferATR         = 0.08;  // Stop outside opposite channel boundary, ATR multiple
input int    InpMaxSpreadPoints     = 0;     // 0=disabled; historical spread filter otherwise
input int    InpHistoryHours        = 10;    // Number of chart-hours shown (1..72)
input bool   InpShowCycleLevels     = true;  // Show 1st projected cycle for selected direction
input bool   InpAlerts             = false; // Alert once after closed-bar signal
input bool   InpDisplayLastScore   = true;  // Show candidate factor score next to signal

// These weights form a normalized feature vector (their sum is 1).
// Features: breakout magnitude, real-body quality, directional momentum,
// channel-to-volatility regime. They are ORIGINAL, not vendor formulas.
#define W_BREAK  0.30
#define W_BODY   0.25
#define W_TREND  0.30
#define W_REGIME 0.15

double BuyBuffer[];
double SellBuffer[];
string g_prefix;
datetime g_seenOpenBar=0;
datetime g_lastProcessedClosedBar=0;
datetime g_alertedBar=0;

//+------------------------------------------------------------------+
double Clamp01(const double x)
  {
   if(x<0.0) return 0.0;
   if(x>1.0) return 1.0;
   return x;
  }

// Computes ATR using bars STRICTLY OLDER than index i (series indices i+1,...).
// Therefore the signal never uses current bar or future price action.
double PreviousATR(const int i,const int total,
                   const double &hi[],const double &lo[],const double &cl[])
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

// Returns a factor-vector weighted dot product in [0, 1].
double FactorScore(const int i,const int dir,const double boundary,
                   const double range,const double atr,
                   const double &op[],const double &hi[],
                   const double &lo[],const double &cl[],
                   const int total)
  {
   if(atr<=0.0 || range<=0.0 || i+InpMomentumBars>=total) return 0.0;
   double beyond=(dir==1 ? cl[i]-boundary : boundary-cl[i]);
   double fb=Clamp01(beyond/(0.42*atr));
   double candle=MathMax(hi[i]-lo[i],_Point);
   double body=MathAbs(cl[i]-op[i])/candle;
   double fbody=Clamp01((body-0.25)/0.65);
   double momentum=(double)dir*(cl[i]-cl[i+InpMomentumBars]);
   double fm=Clamp01(momentum/(1.5*atr));
   // Regime score peaks around channel width=ATR, and tapers for extremes.
   double ratio=range/atr;
   double fregime=Clamp01(ratio/0.85)*Clamp01(1.85/ratio);
   return W_BREAK*fb+W_BODY*fbody+W_TREND*fm+W_REGIME*fregime;
  }

string SessionId(const datetime hourStart)
  {
   return g_prefix+IntegerToString((long)hourStart)+"_";
  }

void Segment(const string name,const datetime t0,const datetime t1,
             const double price,const color col,const ENUM_LINE_STYLE style,
             const int thickness=1)
  {
   if(!ObjectCreate(0,name,OBJ_TREND,0,t0,price,t1,price)) return;
   ObjectSetInteger(0,name,OBJPROP_COLOR,col);
   ObjectSetInteger(0,name,OBJPROP_STYLE,style);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,thickness);
   ObjectSetInteger(0,name,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
  }

void PriceText(const string name,const datetime when,const double price,
               const string label,const color col,const int fontsize=9)
  {
   if(!ObjectCreate(0,name,OBJ_TEXT,0,when,price)) return;
   ObjectSetString(0,name,OBJPROP_TEXT,label);
   ObjectSetString(0,name,OBJPROP_FONT,"Arial");
   ObjectSetInteger(0,name,OBJPROP_COLOR,col);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fontsize);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
  }

// terminal states: 0=looking, 1=awaiting retest, 2=BUY, 3=SELL, 4=cancelled
void RenderSession(const datetime hourStart,const bool ready,
                   const double highLine,const double lowLine,
                   const int status,const int direction,
                   const datetime breakoutTime,const datetime statusTime,
                   const datetime signalTime,const double entry,
                   const double tp1,const double tp2,const double tp3,
                   const double sl,const double candidateScore)
  {
   if(!ready || highLine<=lowLine) return;
   string id=SessionId(hourStart);
   datetime finish=hourStart+3600;
   // Opening-range levels must NOT be painted into the opening candles.
   // They only become visible after all N opening candles have closed.
   datetime availableAt=hourStart+InpOpeningBars*60;
   datetime labelTime=availableAt+60;
   double width=highLine-lowLine;
   Segment(id+"OPEN_HIGH",availableAt,finish,highLine,clrForestGreen,STYLE_SOLID,2);
   Segment(id+"OPEN_LOW", availableAt,finish,lowLine,clrForestGreen,STYLE_SOLID,2);
   Segment(id+"MID",      availableAt,finish,(highLine+lowLine)*0.5,clrSeaGreen,STYLE_DOT,1);
   PriceText(id+"H_TXT",labelTime,highLine,"Canal de Abertura",clrForestGreen,9);
   PriceText(id+"L_TXT",labelTime,lowLine,"Canal de Abertura",clrForestGreen,9);
   PriceText(id+"M_TXT",labelTime,(highLine+lowLine)*0.5,"Canal Fatiado",clrSeaGreen,8);

   if(InpShowCycleLevels && direction!=0)
     {
      double projected=(direction==1 ? highLine+width : lowLine-width);
      datetime cycleAt=(breakoutTime>0 ? breakoutTime+60 : availableAt);
      if(cycleAt<finish)
        {
         Segment(id+"CYCLE",cycleAt,finish,projected,clrDarkSeaGreen,STYLE_DOT,1);
         PriceText(id+"CYCLE_TXT",cycleAt,projected,"Primeiro Ciclo",clrForestGreen,8);
        }
     }

   // Only the pending notice may disappear when its setup resolves.
   if(status!=1) ObjectDelete(0,id+"PENDING");
   if(status==1)
     {
      double p=(direction==1 ? highLine+0.45*width : lowLine-0.45*width);
      datetime pendingAt=(breakoutTime>0 ? breakoutTime+60 : availableAt);
      PriceText(id+"PENDING",pendingAt,p,"AGUARDANDO PULLBACK",clrDarkOrange,10);
     }
   else if(status==4)
     {
      double p=(direction>=0 ? highLine+0.45*width : lowLine-0.45*width);
      datetime cancelledAt=(statusTime>0 ? statusTime+60 : availableAt);
      PriceText(id+"CANCEL",cancelledAt,p,"X CANCELADO",clrFireBrick,11);
     }
   else if(status==2 || status==3)
     {
      bool buy=(status==2);
      color c=(buy ? clrLimeGreen : clrFireBrick);
      // Signal exists only after its candle CLOSED. No historical TP/SL backfill.
      datetime labelAt=(signalTime>0 ? signalTime+60 : availableAt);
      PriceText(id+"SIGNAL",labelAt,entry+(buy ? 0.22*width : -0.22*width),
                (buy ? "BUY" : "SELL"),c,12);
      Segment(id+"TP1",labelAt,finish,tp1,clrLimeGreen,STYLE_DASH,1);
      Segment(id+"TP2",labelAt,finish,tp2,clrLimeGreen,STYLE_DOT,1);
      Segment(id+"TP3",labelAt,finish,tp3,clrDarkGreen,STYLE_DOT,1);
      Segment(id+"SL",labelAt,finish,sl,clrFireBrick,STYLE_DASH,1);
      PriceText(id+"TP1_TXT",labelAt,tp1,"TP1 / 1R",clrLimeGreen,9);
      PriceText(id+"TP2_TXT",labelAt,tp2,"TP2 / 1.5R",clrLimeGreen,9);
      PriceText(id+"TP3_TXT",labelAt,tp3,"TP3 / 2R",clrDarkGreen,9);
      PriceText(id+"SL_TXT",labelAt,sl,"SL",clrFireBrick,11);
      if(InpDisplayLastScore)
         PriceText(id+"SCORE",labelAt,entry+(buy ? -0.25*width : 0.25*width),
                   "Vector " + DoubleToString(candidateScore,2),c,8);
     }
  }

int OnInit()
  {
   if(InpOpeningBars<1 || InpOpeningBars>10 || InpATRPeriod<2 ||
      InpMomentumBars<1 || InpHistoryHours<1 || InpHistoryHours>72 ||
      InpRetestMaxMinutes<1 || InpLastEntryMinute<InpOpeningBars+1 ||
      InpLastEntryMinute>59 || InpMinScore<0.0 || InpMinScore>1.0 ||
      InpMinChannelATR<=0.0 || InpMaxChannelATR<=InpMinChannelATR ||
      InpMaxExtensionChannel<=0.0 || InpTP1R<=0.0 ||
      InpTP2R<=InpTP1R || InpTP3R<=InpTP2R ||
      InpMinBreakATR<0.0 || InpRetestToleranceATR<0.0 ||
      InpSLBufferATR<0.0 || InpMaxSpreadPoints<0)
     {
      Print("H1 Vector Factor: invalid input parameters");
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
   IndicatorSetString(INDICATOR_SHORTNAME,"H1 Vector Factor M1 1.20 NR");
   g_prefix="HVF_"+IntegerToString(ChartID())+"_";
   if(_Period!=PERIOD_M1)
      Print("H1 Vector Factor: open the M1 timeframe. The indicator is inactive on other periods.");
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0,g_prefix,0,-1);
   ChartRedraw(0);
  }

int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],
                const double &high[],const double &low[],
                const double &close[],const long &tick_volume[],
                const long &volume[],const int &spread[])
  {
   if(rates_total<InpATRPeriod+InpMomentumBars+InpOpeningBars+5)
      return 0;
   if(_Period!=PERIOD_M1) return rates_total;
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(spread,true);

   // Do not process the forming candle. All entries are confirmed at its successor's open.
   // MT5 sets prev_calculated=0 when broker history is changed/filled.
   bool fullRebuild=(prev_calculated==0 || g_seenOpenBar==0);
   if(!fullRebuild && time[0]==g_seenOpenBar)
      return rates_total;
   datetime lastClosedBeforePass=g_lastProcessedClosedBar;
   g_seenOpenBar=time[0];
   if(fullRebuild)
     {
      // Historical reconstruction ONLY on initial load or broker-history reset.
      // This can legitimately differ if the broker revises OHLC data.
      ArrayInitialize(BuyBuffer,EMPTY_VALUE);
      ArrayInitialize(SellBuffer,EMPTY_VALUE);
      ObjectsDeleteAll(0,g_prefix,0,-1);
      lastClosedBeforePass=0;
     }
   // Never write an arrow to bar index 0 (the live, incomplete M1 candle).
   BuyBuffer[0]=EMPTY_VALUE;
   SellBuffer[0]=EMPTY_VALUE;

   // Extra hour beyond the visible period permits clean session transitions.
   datetime minTime=time[1]-(InpHistoryHours+1)*3600;
   int oldest=1;
   while(oldest<rates_total-1 && time[oldest]>=minTime)
      oldest++;

   datetime currentHour=0;
   int collected=0;           // exact opening bars collected (no gap)
   bool openingValid=true;
   double upper=0.0,lower=0.0;
   int state=0,dir=0;
   datetime breakoutTime=0,statusTime=0,signalTime=0;
   double entry=0.0,tp1=0.0,tp2=0.0,tp3=0.0,sl=0.0;
   double candidateScore=0.0;
   bool retestTouched=false;
   bool latestBuy=false,latestSell=false;

   // Historical reconstruction from oldest closed M1 bar to newest closed M1 bar.
   // This does not depend on future candles and does not repaint confirmed signals.
   for(int i=oldest;i>=1;i--)
     {
      // Empty buffers for *new* closed bars only; never touch older markers.
      if(!fullRebuild && time[i]>lastClosedBeforePass)
        {
         BuyBuffer[i]=EMPTY_VALUE;
         SellBuffer[i]=EMPTY_VALUE;
        }
      datetime h=(datetime)(((long)time[i]/3600)*3600);
      if(currentHour!=h)
        {
         if(currentHour>0 && currentHour>=time[1]-InpHistoryHours*3600)
            RenderSession(currentHour,collected==InpOpeningBars && openingValid,
                          upper,lower,state,dir,breakoutTime,statusTime,
                          signalTime,entry,tp1,tp2,tp3,sl,candidateScore);
         currentHour=h;
         collected=0;
         openingValid=true;
         upper=-1.0e100;
         lower=1.0e100;
         state=0;
         dir=0;
         breakoutTime=0;
         statusTime=0;
         signalTime=0;
         retestTouched=false;
         entry=tp1=tp2=tp3=sl=0.0;
         candidateScore=0.0;
        }

      int minute=(int)((time[i]-h)/60);
      if(minute<InpOpeningBars)
        {
         // No channel if the broker has missing opening minute(s).
         if(minute!=collected) openingValid=false;
         upper=MathMax(upper,high[i]);
         lower=MathMin(lower,low[i]);
         collected++;
         continue;
        }
      if(!openingValid || collected!=InpOpeningBars) continue;
      double range=upper-lower;
      if(range<_Point) continue;
      if(state==2 || state==3 || state==4) continue;

      // An expired retest must be cancelled even when spread/volatility
      // would prevent processing the current candle.
      if(state==1 &&
         ((int)((time[i]-breakoutTime)/60)>InpRetestMaxMinutes ||
          minute>InpLastEntryMinute))
        {state=4;statusTime=time[i];continue;}

      double atr=PreviousATR(i,rates_total,high,low,close);
      if(atr<=0.0) continue;
      double normalizedRange=range/atr;
      if(normalizedRange<InpMinChannelATR ||
         normalizedRange>InpMaxChannelATR)
         continue;
      if(InpMaxSpreadPoints>0 && spread[i]>InpMaxSpreadPoints)
         continue;

      if(state==0)
        {
         if(minute>InpLastEntryMinute) continue;
         int d=0;
         if(close[i]>upper+InpMinBreakATR*atr) d=1;
         else if(close[i]<lower-InpMinBreakATR*atr) d=-1;
         if(d==0) continue;
         double extension=(d==1 ? close[i]-upper : lower-close[i]);
         if(extension>InpMaxExtensionChannel*range)
           {
            dir=d;
            statusTime=time[i];
            breakoutTime=time[i];
            state=4; // Cancel overextended breakout / anti-FOMO
            continue;
           }
         double score=FactorScore(i,d,(d==1 ? upper : lower),range,atr,
                                  open,high,low,close,rates_total);
         if(score<InpMinScore) continue; // Candidate rejected, no pending state
         dir=d;
         breakoutTime=time[i];
         candidateScore=score;
         if(!InpRequireRetest)
           {
            entry=close[i];
            sl=(d==1 ? lower-InpSLBufferATR*atr : upper+InpSLBufferATR*atr);
            double risk=(double)d*(entry-sl);
            if(risk<=0.0) {state=4;statusTime=time[i];continue;}
            tp1=entry+(double)d*InpTP1R*risk;
            tp2=entry+(double)d*InpTP2R*risk;
            tp3=entry+(double)d*InpTP3R*risk;
            signalTime=time[i];
            statusTime=time[i];
            state=(d==1 ? 2 : 3);
            double offset=MathMax(0.15*atr,3*_Point);
            // Historical signal values are write-once on routine recalculations.
            if(fullRebuild || time[i]>lastClosedBeforePass)
              {
               if(d==1) BuyBuffer[i]=low[i]-offset;
               else     SellBuffer[i]=high[i]+offset;
               if(i==1 && !fullRebuild)
                 {latestBuy=(d==1);latestSell=(d==-1);}
              }
            continue;
           }
         state=1;
         statusTime=time[i];
         breakoutTime=time[i];
         retestTouched=false;
         continue;
        }

      if(state==1)
        {
         if((int)((time[i]-breakoutTime)/60)>InpRetestMaxMinutes ||
            minute>InpLastEntryMinute)
           {state=4;statusTime=time[i];continue;}
         // A close deep INSIDE the channel invalidates the candidate.
         if((dir==1 && close[i]<upper-0.35*range) ||
            (dir==-1 && close[i]>lower+0.35*range))
           {state=4;statusTime=time[i];continue;}
         if((dir==1 && high[i]>upper+InpMaxExtensionChannel*range) ||
            (dir==-1 && low[i]<lower-InpMaxExtensionChannel*range))
           {state=4;statusTime=time[i];continue;}
         double boundary=(dir==1 ? upper : lower);
         if((dir==1 && low[i]<=boundary+InpRetestToleranceATR*atr) ||
            (dir==-1 && high[i]>=boundary-InpRetestToleranceATR*atr))
            retestTouched=true;

         bool confirmed=retestTouched &&
                        ((dir==1 && close[i]>upper+InpMinBreakATR*atr*0.40 && close[i]>open[i]) ||
                         (dir==-1 && close[i]<lower-InpMinBreakATR*atr*0.40 && close[i]<open[i]));
         if(!confirmed) continue;
         entry=close[i];
         sl=(dir==1 ? lower-InpSLBufferATR*atr : upper+InpSLBufferATR*atr);
         double risk=(double)dir*(entry-sl);
         if(risk<=0.0) {state=4;statusTime=time[i];continue;}
         tp1=entry+(double)dir*InpTP1R*risk;
         tp2=entry+(double)dir*InpTP2R*risk;
         tp3=entry+(double)dir*InpTP3R*risk;
         signalTime=time[i];
         statusTime=time[i];
         state=(dir==1 ? 2 : 3);
         double offset=MathMax(0.15*atr,3*_Point);
         if(fullRebuild || time[i]>lastClosedBeforePass)
           {
            if(dir==1) BuyBuffer[i]=low[i]-offset;
            else       SellBuffer[i]=high[i]+offset;
            if(i==1 && !fullRebuild)
              {latestBuy=(dir==1);latestSell=(dir==-1);}
           }
        }
     }
   if(currentHour>0 && currentHour>=time[1]-InpHistoryHours*3600)
      RenderSession(currentHour,collected==InpOpeningBars && openingValid,
                    upper,lower,state,dir,breakoutTime,statusTime,
                    signalTime,entry,tp1,tp2,tp3,sl,candidateScore);

   g_lastProcessedClosedBar=time[1];

   // Alerts are never fired during initial historical load/history reset.
   if(InpAlerts && prev_calculated>0 && (latestBuy || latestSell) &&
      g_alertedBar!=time[1])
     {
      g_alertedBar=time[1];
      Alert("H1 Vector Factor ",_Symbol," M1 ",
            (latestBuy ? "BUY" : "SELL")," confirmed at ",
            DoubleToString(close[1],_Digits));
     }
   ChartRedraw(0);
   return rates_total;
  }
//+------------------------------------------------------------------+