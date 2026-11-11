//+------------------------------------------------------------------+
//|                                   Liquidity_Entry_Signals.mq5     |
//|                                    Ultimate Trading Tools (UTT)   |
//|              Converted from Pine Script v6 (overlay indicator)    |
//|              Original: "Liquidity Entry Signals [MarkitTick]"     |
//|              (CC BY-NC-SA 4.0)  © MarkitTick                      |
//+------------------------------------------------------------------+
//  FIDELITY / DESIGN NOTES vs. Pine source:
//    - Liquidity sweeps:
//        Bearish (SHORT): high > highest(high[1],len) AND close < that
//                         high AND close < open  (buy-side liq grab + reject)
//        Bullish (LONG) : low  < lowest(low[1],len) AND close > that
//                         low  AND close > open  (sell-side liq grab + reject)
//    - Filters (all optional, all OFF by default to match Pine):
//        Trend (EMA Bias): Pine labels it "EMA" but computes ta.sma().
//                          Faithfully reproduced as SMA on close[i-1].
//        Volatility (ATR% of price), Volume (>= MA * mult),
//        Cooldown (min bars between signals), HTF Trend Alignment
//        (previous-closed HTF bar close vs HTF SMA -> non-repainting).
//    - Trade tools: entry = close; SL = swing +/- ATR*mult; TP1/2/3 by RR.
//    - Signals are CONFIRMED-bar only (Pine barstate.isconfirmed):
//        evaluated on the last CLOSED bar -> non-repainting by design.
//    - Only the MOST RECENT trade's levels/labels/zones are drawn (as in
//        Pine's f_deleteLevels()). Permanent arrow buffers additionally
//        mark EVERY historical signal (UTT enhancement for review).
//    - Alerts: popup / push / email / sound, plus optional JSON payloads
//        matching the Pine str.format() blocks (ready for a Telegram /
//        Deriv bridge). Fired once per closed bar; TPs latch once/trade.
//    - Mac MT5 conventions: fixed object prefix, explicit per-name deletion
//        loops (no ObjectsDeleteAll-by-prefix), no ArrayRemove.
//+------------------------------------------------------------------+
#property copyright "Ultimate Trading Tools (UTT)"
#property link      "https://t.me/binaryboss101"
#property version   "1.00"
#property description "Liquidity Entry Signals (SMC sweeps) - MarkitTick port."
#property description "ATR SL + 3 RR TPs, smart filters, dashboard, JSON alerts."

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

//--- Plot 1: Bullish sweep (LONG) arrow, below bar
#property indicator_label1  "Bull Sweep (Long)"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLimeGreen
#property indicator_width1  2

//--- Plot 2: Bearish sweep (SHORT) arrow, above bar
#property indicator_label2  "Bear Sweep (Short)"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrTomato
#property indicator_width2  2

//+------------------------------------------------------------------+
//| Enums / Inputs                                                    |
//+------------------------------------------------------------------+
enum ENUM_DASH_CORNER { DASH_TOP_RIGHT, DASH_TOP_LEFT, DASH_BOTTOM_RIGHT, DASH_BOTTOM_LEFT };

input group "=== SMC (Liquidity Sweeps) ==="
input bool   i_showLiq   = true;   // Show Liquidity Sweeps
input int    i_liqLen    = 10;     // Sweep Lookback (3-50)

input group "=== Smart Filters ==="
input bool   i_useTrendFilter  = false;  // Trend Filter (SMA Bias)
input int    i_trendLen        = 50;     // Trend SMA Len
input bool   i_useVolFilter    = false;  // Volatility Filter (ATR%)
input int    i_volAtrLen       = 14;     // Vol ATR Len
input double i_volMinPct        = 0.0;    // Vol Min % of Price
input bool   i_useVolumeFilter = false;  // Volume Filter
input int    i_volumeMALen     = 20;     // Volume MA Len
input double i_volumeMinMult    = 1.0;    // Volume Min x MA
input bool   i_useCooldown     = true;   // Signal Cooldown
input int    i_cooldownBars    = 5;      // Min Bars Between Signals
input bool   i_useHtfFilter    = false;  // HTF Trend Alignment
input ENUM_TIMEFRAMES i_htfTimeframe = PERIOD_H4; // HTF Timeframe
input int    i_htfEmaLen       = 50;     // HTF SMA Len

input group "=== Trade Tools ==="
input int    i_atrLen  = 14;     // ATR Len
input double i_slMult  = 0.50;   // SL ATR Mult
input double i_tp1RR   = 1.0;    // TP1 RR
input double i_tp2RR   = 2.0;    // TP2 RR
input double i_tp3RR   = 3.0;    // TP3 RR
input int    i_extendBars = 50;  // Extend levels (bars)

input group "=== Signal Markers ==="
input int    i_bullArrowCode = 233;  // Bull arrow (Wingdings)
input int    i_bearArrowCode = 234;  // Bear arrow (Wingdings)
input double i_arrowOffAtr    = 0.50; // Arrow offset (x ATR)

input group "=== Alerts (channels) ==="
input bool   InpAlertPopup = true;            // Popup alerts
input bool   InpAlertPush  = false;           // Push notifications
input bool   InpAlertEmail = false;           // Email alerts
input bool   InpAlertSound = false;           // Play sound
input string InpSoundFile  = "alert.wav";     // Sound file
input bool   i_alertOnTP   = true;            // Alert on TP hits
input string InpAlertPrefix = "MarkitTick SMC"; // Alert prefix

input group "=== Alerts (JSON payload) ==="
input bool   i_emitJSON = true;               // Append JSON payload to alert
input string i_actionLong       = "long";       // Long action
input string i_actionShort      = "short";      // Short action
input string i_actionCloseLong  = "closelong";  // Close-long action
input string i_actionCloseShort = "closeshort"; // Close-short action
input string i_actionTP1        = "tp1hit";     // TP1 hit action
input string i_actionTP2        = "tp2hit";     // TP2 hit action
input string i_actionTP3        = "tp3hit";     // TP3 hit action

input group "=== Dashboard ==="
input bool             i_showDash = true;            // Show Dashboard
input ENUM_DASH_CORNER i_dashPos  = DASH_TOP_RIGHT;  // Position
input int              i_dashX    = 12;              // X offset (px)
input int              i_dashY    = 18;              // Y offset (px)

input group "=== Colors ==="
input color  i_cLiqB   = C'0,200,100';   // Liq Sweep Bull
input color  i_cLiqS   = C'220,50,80';   // Liq Sweep Bear
input color  i_cSL     = C'239,83,80';   // SL Color
input color  i_cEntry  = C'33,150,243';  // Entry Color
input color  i_cTP1    = C'38,166,154';  // TP1 Color
input color  i_cTP2    = C'38,166,154';  // TP2 Color
input color  i_cTP3    = C'38,166,154';  // TP3 Color
input color  i_cRisk   = C'70,30,32';    // Risk Zone Fill
input color  i_cReward = C'22,48,44';    // Reward Zone Fill
input color  i_cDashBg    = C'10,15,26';  // Dash BG
input color  i_cDashHead  = C'20,181,203';// Dash Header BG
input color  i_cDashLabel = C'200,200,200';// Dash Label Text
input color  i_cDashValue = C'255,255,255';// Dash Value Text

//+------------------------------------------------------------------+
//| Buffers / handles / state                                         |
//+------------------------------------------------------------------+
double BullArrowBuf[];
double BearArrowBuf[];

int    h_trendSMA = INVALID_HANDLE;
int    h_atrTrade = INVALID_HANDLE;
int    h_volATR   = INVALID_HANDLE;
int    h_volMA    = INVALID_HANDLE;
int    h_htfSMA   = INVALID_HANDLE;

//--- signal / trade state (forward-index based; index 0 = oldest bar)
int      g_lastSignalBar = -1;
datetime g_lastSignalTime = 0;
bool     g_lastWasLong   = false;
double   g_lastEntry = 0.0, g_lastSL = 0.0, g_lastTP1 = 0.0, g_lastTP2 = 0.0, g_lastTP3 = 0.0;

//--- active-trade TP latches (fire each TP once per trade)
bool     g_tp1done = false, g_tp2done = false, g_tp3done = false;

//--- latest closed-bar snapshot (for dashboard)
double   g_lastAtr = 0.0, g_lastVolAtr = 0.0, g_lastVolume = 0.0, g_lastVolMA = 0.0;
bool     g_trendOkL = false, g_trendOkS = false, g_volOkCur = false, g_volumeOkCur = false;

//--- alert control
bool     g_firstRun = true;
datetime g_lastAlertBar = 0;

double   g_point = 0.0;

//--- object naming (fixed prefix -> Mac-safe explicit deletion)
string   PFX = "LES_";

//+------------------------------------------------------------------+
//| OnInit                                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, BullArrowBuf, INDICATOR_DATA);
   SetIndexBuffer(1, BearArrowBuf, INDICATOR_DATA);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(0, PLOT_ARROW, i_bullArrowCode);
   PlotIndexSetInteger(1, PLOT_ARROW, i_bearArrowCode);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, i_cLiqB);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, i_cLiqS);

   //--- indicator handles
   h_trendSMA = iMA(_Symbol, _Period, i_trendLen,    0, MODE_SMA, PRICE_CLOSE);
   h_atrTrade = iATR(_Symbol, _Period, i_atrLen);
   h_volATR   = iATR(_Symbol, _Period, i_volAtrLen);
   h_volMA    = iMA(_Symbol, _Period, i_volumeMALen, 0, MODE_SMA, VOLUME_TICK);
   h_htfSMA   = iMA(_Symbol, i_htfTimeframe, i_htfEmaLen, 0, MODE_SMA, PRICE_CLOSE);

   if(h_trendSMA==INVALID_HANDLE || h_atrTrade==INVALID_HANDLE ||
      h_volATR==INVALID_HANDLE   || h_volMA==INVALID_HANDLE    ||
      h_htfSMA==INVALID_HANDLE)
   {
      Print("[LES] Handle creation failed. Err=", GetLastError());
      return(INIT_FAILED);
   }

   g_point = _Point;

   //--- reset state
   g_lastSignalBar  = -1;
   g_lastSignalTime = 0;
   g_lastWasLong    = false;
   g_lastEntry = g_lastSL = g_lastTP1 = g_lastTP2 = g_lastTP3 = 0.0;
   g_tp1done = g_tp2done = g_tp3done = false;
   g_firstRun = true;
   g_lastAlertBar = 0;

   IndicatorSetString(INDICATOR_SHORTNAME,
      StringFormat("Liquidity Entry Signals (sweep %d, ATR %d)", i_liqLen, i_atrLen));
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| OnDeinit                                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(h_trendSMA!=INVALID_HANDLE) IndicatorRelease(h_trendSMA);
   if(h_atrTrade!=INVALID_HANDLE) IndicatorRelease(h_atrTrade);
   if(h_volATR!=INVALID_HANDLE)   IndicatorRelease(h_volATR);
   if(h_volMA!=INVALID_HANDLE)    IndicatorRelease(h_volMA);
   if(h_htfSMA!=INVALID_HANDLE)   IndicatorRelease(h_htfSMA);

   DeleteTradeLevels();
   DeleteDashboard();
}

//+------------------------------------------------------------------+
//| OnCalculate                                                       |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   int warmup = MathMax(i_liqLen, MathMax(i_trendLen, MathMax(i_atrLen,
                        MathMax(i_volAtrLen, i_volumeMALen)))) + 3;
   if(rates_total < warmup + 2) return(0);

   //--- source indicators ready?
   if(BarsCalculated(h_atrTrade) < rates_total) return(prev_calculated);
   if(i_useTrendFilter && BarsCalculated(h_trendSMA) < rates_total) return(prev_calculated);
   if(i_useVolFilter   && BarsCalculated(h_volATR)   < rates_total) return(prev_calculated);
   if(i_useVolumeFilter&& BarsCalculated(h_volMA)    < rates_total) return(prev_calculated);
   if(i_useHtfFilter   && BarsCalculated(h_htfSMA)   <= 0)          return(prev_calculated);

   int start = (prev_calculated==0) ? warmup : prev_calculated-1;

   //--- copy indicator buffers (forward-indexed, aligned to bars) ---
   int copy_from  = start - 1;
   if(copy_from < 0) copy_from = 0;
   int copy_count = rates_total - copy_from;

   double smaT[], atrT[], volA[], volM[];
   ArrayResize(smaT, copy_count); ArraySetAsSeries(smaT, false);
   ArrayResize(atrT, copy_count); ArraySetAsSeries(atrT, false);
   ArrayResize(volA, copy_count); ArraySetAsSeries(volA, false);
   ArrayResize(volM, copy_count); ArraySetAsSeries(volM, false);

   if(CopyBuffer(h_atrTrade, 0, 0, copy_count, atrT) < copy_count) return(prev_calculated);
   if(i_useTrendFilter  && CopyBuffer(h_trendSMA,0,0,copy_count,smaT)<copy_count) return(prev_calculated);
   if(i_useVolFilter    && CopyBuffer(h_volATR,  0,0,copy_count,volA)<copy_count) return(prev_calculated);
   if(i_useVolumeFilter && CopyBuffer(h_volMA,   0,0,copy_count,volM)<copy_count) return(prev_calculated);

   int lastClosed = rates_total - 2;   // most recent CONFIRMED bar

   //--- event flags for real-time alerting (last closed bar only)
   bool evLong=false, evShort=false, evTP1=false, evTP2=false, evTP3=false;

   //================= main loop ==================
   for(int i = start; i < rates_total; i++)
   {
      int j = i - copy_from;

      double atrVal = atrT[j];
      BullArrowBuf[i] = EMPTY_VALUE;
      BearArrowBuf[i] = EMPTY_VALUE;

      bool confirmed = (i <= lastClosed);
      if(!confirmed) continue;   // forming bar -> no signal (barstate.isconfirmed)

      //--- recent swing over previous i_liqLen bars (exclude current)
      double recentHigh = -DBL_MAX, recentLow = DBL_MAX;
      for(int k = i - i_liqLen; k <= i - 1; k++)
      {
         if(high[k] > recentHigh) recentHigh = high[k];
         if(low[k]  < recentLow ) recentLow  = low[k];
      }

      //--- sweeps
      bool bearSweep = (high[i] > recentHigh && close[i] < recentHigh && close[i] < open[i]); // SHORT
      bool bullSweep = (low[i]  < recentLow  && close[i] > recentLow  && close[i] > open[i]);  // LONG

      //--- trend filter (SMA on close[i-1])
      bool trendUp = false, trendDn = false;
      if(i_useTrendFilter)
      {
         double smaPrev = smaT[j-1];
         trendUp = (close[i-1] > smaPrev);
         trendDn = (close[i-1] < smaPrev);
      }
      bool trendOkLong  = (!i_useTrendFilter || trendUp);
      bool trendOkShort = (!i_useTrendFilter || trendDn);

      //--- HTF alignment (previous closed HTF bar) -> non-repainting
      bool htfOkLong = true, htfOkShort = true;
      if(i_useHtfFilter)
      {
         bool hUp=false, hDn=false;
         if(HtfBias(time[i], hUp, hDn))
         {
            htfOkLong  = hUp;
            htfOkShort = hDn;
         }
         else { htfOkLong = false; htfOkShort = false; } // data missing -> block
      }

      //--- volatility filter (ATR% of price)
      bool volOk = true;
      if(i_useVolFilter)
         volOk = (close[i] != 0.0) && (volA[j] / close[i] * 100.0 >= i_volMinPct);

      //--- volume filter
      bool volumeOk = true;
      if(i_useVolumeFilter)
         volumeOk = ((double)volume[i] >= volM[j] * i_volumeMinMult);

      //--- cooldown
      bool cooldownOk = (!i_useCooldown || g_lastSignalBar < 0 ||
                         (i - g_lastSignalBar) >= i_cooldownBars);

      //--- composite signals
      bool newShort = i_showLiq && bearSweep && trendOkShort && htfOkShort && volOk && volumeOk && cooldownOk;
      bool newLong  = i_showLiq && bullSweep && trendOkLong  && htfOkLong  && volOk && volumeOk && cooldownOk;

      //--- fire a signal (long takes precedence if both, which is rare)
      if(newLong || newShort)
      {
         bool isLong = newLong;

         double entry = close[i];
         double sl, tp1, tp2, tp3, riskDist;
         if(isLong)
         {
            sl  = low[i] - atrVal * i_slMult;
            riskDist = entry - sl;
            tp1 = entry + riskDist * i_tp1RR;
            tp2 = entry + riskDist * i_tp2RR;
            tp3 = entry + riskDist * i_tp3RR;
         }
         else
         {
            sl  = high[i] + atrVal * i_slMult;
            riskDist = sl - entry;
            tp1 = entry - riskDist * i_tp1RR;
            tp2 = entry - riskDist * i_tp2RR;
            tp3 = entry - riskDist * i_tp3RR;
         }

         //--- permanent arrow marker
         double off = atrVal * i_arrowOffAtr;
         if(isLong) BullArrowBuf[i] = low[i]  - off;
         else       BearArrowBuf[i] = high[i] + off;

         //--- update state (latest trade)
         g_lastSignalBar  = i;
         g_lastSignalTime = time[i];
         g_lastWasLong    = isLong;
         g_lastEntry = entry; g_lastSL = sl;
         g_lastTP1 = tp1; g_lastTP2 = tp2; g_lastTP3 = tp3;
         g_tp1done = g_tp2done = g_tp3done = false;

         //--- draw the (only) current level set
         DrawTradeLevels(time[i], entry, sl, tp1, tp2, tp3, isLong);

         if(i == lastClosed) { if(isLong) evLong = true; else evShort = true; }
      }

      //--- TP-hit tracking for the active trade (latch once each)
      if(g_lastSignalBar >= 0 && i >= g_lastSignalBar)
      {
         bool L = g_lastWasLong;
         bool hit1 = L ? (high[i] >= g_lastTP1) : (low[i] <= g_lastTP1);
         bool hit2 = L ? (high[i] >= g_lastTP2) : (low[i] <= g_lastTP2);
         bool hit3 = L ? (high[i] >= g_lastTP3) : (low[i] <= g_lastTP3);

         if(hit1 && !g_tp1done) { g_tp1done = true; if(i==lastClosed) evTP1 = true; }
         if(hit2 && !g_tp2done) { g_tp2done = true; if(i==lastClosed) evTP2 = true; }
         if(hit3 && !g_tp3done) { g_tp3done = true; if(i==lastClosed) evTP3 = true; }
      }

      //--- snapshot latest-closed values for dashboard
      if(i == lastClosed)
      {
         g_lastAtr    = atrVal;
         g_lastVolAtr = i_useVolFilter    ? volA[j] : SafeCopyLast(h_volATR);
         g_lastVolume = (double)volume[i];
         g_lastVolMA  = i_useVolumeFilter ? volM[j] : SafeCopyLast(h_volMA);
         g_trendOkL   = trendOkLong;
         g_trendOkS   = trendOkShort;
         g_volOkCur   = volOk;
         g_volumeOkCur= volumeOk;
      }
   }
   //================ end main loop ================

   //--- real-time alerts (never on initial history load)
   if(!g_firstRun && (evLong||evShort||evTP1||evTP2||evTP3))
   {
      datetime bt = time[lastClosed];
      string tf   = TFString(_Period);

      if(evLong)
         FireSignalAlert(true, tf);
      if(evShort)
         FireSignalAlert(false, tf);
      if(i_alertOnTP && evTP1) FireTPAlert(1, g_lastTP1, tf);
      if(i_alertOnTP && evTP2) FireTPAlert(2, g_lastTP2, tf);
      if(i_alertOnTP && evTP3) FireTPAlert(3, g_lastTP3, tf);

      g_lastAlertBar = bt;
   }

   if(i_showDash) UpdateDashboard(rates_total, time);

   if(g_firstRun) g_firstRun = false;
   return(rates_total);
}

//+------------------------------------------------------------------+
//| HTF bias: previous CLOSED HTF bar close vs HTF SMA                |
//+------------------------------------------------------------------+
bool HtfBias(datetime t, bool &up, bool &dn)
{
   int hs = iBarShift(_Symbol, i_htfTimeframe, t, false);
   if(hs < 0) return(false);
   int idx = hs + 1;                       // previous closed HTF bar (Pine close[1])

   double c = iClose(_Symbol, i_htfTimeframe, idx);
   if(c <= 0.0) return(false);

   double buf[];
   ArraySetAsSeries(buf, true);
   if(CopyBuffer(h_htfSMA, 0, idx, 1, buf) < 1) return(false);

   up = (c > buf[0]);
   dn = (c < buf[0]);
   return(true);
}

//+------------------------------------------------------------------+
//| Read last-closed value of a handle (shift 1)                      |
//+------------------------------------------------------------------+
double SafeCopyLast(int handle)
{
   double b[];
   ArraySetAsSeries(b, true);
   if(CopyBuffer(handle, 0, 1, 1, b) < 1) return(0.0);
   return(b[0]);
}

//+------------------------------------------------------------------+
//| Trade level drawing (single active trade)                         |
//+------------------------------------------------------------------+
void DrawTradeLevels(datetime t0, double entry, double sl,
                     double tp1, double tp2, double tp3, bool isLong)
{
   DeleteTradeLevels();

   datetime t1 = t0 + (datetime)(PeriodSeconds(_Period) * i_extendBars);

   //--- lines
   MakeTrend(PFX+"SL_LN",  t0, sl,    t1, sl,    i_cSL,    STYLE_SOLID,  2);
   MakeTrend(PFX+"EN_LN",  t0, entry, t1, entry, i_cEntry, STYLE_DASH,   1);
   MakeTrend(PFX+"TP1_LN", t0, tp1,   t1, tp1,   i_cTP1,   STYLE_DASH,   1);
   MakeTrend(PFX+"TP2_LN", t0, tp2,   t1, tp2,   i_cTP2,   STYLE_DASH,   1);
   MakeTrend(PFX+"TP3_LN", t0, tp3,   t1, tp3,   i_cTP3,   STYLE_DASH,   1);

   //--- labels at the right end
   MakeText(PFX+"SL_TX",  t1, sl,    "SL "    + DoubleToString(sl,_Digits),    i_cSL);
   MakeText(PFX+"EN_TX",  t1, entry, "Entry " + DoubleToString(entry,_Digits), i_cEntry);
   MakeText(PFX+"TP1_TX", t1, tp1,   "TP1 "   + DoubleToString(tp1,_Digits),   i_cTP1);
   MakeText(PFX+"TP2_TX", t1, tp2,   "TP2 "   + DoubleToString(tp2,_Digits),   i_cTP2);
   MakeText(PFX+"TP3_TX", t1, tp3,   "TP3 "   + DoubleToString(tp3,_Digits),   i_cTP3);

   //--- LS tag on the signal bar (at entry level)
   MakeText(PFX+"LS_TX", t0, entry, "LS", isLong ? i_cLiqB : i_cLiqS);

   //--- risk / reward zone fills
   MakeRect(PFX+"RISK_ZN",   t0, sl,    t1, entry, i_cRisk);
   MakeRect(PFX+"REWARD_ZN", t0, entry, t1, tp3,   i_cReward);
}

void DeleteTradeLevels()
{
   string names[] = {
      "SL_LN","EN_LN","TP1_LN","TP2_LN","TP3_LN",
      "SL_TX","EN_TX","TP1_TX","TP2_TX","TP3_TX",
      "LS_TX","RISK_ZN","REWARD_ZN"
   };
   for(int i=0; i<ArraySize(names); i++)
      ObjectDelete(0, PFX + names[i]);
}

//+------------------------------------------------------------------+
//| Object helpers                                                    |
//+------------------------------------------------------------------+
void MakeTrend(string name, datetime t1, double p1, datetime t2, double p2,
               color clr, int style, int width)
{
   if(ObjectFind(0,name) < 0)
      ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2);
   ObjectSetInteger(0, name, OBJPROP_TIME, 0, t1);
   ObjectSetDouble (0, name, OBJPROP_PRICE,0, p1);
   ObjectSetInteger(0, name, OBJPROP_TIME, 1, t2);
   ObjectSetDouble (0, name, OBJPROP_PRICE,1, p2);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void MakeText(string name, datetime t, double p, string txt, color clr)
{
   if(ObjectFind(0,name) < 0)
      ObjectCreate(0, name, OBJ_TEXT, 0, t, p);
   ObjectSetInteger(0, name, OBJPROP_TIME, 0, t);
   ObjectSetDouble (0, name, OBJPROP_PRICE,0, p);
   ObjectSetString (0, name, OBJPROP_TEXT, txt);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
   ObjectSetString (0, name, OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void MakeRect(string name, datetime t1, double p1, datetime t2, double p2, color clr)
{
   if(ObjectFind(0,name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, p1, t2, p2);
   ObjectSetInteger(0, name, OBJPROP_TIME, 0, t1);
   ObjectSetDouble (0, name, OBJPROP_PRICE,0, p1);
   ObjectSetInteger(0, name, OBJPROP_TIME, 1, t2);
   ObjectSetDouble (0, name, OBJPROP_PRICE,1, p2);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Alerts                                                            |
//+------------------------------------------------------------------+
bool AnyChannel() { return(InpAlertPopup||InpAlertPush||InpAlertEmail||InpAlertSound); }

void Dispatch(string subject, string body)
{
   if(!AnyChannel()) return;
   if(InpAlertPopup) Alert(body);
   if(InpAlertPush)  SendNotification(body);
   if(InpAlertEmail) SendMail(subject, body);
   if(InpAlertSound) PlaySound(InpSoundFile);
}

string LevelsJSON(string action, string dir)
{
   return StringFormat("{\"action\":\"%s\",\"ticker\":\"%s\",\"tf\":\"%s\",\"direction\":\"%s\",\"entry\":\"%s\",\"sl\":\"%s\",\"tp1\":\"%s\",\"tp2\":\"%s\",\"tp3\":\"%s\"}",
      action, _Symbol, TFString(_Period), dir,
      DoubleToString(g_lastEntry,_Digits),
      DoubleToString(g_lastSL,_Digits),
      DoubleToString(g_lastTP1,_Digits),
      DoubleToString(g_lastTP2,_Digits),
      DoubleToString(g_lastTP3,_Digits));
}

void FireSignalAlert(bool isLong, string tf)
{
   string dir  = isLong ? "LONG"  : "SHORT";
   string body = StringFormat("[%s] %s %s | %s sweep entry | E=%s SL=%s TP1=%s TP2=%s TP3=%s",
                    InpAlertPrefix, _Symbol, tf, dir,
                    DoubleToString(g_lastEntry,_Digits),
                    DoubleToString(g_lastSL,_Digits),
                    DoubleToString(g_lastTP1,_Digits),
                    DoubleToString(g_lastTP2,_Digits),
                    DoubleToString(g_lastTP3,_Digits));

   if(i_emitJSON)
   {
      string entryJSON = LevelsJSON(isLong ? i_actionLong : i_actionShort,
                                    isLong ? "long" : "short");
      string closeJSON = StringFormat("{\"action\":\"%s\",\"ticker\":\"%s\",\"tf\":\"%s\",\"direction\":\"%s\"}",
                                    isLong ? i_actionCloseShort : i_actionCloseLong,
                                    _Symbol, tf, isLong ? "short" : "long");
      body += " | " + entryJSON + " | " + closeJSON;
   }

   Dispatch(StringFormat("%s %s %s", InpAlertPrefix, dir, _Symbol), body);
}

void FireTPAlert(int n, double px, string tf)
{
   string act = (n==1)? i_actionTP1 : (n==2)? i_actionTP2 : i_actionTP3;
   string dir = g_lastWasLong ? "long" : "short";
   string body = StringFormat("[%s] %s %s | TP%d hit @ %s (%s)",
                    InpAlertPrefix, _Symbol, tf, n, DoubleToString(px,_Digits), dir);
   if(i_emitJSON)
      body += StringFormat(" | {\"action\":\"%s\",\"ticker\":\"%s\",\"tf\":\"%s\",\"direction\":\"%s\",\"tp\":\"%s\"}",
                 act, _Symbol, tf, dir, DoubleToString(px,_Digits));
   Dispatch(StringFormat("%s TP%d %s", InpAlertPrefix, n, _Symbol), body);
}

//+------------------------------------------------------------------+
//| Dashboard                                                         |
//+------------------------------------------------------------------+
#define DASH_ROWS   15
#define ROW_H       16
#define COL_LBL_W   118
#define COL_VAL_W   156
#define PAD          6
#define PANEL_W     (PAD + COL_LBL_W + COL_VAL_W + PAD)
#define PANEL_H     (PAD + (DASH_ROWS+1)*ROW_H + PAD)

void DashCornerFlags(bool &isRight, bool &isLower, ENUM_BASE_CORNER &corner)
{
   switch(i_dashPos)
   {
      case DASH_TOP_LEFT:     corner=CORNER_LEFT_UPPER;  isRight=false; isLower=false; break;
      case DASH_BOTTOM_RIGHT: corner=CORNER_RIGHT_LOWER; isRight=true;  isLower=true;  break;
      case DASH_BOTTOM_LEFT:  corner=CORNER_LEFT_LOWER;  isRight=false; isLower=true;  break;
      default:                corner=CORNER_RIGHT_UPPER; isRight=true;  isLower=false; break;
   }
}

void PanelBox(string name, int ix, int iy, int w, int h, color bg)
{
   bool isRight, isLower; ENUM_BASE_CORNER corner;
   DashCornerFlags(isRight, isLower, corner);

   int x = isRight ? (i_dashX + (PANEL_W - ix - w)) : (i_dashX + ix);
   int y = isLower ? (i_dashY + (PANEL_H - iy - h)) : (i_dashY + iy);

   if(ObjectFind(0,name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_COLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void PanelText(string name, int ix, int iy, string txt, color clr, string font="Tahoma", int fsize=8)
{
   bool isRight, isLower; ENUM_BASE_CORNER corner;
   DashCornerFlags(isRight, isLower, corner);

   int x = isRight ? (i_dashX + (PANEL_W - ix)) : (i_dashX + ix);
   int y = isLower ? (i_dashY + (PANEL_H - iy)) : (i_dashY + iy);

   if(ObjectFind(0,name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetString (0, name, OBJPROP_TEXT, txt);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetString (0, name, OBJPROP_FONT, font);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fsize);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

color BarColor(double pct)
{
   if(pct >= 0.66) return C'38,166,154';
   if(pct >= 0.33) return C'249,168,37';
   return C'239,83,80';
}

string AsciiBar(double val, double maxVal)
{
   double r = (maxVal>0.0) ? MathMin(val/maxVal, 1.0) : 0.0;
   if(r < 0) r = 0;
   int filled = (int)MathRound(r*10.0);
   string s = "[";
   for(int k=0;k<10;k++) s += (k<filled) ? "#" : "-";
   s += "] " + IntegerToString((int)MathRound(r*100.0)) + "%";
   return s;
}

string OnOff(bool used, bool ok) { return used ? (ok ? "Pass" : "Block") : "Off"; }
color  OnOffClr(bool used, bool ok){ return used ? (ok ? C'38,166,154' : C'239,83,80') : i_cDashLabel; }

void UpdateDashboard(const int rates_total, const datetime &time[])
{
   //--- background + header
   PanelBox(PFX+"DASH_BG", 0, 0, PANEL_W, PANEL_H, i_cDashBg);
   PanelBox(PFX+"DASH_HD", 0, 0, PANEL_W, ROW_H+PAD, i_cDashHead);
   PanelText(PFX+"DASH_TT", PAD, PAD-2, "  " + InpAlertPrefix, clrWhite, "Tahoma Bold", 9);

   int lastClosed = rates_total - 2;

   //--- current HTF bias (single lookup, independent of filter toggle)
   bool hUp=false, hDn=false; bool okHtf=false;
   if(lastClosed >= 0) okHtf = HtfBias(time[lastClosed], hUp, hDn);
   string biasTxt = (!okHtf) ? "N/A" : (hUp ? "Bull" : (hDn ? "Bear" : "Neutral"));
   color  biasClr = (!okHtf) ? i_cDashValue : (hUp ? C'38,166,154' : (hDn ? C'239,83,80' : i_cDashValue));

   bool has = (g_lastSignalBar >= 0);
   int  barsAgo = has ? (lastClosed - g_lastSignalBar) : -1;

   double riskPct   = (has && g_lastEntry!=0) ? MathAbs(g_lastEntry-g_lastSL)/g_lastEntry*100.0 : 0.0;
   double rewardPct = (has && g_lastEntry!=0) ? MathAbs(g_lastTP3-g_lastEntry)/g_lastEntry*100.0 : 0.0;
   double rr1 = (i_slMult!=0)? i_tp1RR/i_slMult : 0.0;
   double rr2 = (i_slMult!=0)? i_tp2RR/i_slMult : 0.0;
   double rr3 = (i_slMult!=0)? i_tp3RR/i_slMult : 0.0;
   double volRatio = (g_lastVolMA>0) ? g_lastVolume/g_lastVolMA : 0.0;
   double closePx  = (lastClosed>=0)? iClose(_Symbol,_Period,1) : 0.0;
   double volPct   = (closePx>0)? g_lastVolAtr/closePx*100.0 : 0.0;

   double cdRatio  = has ? MathMin(barsAgo/(i_cooldownBars*2.0),1.0) : 0.0;
   string dirTxt   = !has ? "-" : (g_lastWasLong ? "LONG" : "SHORT");
   color  dirClr   = !has ? i_cDashValue : (g_lastWasLong ? C'38,166,154' : C'239,83,80');

   //--- row writer
   int r = 0;
   DashRow(r++, "Bias",          biasTxt, biasClr);
   DashRow(r++, "Direction",     dirTxt, dirClr);
   DashRow(r++, "Last Signal",   has ? IntegerToString(barsAgo)+" bars ago" : "-", i_cDashValue);
   DashRowBar(r++, "Cooldown",   AsciiBar(has?barsAgo:0, i_cooldownBars*2.0), BarColor(cdRatio));
   DashRow(r++, "Entry",         has ? DoubleToString(g_lastEntry,_Digits) : "-", i_cDashValue);
   DashRow(r++, "Stop Loss",     has ? DoubleToString(g_lastSL,_Digits) : "-", i_cSL);
   DashRow(r++, "TP1/TP2/TP3",   has ? DoubleToString(g_lastTP1,_Digits)+" / "+DoubleToString(g_lastTP2,_Digits)+" / "+DoubleToString(g_lastTP3,_Digits) : "-", i_cTP3);
   DashRow(r++, "Risk %",        has ? DoubleToString(riskPct,2)+"%" : "-", i_cSL);
   DashRow(r++, "Reward %",      has ? DoubleToString(rewardPct,2)+"%" : "-", i_cTP3);
   DashRow(r++, "R:R (1/2/3)",   DoubleToString(rr1,2)+" / "+DoubleToString(rr2,2)+" / "+DoubleToString(rr3,2), i_cDashValue);
   DashRow(r++, "ATR",           DoubleToString(g_lastAtr,_Digits), i_cDashValue);
   DashRowBar(r++, "Volatility", AsciiBar(MathMin(volPct,5.0),5.0), BarColor(MathMin(volPct,5.0)/5.0));
   DashRow(r++, "Trend / HTF",   OnOff(i_useTrendFilter, g_trendOkL||g_trendOkS)+" / "+OnOff(i_useHtfFilter, okHtf && (hUp||hDn)), OnOffClr(i_useTrendFilter, g_trendOkL||g_trendOkS));
   DashRow(r++, "Vol / Volume",  OnOff(i_useVolFilter, g_volOkCur)+" / "+OnOff(i_useVolumeFilter, g_volumeOkCur), OnOffClr(i_useVolFilter, g_volOkCur));
   DashRow(r++, "Volume x MA",   (g_lastVolMA>0)? DoubleToString(volRatio,2)+"x" : "-", i_cDashValue);
}

void DashRow(int row, string label, string val, color valClr)
{
   int iy = PAD + (row+1)*ROW_H + 2;
   PanelText(PFX+"DASH_L"+IntegerToString(row), PAD, iy, label, i_cDashLabel);
   PanelText(PFX+"DASH_V"+IntegerToString(row), PAD+COL_LBL_W, iy, val, valClr);
}

void DashRowBar(int row, string label, string bar, color valClr)
{
   int iy = PAD + (row+1)*ROW_H + 2;
   PanelText(PFX+"DASH_L"+IntegerToString(row), PAD, iy, label, i_cDashLabel);
   PanelText(PFX+"DASH_V"+IntegerToString(row), PAD+COL_LBL_W, iy, bar, valClr, "Courier New", 8);
}

void DeleteDashboard()
{
   ObjectDelete(0, PFX+"DASH_BG");
   ObjectDelete(0, PFX+"DASH_HD");
   ObjectDelete(0, PFX+"DASH_TT");
   for(int r=0; r<DASH_ROWS; r++)
   {
      ObjectDelete(0, PFX+"DASH_L"+IntegerToString(r));
      ObjectDelete(0, PFX+"DASH_V"+IntegerToString(r));
   }
}

//+------------------------------------------------------------------+
//| Timeframe string                                                  |
//+------------------------------------------------------------------+
string TFString(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:  return "M1";   case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15";  case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";   case PERIOD_H4:  return "H4";
      case PERIOD_D1:  return "D1";   case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN1";  default: return EnumToString(tf);
   }
}
//+------------------------------------------------------------------+
