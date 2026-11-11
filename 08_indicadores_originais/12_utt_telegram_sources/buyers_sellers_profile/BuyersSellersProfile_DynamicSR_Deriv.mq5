//+------------------------------------------------------------------+
//|                        BuyersSellersProfile_DynamicSR_Deriv.mq5  |
//|   Buyers & Sellers Profile + Dynamic S/R (Zeiierman) -> MQL5     |
//|   DERIV SYNTHETIC-INDEX EDITION  v2.0  |  Ultimate Trading Tools  |
//|   Original Pine v6 (c) Zeiierman, CC BY-NC-SA 4.0                |
//+------------------------------------------------------------------+
//  What is different from the plain port (all switchable):
//   1. SUB-BAR PROFILE  - the rolling profile is built from lower-TF
//      candles (auto M1/M5/M15) so the price distribution inside each
//      chart candle is real, and buy/sell share is estimated per sub-bar.
//   2. ACTIVITY VOLUME  - on Deriv synthetics tick volume is constant
//      (one tick per 1s/2s), so "volume" carries no information. The
//      engine uses PATH ACTIVITY (range + body of every sub-bar) as the
//      volume weight and for the pivot volume / absorption features.
//   3. MARKET AUTO-PROFILE - the symbol's own parameters (Volatility %,
//      tick interval, Boom/Crash/Step/Jump/Range Break/DEX) are read from
//      the MT5 symbol description (the same figures Deriv's API publishes)
//      and used to scale Search / Merge / Break ATR, with an asymmetric
//      break buffer on the spike side of Boom / Crash.
//   4. TIME-BASED LOOKBACK - the profile window is set in minutes and
//      converted to bars per timeframe, so it means the same thing on
//      every chart.
//   5. UTT LEVEL RELIABILITY - every retest of an active level is
//      recorded as HELD or BROKE, by score band and side, and shown on a
//      UTT-branded dashboard with a plain-English bias line.
//   6. No-blink guard for 1s indices; market-switch re-init.
//+------------------------------------------------------------------+
#property copyright   "Ultimate Trading Tools | engine ported from Pine Script by Zeiierman (CC BY-NC-SA 4.0)"
#property link        "https://ultimatetrading.tools"
#property version     "2.10"
#property description "UTT Buyers & Sellers Profile + Dynamic S/R - Deriv edition: sub-bar profile, activity volume,"
#property description "auto market profile, time-based lookback, Level Reliability dashboard."
#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   6
#property indicator_label1  "Nearest Support"
#property indicator_type1   DRAW_NONE
#property indicator_label2  "Nearest Resistance"
#property indicator_type2   DRAW_NONE
#property indicator_label3  "Profile POC"
#property indicator_type3   DRAW_NONE
#property indicator_label4  "Value Area High"
#property indicator_type4   DRAW_NONE
#property indicator_label5  "Value Area Low"
#property indicator_type5   DRAW_NONE
#property indicator_label6  "Activity (effective volume)"
#property indicator_type6   DRAW_NONE

//+------------------------------------------------------------------+
//| INPUTS                                                           |
//+------------------------------------------------------------------+
enum ENUM_LSTYLE   { LS_SOLID = 0, LS_DOTTED = 1, LS_DASHED = 2 };
enum ENUM_VOLSRC   { VS_AUTO = 0, VS_ACTIVITY = 1, VS_TICK = 2, VS_REAL = 3 };
enum ENUM_SUBTF    { ST_AUTO = 0, ST_OFF = 1, ST_M1 = 2, ST_M5 = 3, ST_M15 = 4 };
enum ENUM_LBMODE   { LB_MINUTES = 0, LB_BARS = 1 };

input group "Deriv Adaptation"
input bool   InpAutoAdapt     = true;       // Auto-adapt thresholds to the detected market
input ENUM_VOLSRC InpVolSrc   = VS_AUTO;    // Volume weight: Auto (activity on synthetics) / Activity / Tick / Real
input ENUM_SUBTF InpSubTf     = ST_AUTO;    // Sub-bar profile source: Auto / Off (chart bars) / M1 / M5 / M15
input ENUM_LBMODE InpLbMode   = LB_MINUTES; // Lookback mode: minutes (auto bars per TF) / bars
input int    InpLookbackMin   = 9000;       // Lookback (minutes)  [9000 = 600 x M15]
input int    InpProfLb        = 600;        // Lookback (bars, when mode = bars)

input group "Large Rolling Profile"
input int    InpProfRows    = 72;    // Rows (24-100)
input int    InpProfW       = 58;    // Width (bars)
input int    InpProfOff     = 8;     // Offset (bars)
input bool   InpShowProf    = true;  // Show Profile
input bool   InpShowPoc     = true;  // POC
input bool   InpShowLvlRows = true;  // Level Rows
input int    InpVaPct       = 70;    // Value Area %

input group "Profile-Guided Pivot Engine"
input int    InpSwingLen    = 5;     // Swing Length (2-25)
input double InpSrchAtr     = 1.20;  // Search ATR
input double InpNodeMin     = 0.08;  // Min Node
input double InpEvidMin     = 0.22;  // Min Evidence
input double InpPullMax     = 0.85;  // Profile Pull
input double InpScoreMin    = 30.0;  // Min Score
input int    InpMaxLvl      = 20;    // Max Levels
input double InpMergeAtr    = 0.16;  // Merge ATR
input double InpBreakAtr    = 0.10;  // Break ATR

input group "Level Reliability (retest tracker)"
input double InpTouchAtr    = 0.15;  // Retest band (ATR) around a level
input double InpHoldAtr     = 0.50;  // Reaction needed to count as HELD (ATR away from the level)
input int    InpRetestTimeout = 20;  // Bars before an unresolved retest is dropped

input group "Visual Style"
input color  InpSupCol   = C'31,199,116';   // Support
input color  InpResCol   = C'239,75,75';    // Resistance
input color  InpCoreCol  = C'255,205,64';   // Pivot Core
input color  InpRawCol   = C'160,166,178';  // Raw Pivot
input color  InpBuyCol   = C'43,158,143';   // Profile Buy
input color  InpSellCol  = C'74,88,182';    // Profile Sell
input color  InpPocCol   = C'255,145,32';   // POC
input color  InpVaCol    = C'120,130,150';  // Value Area
input ENUM_LSTYLE InpLvlStyle = LS_SOLID;   // Line Style
input bool   InpShowDots     = true;  // Pivot Dots
input bool   InpShowRaw      = true;  // Raw Pivot
input bool   InpShowDotScore = true;  // Dot Score
input bool   InpShowEdge     = true;  // Right Score
input bool   InpShowVA       = true;  // Value Area lines

input group "UTT Dashboard"
input bool   InpShowDash     = true;             // Show UTT dashboard
input ENUM_BASE_CORNER InpDashCorner = CORNER_LEFT_UPPER; // Corner
input int    InpDashX        = 10;               // X offset (px)
input int    InpDashY        = 22;               // Y offset (px)
input int    InpDashFont     = 8;                // Font size
input color  InpDashBrand    = C'255,205,64';    // Brand colour
input color  InpDashText     = clrWhite;         // Text colour
input color  InpDashMuted    = C'156,163,175';   // Muted colour

input group "MT5 Engine"
input int    InpMaxHistory   = 5000;  // Bars of history to process
input int    InpRedrawMs     = 1000;  // Min ms between live redraws
input bool   InpAutoBackground = true; // Blend against chart background
input color  InpBackgroundCol  = clrBlack; // Manual background colour

input group "Alerts"
input bool   InpAlertNewLevel = true;  // Alert: new profile-confirmed support / resistance
input bool   InpAlertBreak    = true;  // Alert: support / resistance broken
input bool   InpAlertRetest   = false; // Alert: price retesting a level (band entry)
input bool   InpAlertPopup    = true;  // Popup
input bool   InpAlertPush     = false; // Push notification
input bool   InpAlertSound    = false; // Sound
input string InpSoundFile     = "alert.wav";

//+------------------------------------------------------------------+
//| CONSTANTS / TYPES                                                |
//+------------------------------------------------------------------+
#define VOL_LEN      40
#define PIV_VOL_X    2.2
#define ABS_BODY_MAX 0.40
#define ABS_VOL_X    1.5
#define ATR_NORM_LEN 200

enum ENUM_MKT { MKT_OTHER = 0, MKT_VOL_CALM, MKT_VOL_MID, MKT_VOL_FAST, MKT_BOOM, MKT_CRASH, MKT_STEP, MKT_JUMP, MKT_RANGEBREAK, MKT_DEX };

struct Lvl
  {
   int      id;
   double   p, sc, raw, node, evid, nStr;
   bool     supp;
   datetime born;
   int      bornBar;
   int      holds, breaks;
   bool     inRetest;
   int      retestStart;
  };

//+------------------------------------------------------------------+
//| STATE                                                            |
//+------------------------------------------------------------------+
Lvl      g_lv[];
int      g_nextId = 1;
double   SupBuf[], ResBuf[], PocBuf[], VahBuf[], ValBuf[], ActBuf[], AvgVolBuf[], AtrBuf[];
int      hAtr = INVALID_HANDLE;
int      g_absRad = 3;
int      g_lastProcessed = -1, g_prevRates = 0, g_ratesTotal = 0;
datetime g_lastTime = 0, g_firstBarTime = 0, g_lastProcessedTime = 0;
bool     g_liveMode = false;
uint     g_lastRedraw = 0;
datetime g_lastRedrawBar = 0;
bool     g_dirty = true;
int      g_nDraw = 0, g_maxDraw = 0, g_atrWait = 0, g_subWait = 0;
string   g_prefix;
color    g_bg;
double   g_tick;
string   SYM_DOT;

// market profile
ENUM_MKT g_mkt = MKT_OTHER;
bool     g_isSynthetic = false;
double   g_volPct = 0.0;          // Deriv constant volatility %
int      g_tickSec = 0;           // tick interval in seconds (1 / 2), 0 = unknown
string   g_mktName = "";
double   g_mSrch = 1.0, g_mMerge = 1.0, g_mBreakSup = 1.0, g_mBreakRes = 1.0;
int      g_profLb = 600;
bool     g_useActivity = true;

// sub-bar cache (per chart bar index)
ENUM_TIMEFRAMES g_subTf = PERIOD_M1;
bool     g_useSub = true;
int      g_subStart[], g_subCount[];
double   g_subL[], g_subH[], g_subO[], g_subC[], g_subW[];
int      g_subTotal = 0;
int      g_subLoadedTo = -1;      // last chart bar index whose sub-bars are cached

// reliability counters: index = side(0 sup,1 res)*3 + band(0: 80+, 1: 60-79, 2: <60)
int      g_relHold[6], g_relBreak[6];
double   g_poc = 0, g_vah = 0, g_val = 0;
int      g_lastAlertBar = -1;

//+------------------------------------------------------------------+
//| HELPERS                                                          |
//+------------------------------------------------------------------+
string S(const int v) { return IntegerToString(v); }
string Px(const double v) { return DoubleToString(v, _Digits); }
double Clip(const double x) { return MathMax(0.0, MathMin(1.0, x)); }
int    Band(const double sc) { return sc >= 80 ? 0 : sc >= 60 ? 1 : 2; }

color Blend(const color c, const int transparency)
  {
   if(transparency <= 0)   return(c);
   if(transparency >= 100) return(g_bg);
   double t = transparency / 100.0;
   int ci = (int)c, bi = (int)g_bg;
   int r = (int)MathRound((ci & 0xFF) * (1.0 - t) + (bi & 0xFF) * t);
   int g = (int)MathRound(((ci >> 8) & 0xFF) * (1.0 - t) + ((bi >> 8) & 0xFF) * t);
   int b = (int)MathRound(((ci >> 16) & 0xFF) * (1.0 - t) + ((bi >> 16) & 0xFF) * t);
   return((color)(r | (g << 8) | (b << 16)));
  }

datetime BarTime(const int idx)
  {
   int last = g_ratesTotal - 1;
   if(idx >= 0 && idx <= last) return iTime(_Symbol, _Period, last - idx);
   if(idx < 0) return iTime(_Symbol, _Period, last);
   return g_lastTime + (datetime)((idx - last) * PeriodSeconds());
  }

ENUM_LINE_STYLE LStyle() { return InpLvlStyle == LS_DOTTED ? STYLE_DOT : InpLvlStyle == LS_DASHED ? STYLE_DASH : STYLE_SOLID; }
int   LWidth(const double s) { return s >= 82 ? 4 : s >= 62 ? 3 : 2; }
int   LAlpha(const double s) { return s >= 82 ? 8 : s >= 62 ? 22 : s >= 45 ? 38 : 52; }
int   Rings(const double s)  { return s >= 82 ? 4 : s >= 66 ? 3 : s >= 50 ? 2 : 1; }
int   RSize(const int r)     { return r >= 4 ? 22 : r == 3 ? 16 : r == 2 ? 11 : 7; }
int   RAlpha(const int r)    { return r >= 4 ? 68 : r == 3 ? 52 : r == 2 ? 30 : 4; }
color LvlCol(const bool supp){ return supp ? InpSupCol : InpResCol; }
int RowId(const double p, const double bot, const double step, const int rows)
  { return (int)MathMax(0, MathMin(rows - 1, (int)MathFloor((p - bot) / step))); }

double Activity(const double o, const double h, const double l, const double c) { return MathMax(g_tick, (h - l) + MathAbs(c - o)); }

double VolAt(const int i, const double &open[], const double &high[], const double &low[], const double &close[],
             const long &tick_volume[], const long &volume[])
  {
   if(g_useActivity) return Activity(open[i], high[i], low[i], close[i]);
   if(InpVolSrc == VS_REAL) return (double)volume[i];
   return (double)tick_volume[i];
  }

//+------------------------------------------------------------------+
//| MARKET AUTO-PROFILE                                              |
//+------------------------------------------------------------------+
double ParseNumberAfter(const string text, const string key)
  {
   int p = StringFind(text, key);
   if(p < 0) return -1.0;
   p += StringLen(key);
   string num = "";
   for(int k = p; k < StringLen(text); k++)
     {
      ushort ch = StringGetCharacter(text, k);
      if((ch >= '0' && ch <= '9') || ch == '.') num += ShortToString(ch);
      else if(StringLen(num) > 0) break;
     }
   return StringLen(num) > 0 ? StringToDouble(num) : -1.0;
  }

void DetectMarket()
  {
   string name = _Symbol, desc = SymbolInfoString(_Symbol, SYMBOL_DESCRIPTION);
   string all = name + " | " + desc;
   g_volPct = ParseNumberAfter(desc, "Volatility of ");
   if(g_volPct < 0) g_volPct = ParseNumberAfter(name, "Volatility ");
   double ts = ParseNumberAfter(desc, "tick every ");
   g_tickSec = ts > 0 ? (int)ts : (StringFind(name, "(1s)") >= 0 ? 1 : 0);

   g_mkt = MKT_OTHER;
   if(StringFind(all, "Boom") >= 0)             g_mkt = MKT_BOOM;
   else if(StringFind(all, "Crash") >= 0)       g_mkt = MKT_CRASH;
   else if(StringFind(all, "Step") >= 0)        g_mkt = MKT_STEP;
   else if(StringFind(all, "Jump") >= 0)        g_mkt = MKT_JUMP;
   else if(StringFind(all, "Range Break") >= 0) g_mkt = MKT_RANGEBREAK;
   else if(StringFind(all, "DEX") >= 0)         g_mkt = MKT_DEX;
   else if(StringFind(all, "Volatility") >= 0 || g_volPct > 0)
     {
      if(g_volPct <= 0) g_volPct = 50;
      g_mkt = g_volPct <= 30 ? MKT_VOL_CALM : g_volPct <= 50 ? MKT_VOL_MID : MKT_VOL_FAST;
     }
   g_isSynthetic = (g_mkt != MKT_OTHER);
   if(g_tickSec == 0 && g_isSynthetic) g_tickSec = 2;

   switch(g_mkt)
     {
      case MKT_VOL_CALM:   g_mktName = "Volatility " + DoubleToString(g_volPct, 0) + "% (calm)";  g_mSrch = 1.00; g_mMerge = 1.00; g_mBreakSup = 1.00; g_mBreakRes = 1.00; break;
      case MKT_VOL_MID:    g_mktName = "Volatility " + DoubleToString(g_volPct, 0) + "% (mid)";   g_mSrch = 1.05; g_mMerge = 1.10; g_mBreakSup = 1.10; g_mBreakRes = 1.10; break;
      case MKT_VOL_FAST:   g_mktName = "Volatility " + DoubleToString(g_volPct, 0) + "% (fast)";  g_mSrch = 1.15; g_mMerge = 1.25; g_mBreakSup = 1.30; g_mBreakRes = 1.30; break;
      case MKT_BOOM:       g_mktName = "Boom (up-spikes)";      g_mSrch = 1.20; g_mMerge = 1.20; g_mBreakSup = 1.00; g_mBreakRes = 2.20; break;
      case MKT_CRASH:      g_mktName = "Crash (down-spikes)";   g_mSrch = 1.20; g_mMerge = 1.20; g_mBreakSup = 2.20; g_mBreakRes = 1.00; break;
      case MKT_STEP:       g_mktName = "Step index";            g_mSrch = 0.90; g_mMerge = 1.00; g_mBreakSup = 0.80; g_mBreakRes = 0.80; break;
      case MKT_JUMP:       g_mktName = "Jump index";            g_mSrch = 1.20; g_mMerge = 1.20; g_mBreakSup = 1.60; g_mBreakRes = 1.60; break;
      case MKT_RANGEBREAK: g_mktName = "Range Break";           g_mSrch = 1.10; g_mMerge = 1.10; g_mBreakSup = 1.50; g_mBreakRes = 1.50; break;
      case MKT_DEX:        g_mktName = "DEX";                   g_mSrch = 1.20; g_mMerge = 1.20; g_mBreakSup = 1.50; g_mBreakRes = 1.50; break;
      default:             g_mktName = "standard symbol";       g_mSrch = 1.00; g_mMerge = 1.00; g_mBreakSup = 1.00; g_mBreakRes = 1.00; break;
     }
   if(!InpAutoAdapt) { g_mSrch = 1.0; g_mMerge = 1.0; g_mBreakSup = 1.0; g_mBreakRes = 1.0; }
   if(g_tickSec == 1 && (g_mkt == MKT_VOL_CALM || g_mkt == MKT_VOL_MID || g_mkt == MKT_VOL_FAST)) g_mktName += " 1s";

   // volume source
   g_useActivity = (InpVolSrc == VS_ACTIVITY) || (InpVolSrc == VS_AUTO && g_isSynthetic);

   // sub-bar timeframe
   int sec = PeriodSeconds();
   switch(InpSubTf)
     {
      case ST_OFF: g_useSub = false; break;
      case ST_M1:  g_subTf = PERIOD_M1; break;
      case ST_M5:  g_subTf = PERIOD_M5; break;
      case ST_M15: g_subTf = PERIOD_M15; break;
      default:     g_subTf = sec <= 4 * 3600 ? PERIOD_M1 : sec < 86400 ? PERIOD_M5 : PERIOD_M15; break;
     }
   if(InpSubTf != ST_OFF) g_useSub = PeriodSeconds(g_subTf) < sec;

   // lookback bars
   if(InpLbMode == LB_MINUTES) g_profLb = (int)MathMax(100, MathMin(1500, InpLookbackMin / MathMax(1, sec / 60)));
   else g_profLb = MathMax(100, MathMin(1500, InpProfLb));
  }

//+------------------------------------------------------------------+
//| SUB-BAR CACHE                                                    |
//+------------------------------------------------------------------+
void SubReset(const int rates_total)
  {
   ArrayResize(g_subStart, rates_total); ArrayResize(g_subCount, rates_total);
   ArrayInitialize(g_subStart, 0); ArrayInitialize(g_subCount, 0);
   ArrayResize(g_subL, 0); ArrayResize(g_subH, 0); ArrayResize(g_subO, 0); ArrayResize(g_subC, 0); ArrayResize(g_subW, 0);
   g_subTotal = 0; g_subLoadedTo = -1;
  }

void SubEnsureSize(const int rates_total)
  {
   int old = ArraySize(g_subStart);
   if(old < rates_total)
     {
      ArrayResize(g_subStart, rates_total); ArrayResize(g_subCount, rates_total);
      for(int k = old; k < rates_total; k++) { g_subStart[k] = 0; g_subCount[k] = 0; }
     }
  }

void SubAppend(const int bar, const MqlRates &r)
  {
   if(g_subCount[bar] == 0) g_subStart[bar] = g_subTotal;
   int n = g_subTotal + 1;
   ArrayResize(g_subL, n, 4096); ArrayResize(g_subH, n, 4096); ArrayResize(g_subO, n, 4096); ArrayResize(g_subC, n, 4096); ArrayResize(g_subW, n, 4096);
   g_subL[g_subTotal] = r.low; g_subH[g_subTotal] = r.high; g_subO[g_subTotal] = r.open; g_subC[g_subTotal] = r.close;
   g_subW[g_subTotal] = g_useActivity ? Activity(r.open, r.high, r.low, r.close) : (InpVolSrc == VS_REAL ? (double)r.real_volume : (double)r.tick_volume);
   g_subTotal = n; g_subCount[bar]++;
  }

// load sub-bars for chart bars [a .. b] (appends; bars must be loaded in ascending order)
void SubLoad(const int a, const int b, const datetime &time[])
  {
   if(!g_useSub || b < a) return;
   MqlRates rt[];
   datetime tEnd = (b + 1 < g_ratesTotal) ? time[b + 1] - 1 : time[b] + PeriodSeconds() - 1;
   int n = CopyRates(_Symbol, g_subTf, time[a], tEnd, rt);
   if(n <= 0) { g_subLoadedTo = b; return; }
   int j = 0;
   for(int i = a; i <= b; i++)
     {
      datetime t0 = time[i], t1 = (i + 1 < g_ratesTotal) ? time[i + 1] : time[i] + PeriodSeconds();
      while(j < n && rt[j].time < t0) j++;
      while(j < n && rt[j].time < t1) { SubAppend(i, rt[j]); j++; }
     }
   g_subLoadedTo = b;
  }

//+------------------------------------------------------------------+
//| DRAW OBJECT POOL                                                 |
//+------------------------------------------------------------------+
string DName() { return g_prefix + "D" + S(g_nDraw++); }
void DrawBegin() { for(int i = 0; i < g_maxDraw; i++) ObjectDelete(0, g_prefix + "D" + S(i)); g_nDraw = 0; }
void DrawEnd()   { g_maxDraw = g_nDraw; }

void DRect(const datetime t1, const double p1, const datetime t2, const double p2, const color clr, const bool fill, const int width = 1)
  {
   string n = DName();
   ObjectCreate(0, n, OBJ_RECTANGLE, 0, t1, p1, t2, p2);
   ObjectSetInteger(0, n, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, n, OBJPROP_FILL, fill);
   ObjectSetInteger(0, n, OBJPROP_BACK, true);
   ObjectSetInteger(0, n, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN, true);
  }
void DText(const datetime t, const double p, const string txt, const color clr, const int fs,
           const ENUM_ANCHOR_POINT anchor, const string tip = "", const string font = "Arial")
  {
   string n = DName();
   ObjectCreate(0, n, OBJ_TEXT, 0, t, p);
   ObjectSetString(0, n, OBJPROP_TEXT, txt);
   ObjectSetString(0, n, OBJPROP_FONT, font);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE, fs);
   ObjectSetInteger(0, n, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, n, OBJPROP_ANCHOR, anchor);
   ObjectSetInteger(0, n, OBJPROP_BACK, false);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN, true);
   ObjectSetString(0, n, OBJPROP_TOOLTIP, tip == "" ? "\n" : tip);
  }
void DLine(const datetime t1, const double p1, const datetime t2, const double p2, const color clr, const int width, const ENUM_LINE_STYLE st)
  {
   string n = DName();
   ObjectCreate(0, n, OBJ_TREND, 0, t1, p1, t2, p2);
   ObjectSetInteger(0, n, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, n, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, n, OBJPROP_STYLE, st);
   ObjectSetInteger(0, n, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, n, OBJPROP_RAY_LEFT, false);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN, true);
  }

//+------------------------------------------------------------------+
//| LEVEL LINES                                                      |
//+------------------------------------------------------------------+
string LineName(const int id) { return g_prefix + "LN" + S(id); }
string ScoreTip(const Lvl &lv)
  {
   return (lv.supp ? "SUPPORT" : "RESISTANCE") + "  score " + S((int)MathRound(lv.sc)) +
          "\nRaw pivot: " + Px(lv.raw) + "\nProfile node: " + Px(lv.node) +
          "\nProfile evidence: " + S((int)MathRound(lv.evid * 100.0)) + "%\nNode strength vs POC: " + S((int)MathRound(lv.nStr * 100.0)) +
          "%\nFinal level: " + Px(lv.p) + "\nRetests: held " + S(lv.holds) + " / broke " + S(lv.breaks);
  }
void LineSet(const Lvl &lv, const datetime tNow)
  {
   string n = LineName(lv.id);
   if(ObjectFind(0, n) < 0)
     {
      ObjectCreate(0, n, OBJ_TREND, 0, lv.born, lv.p, tNow, lv.p);
      ObjectSetInteger(0, n, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, n, OBJPROP_RAY_LEFT, false);
      ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, n, OBJPROP_HIDDEN, true);
     }
   ObjectSetInteger(0, n, OBJPROP_TIME, 0, lv.born);
   ObjectSetDouble(0, n, OBJPROP_PRICE, 0, lv.p);
   ObjectSetInteger(0, n, OBJPROP_TIME, 1, tNow);
   ObjectSetDouble(0, n, OBJPROP_PRICE, 1, lv.p);
   ObjectSetInteger(0, n, OBJPROP_COLOR, Blend(LvlCol(lv.supp), LAlpha(lv.sc)));
   ObjectSetInteger(0, n, OBJPROP_WIDTH, LWidth(lv.sc));
   ObjectSetInteger(0, n, OBJPROP_STYLE, LStyle());
   ObjectSetString(0, n, OBJPROP_TOOLTIP, ScoreTip(lv));
  }

//+------------------------------------------------------------------+
//| PROFILE over chart bars [a .. b]  (sub-bars when cached)         |
//+------------------------------------------------------------------+
void SpreadRange(const double l, const double h, const double c, const double v, const double bot, const double step,
                 const int rows, double &tot[], double &buy[])
  {
   double r = h - l;
   double bf = r > 0 ? Clip((c - l) / r) : 0.5;
   int r0 = RowId(l, bot, step, rows), r1 = RowId(h, bot, step, rows);
   for(int j = r0; j <= r1; j++)
     {
      double rl = bot + j * step;
      double ov = r > 0 ? MathMax(0.0, MathMin(h, rl + step) - MathMax(l, rl)) : step;
      double frac = r > 0 ? ov / r : 1.0;
      if(frac > 0) { double av = v * frac; tot[j] += av; buy[j] += av * bf; }
     }
  }

void Profile(const int a, const int b, const int rows, const double &open[], const double &high[], const double &low[], const double &close[],
             const long &tick_volume[], const long &volume[], double &bot, double &step, double &tot[], double &buy[])
  {
   double lo = low[b], hi = high[b];
   for(int i = a; i <= b; i++) { if(low[i] < lo) lo = low[i]; if(high[i] > hi) hi = high[i]; }
   double span = MathMax(hi - lo, g_tick * rows);
   bot  = lo - (span - (hi - lo)) * 0.5;
   step = span / rows;
   ArrayResize(tot, rows); ArrayResize(buy, rows);
   ArrayInitialize(tot, 0.0); ArrayInitialize(buy, 0.0);
   for(int i = a; i <= b; i++)
     {
      int cnt = (g_useSub && i < ArraySize(g_subCount)) ? g_subCount[i] : 0;
      if(cnt > 0)
        {
         int s0 = g_subStart[i];
         for(int j = s0; j < s0 + cnt; j++) SpreadRange(g_subL[j], g_subH[j], g_subC[j], g_subW[j], bot, step, rows, tot, buy);
        }
      else
         SpreadRange(low[i], high[i], close[i], MathMax(VolAt(i, open, high, low, close, tick_volume, volume), 0.0), bot, step, rows, tot, buy);
     }
  }

void CalcVA(const double &tot[], const int poc, int &lo, int &hi)
  {
   int n = ArraySize(tot);
   double sum = 0; for(int i = 0; i < n; i++) sum += tot[i];
   double target = sum * InpVaPct / 100.0;
   lo = poc; hi = poc; double acc = tot[poc];
   while(acc < target && (lo > 0 || hi < n - 1))
     {
      double up = hi < n - 1 ? tot[hi + 1] : -1.0, dn = lo > 0 ? tot[lo - 1] : -1.0;
      if(up >= dn) { hi++; acc += up; } else { lo--; acc += dn; }
     }
  }

//+------------------------------------------------------------------+
//| PIVOT FEATURES                                                   |
//+------------------------------------------------------------------+
void PivotFeatures(const bool supp, const int pb, const double &open[], const double &high[], const double &low[],
                   const double &close[], double &vSc, double &wSc, double &absSc)
  {
   double vol = ActBuf[pb];
   double vb = AvgVolBuf[pb] > 0 ? AvgVolBuf[pb] : vol;
   double vr = vb > 0 ? vol / vb : 1.0;
   vSc = Clip((vr - 0.8) / (PIV_VOL_X - 0.8));
   double pr = MathMax(high[pb] - low[pb], g_tick);
   double wick = supp ? MathMin(open[pb], close[pb]) - low[pb] : high[pb] - MathMax(open[pb], close[pb]);
   wSc = Clip((wick / pr) / 0.50);
   absSc = 0.0;
   for(int o = pb - g_absRad; o <= pb + g_absRad; o++)
     {
      if(o < 0) continue;
      double cr = MathMax(high[o] - low[o], g_tick);
      double v = MathMax(ActBuf[o], 0.0);
      double base = AvgVolBuf[o] > 0 ? AvgVolBuf[o] : v;
      double vRat = base > 0 ? v / base : 1.0;
      double bRat = MathAbs(close[o] - open[o]) / cr;
      double small = Clip((ABS_BODY_MAX - bRat) / ABS_BODY_MAX);
      double av = Clip((vRat - 1.0) / (ABS_VOL_X - 1.0));
      absSc = MathMax(absSc, MathSqrt(small * av));
     }
  }

void ProfileNode(const double raw, const bool supp, const double atrP, const double bot, const double step,
                 const double &tot[], const double &buy[], double &bestP, double &bestE, double &bestS)
  {
   int rows = ArraySize(tot);
   double mx = 0.0; for(int r = 0; r < rows; r++) mx = MathMax(mx, tot[r]);
   mx = MathMax(mx, 0.0000001);
   double rad = MathMax(atrP * InpSrchAtr * g_mSrch, step * 2.0);
   bestP = raw; bestE = -1.0; bestS = 0.0;
   for(int r = 0; r < rows; r++)
     {
      double p = bot + (r + 0.5) * step, d = MathAbs(p - raw);
      if(d > rad) continue;
      double rv = tot[r], str = rv / mx;
      double lv = r > 0 ? tot[r - 1] : rv, rv2 = r < rows - 1 ? tot[r + 1] : rv;
      double nAvg = MathMax((lv + rv2) * 0.5, mx * 0.01);
      double pk = Clip((rv / nAvg - 0.85) / 0.65);
      double bSh = rv > 0 ? Clip(buy[r] / rv) : 0.5;
      double dir = supp ? bSh : 1.0 - bSh;
      double prox = 1.0 - d / rad;
      double e = 0.50 * str + 0.20 * pk + 0.20 * dir + 0.10 * prox;
      if(e > bestE) { bestE = e; bestP = p; bestS = str; }
     }
   bestE = MathMax(bestE, 0.0);
  }

//+------------------------------------------------------------------+
//| LEVEL STORE / LIFECYCLE                                          |
//+------------------------------------------------------------------+
int Nearby(const double p, const bool supp, const double tol)
  {
   int id = -1; double best = 1e20;
   for(int i = 0; i < ArraySize(g_lv); i++)
      if(g_lv[i].supp == supp) { double d = MathAbs(g_lv[i].p - p); if(d <= tol && d < best) { best = d; id = i; } }
   return id;
  }

bool StoreLvl(const double p, const double raw, const double node, const double evid, const double nStr, const bool supp,
              const double sc, const datetime born, const int bornBar, const double atrP, const datetime tNow)
  {
   double tol = MathMax(atrP * InpMergeAtr * g_mMerge, g_tick);
   int id = Nearby(p, supp, tol);
   if(id >= 0)
     {
      if(sc > g_lv[id].sc)
        {
         g_lv[id].p = p; g_lv[id].sc = sc; g_lv[id].raw = raw; g_lv[id].node = node; g_lv[id].evid = evid; g_lv[id].nStr = nStr;
         g_lv[id].born = born; g_lv[id].bornBar = bornBar;
         LineSet(g_lv[id], tNow);
         return true;
        }
      return false;
     }
   Lvl lv; ZeroMemory(lv);
   lv.id = g_nextId++; lv.p = p; lv.sc = sc; lv.raw = raw; lv.node = node; lv.evid = evid; lv.nStr = nStr; lv.supp = supp;
   lv.born = born; lv.bornBar = bornBar; lv.inRetest = false; lv.retestStart = -1;
   int sz = ArraySize(g_lv); ArrayResize(g_lv, sz + 1); g_lv[sz] = lv;
   LineSet(lv, tNow);
   return true;
  }

void RemoveLvl(const int id) { ObjectDelete(0, LineName(g_lv[id].id)); ArrayRemove(g_lv, id, 1); }

void TrimLvls()
  {
   while(ArraySize(g_lv) > InpMaxLvl)
     {
      int weak = 0; double sc = g_lv[0].sc;
      for(int i = 1; i < ArraySize(g_lv); i++) if(g_lv[i].sc < sc) { sc = g_lv[i].sc; weak = i; }
      RemoveLvl(weak);
     }
  }

int LevelRow(const double lo, const double hi)
  {
   for(int i = 0; i < ArraySize(g_lv); i++) if(g_lv[i].p >= lo && g_lv[i].p <= hi) return g_lv[i].supp ? 1 : -1;
   return 0;
  }

//+------------------------------------------------------------------+
//| PIVOT EVALUATION                                                 |
//+------------------------------------------------------------------+
bool PivotEval(const int i, const double raw, const bool supp, const datetime &time[], const double &open[], const double &high[],
               const double &low[], const double &close[], const long &tick_volume[], const long &volume[])
  {
   int pb = i - InpSwingLen;
   int bars = MathMax(1, MathMin(g_profLb, pb + 1));
   double bot, step; double tot[], buy[];
   Profile(pb - bars + 1, pb, InpProfRows, open, high, low, close, tick_volume, volume, bot, step, tot, buy);
   double atrP = MathMax(AtrBuf[pb] > 0 ? AtrBuf[pb] : g_tick, g_tick);
   double node, evid, nStr;
   ProfileNode(raw, supp, atrP, bot, step, tot, buy, node, evid, nStr);
   double vSc, wSc, aSc;
   PivotFeatures(supp, pb, open, high, low, close, vSc, wSc, aSc);
   bool ok = nStr >= InpNodeMin && evid >= InpEvidMin;
   double pull = ok ? InpPullMax * Clip(evid / 0.65) : 0.0;
   double p = raw + (node - raw) * pull;
   double sc = 100.0 * (0.50 * evid + 0.20 * aSc + 0.15 * vSc + 0.15 * wSc);
   if(ok && sc >= InpScoreMin) return StoreLvl(p, raw, node, evid, nStr, supp, sc, time[pb], pb, atrP, time[i]);
   return false;
  }

bool IsPivotLow(const double &low[], const int i, const int n)
  {
   int c = i - n; if(c - n < 0) return false;
   double p = low[c];
   for(int k = c - n; k < c; k++)  if(low[k] <  p) return false;
   for(int k = c + 1; k <= c + n; k++) if(low[k] <= p) return false;
   return true;
  }
bool IsPivotHigh(const double &high[], const int i, const int n)
  {
   int c = i - n; if(c - n < 0) return false;
   double p = high[c];
   for(int k = c - n; k < c; k++)  if(high[k] >  p) return false;
   for(int k = c + 1; k <= c + n; k++) if(high[k] >= p) return false;
   return true;
  }

void Fire(const string msg)
  {
   string full = _Symbol + " " + EnumToString((ENUM_TIMEFRAMES)_Period) + " | UTT: " + msg;
   if(InpAlertPopup) Alert(full);
   if(InpAlertPush)  SendNotification(full);
   if(InpAlertSound) PlaySound(InpSoundFile);
  }

//+------------------------------------------------------------------+
//| CONFIRMED BAR                                                    |
//+------------------------------------------------------------------+
void ProcessConfirmedBar(const int i, const datetime &time[], const double &open[], const double &high[], const double &low[],
                         const double &close[], const long &tick_volume[], const long &volume[])
  {
   bool ready = i > VOL_LEN + InpSwingLen * 2 + 5;
   bool newSup = false, newRes = false;
   if(ready && IsPivotLow(low, i, InpSwingLen))   newSup = PivotEval(i, low[i - InpSwingLen],  true,  time, open, high, low, close, tick_volume, volume);
   if(ready && IsPivotHigh(high, i, InpSwingLen)) newRes = PivotEval(i, high[i - InpSwingLen], false, time, open, high, low, close, tick_volume, volume);
   if(newSup || newRes) g_dirty = true;

   double atr = AtrBuf[i] > 0 ? AtrBuf[i] : g_tick;
   bool sBreak = false, rBreak = false, retestNow = false;
   for(int k = ArraySize(g_lv) - 1; k >= 0; k--)
     {
      double p = g_lv[k].p; bool supp = g_lv[k].supp;
      double buf = MathMax(atr * InpBreakAtr * (supp ? g_mBreakSup : g_mBreakRes), 0.0);
      bool broken = supp ? close[i] < p - buf : close[i] > p + buf;
      if(broken)
        {
         g_relBreak[(supp ? 0 : 1) * 3 + Band(g_lv[k].sc)]++;
         if(supp) sBreak = true; else rBreak = true;
         RemoveLvl(k); g_dirty = true; continue;
        }
      // ---- retest tracker
      if(i <= g_lv[k].bornBar + InpSwingLen) continue;           // not before the level is confirmed
      double band = InpTouchAtr * atr;
      bool inside = (low[i] <= p + band && high[i] >= p - band);
      if(!g_lv[k].inRetest && inside) { g_lv[k].inRetest = true; g_lv[k].retestStart = i; retestNow = true; }
      if(g_lv[k].inRetest)
        {
         bool held = supp ? (high[i] >= p + InpHoldAtr * atr) : (low[i] <= p - InpHoldAtr * atr);
         if(held)
           {
            g_lv[k].holds++; g_relHold[(supp ? 0 : 1) * 3 + Band(g_lv[k].sc)]++;
            g_lv[k].inRetest = false; g_dirty = true;
           }
         else if(!inside && i - g_lv[k].retestStart > InpRetestTimeout) g_lv[k].inRetest = false;
        }
     }
   int before = ArraySize(g_lv); TrimLvls(); if(ArraySize(g_lv) != before) g_dirty = true;

   if(g_liveMode)
     {
      if(InpAlertNewLevel && newSup) Fire("New profile-confirmed SUPPORT");
      if(InpAlertNewLevel && newRes) Fire("New profile-confirmed RESISTANCE");
      if(InpAlertBreak && sBreak)    Fire("Support broken on a confirmed close");
      if(InpAlertBreak && rBreak)    Fire("Resistance broken on a confirmed close");
      if(InpAlertRetest && retestNow) Fire("Price is retesting a profile-confirmed level");
     }
  }

//+------------------------------------------------------------------+
//| DRAWING                                                          |
//+------------------------------------------------------------------+
void DrawMarkers()
  {
   if(!InpShowDots) return;
   for(int i = 0; i < ArraySize(g_lv); i++)
     {
      Lvl lv = g_lv[i];
      color base = LvlCol(lv.supp);
      if(InpShowRaw)
        {
         DText(lv.born, lv.raw, SYM_DOT, Blend(InpRawCol, 60), 7, ANCHOR_CENTER);
         DLine(lv.born, lv.raw, lv.born, lv.p, Blend(InpCoreCol, 45), 1, STYLE_DOT);
        }
      int rc = Rings(lv.sc);
      for(int r = rc; r >= 1; r--)
        {
         color fill = r == 1 ? Blend(InpCoreCol, lv.evid >= 0.45 ? 0 : 22) : Blend(base, RAlpha(r));
         DText(lv.born, lv.p, SYM_DOT, fill, RSize(r), ANCHOR_CENTER);
        }
      if(InpShowDotScore) DText(lv.born, lv.p, S((int)MathRound(lv.sc)), clrWhite, 7, ANCHOR_CENTER, ScoreTip(lv), "Arial Bold");
     }
  }

void DrawEdge(const int last)
  {
   if(!InpShowEdge) return;
   for(int i = 0; i < ArraySize(g_lv); i++)
     {
      color c = LvlCol(g_lv[i].supp);
      string rt = (g_lv[i].holds + g_lv[i].breaks > 0) ? "  " + S(g_lv[i].holds) + "/" + S(g_lv[i].holds + g_lv[i].breaks) : "";
      DText(BarTime(last), g_lv[i].p, SYM_DOT, c, 7, ANCHOR_CENTER);
      DText(BarTime(last + 1), g_lv[i].p, S((int)MathRound(g_lv[i].sc)) + rt, c, 8, ANCHOR_LEFT, ScoreTip(g_lv[i]), "Arial Bold");
     }
  }

void DrawProfile(const int last, const bool draw, const double &open[], const double &high[], const double &low[], const double &close[],
                 const long &tick_volume[], const long &volume[])
  {
   int bars = MathMax(1, MathMin(g_profLb, last + 1));
   double bot, step; double tot[], buy[];
   Profile(last - bars + 1, last, InpProfRows, open, high, low, close, tick_volume, volume, bot, step, tot, buy);
   double mx = 0.0; int poc = 0;
   for(int r = 0; r < InpProfRows; r++) if(tot[r] > mx) { mx = tot[r]; poc = r; }
   g_poc = 0; g_vah = 0; g_val = 0;
   if(mx <= 0) return;
   int vlo, vhi; CalcVA(tot, poc, vlo, vhi);
   g_poc = bot + (poc + 0.5) * step; g_vah = bot + (vhi + 1) * step; g_val = bot + vlo * step;
   if(!draw) return;
   int x = last + InpProfOff;
   for(int r = 0; r < InpProfRows; r++)
     {
      double rv = tot[r]; if(rv <= 0) continue;
      double str = rv / mx, bSh = Clip(buy[r] / rv);
      int tw = MathMax(1, (int)MathRound(InpProfW * str)), bw = (int)MathRound(tw * bSh), sw = tw - bw;
      double y0 = bot + (r + 0.08) * step, y1 = bot + (r + 0.92) * step;
      int fade = (int)MathRound(76.0 - 46.0 * str);
      if(bw > 0) DRect(BarTime(x), y1, BarTime(x + bw), y0, Blend(InpBuyCol, fade), true);
      if(sw > 0) DRect(BarTime(x + bw), y1, BarTime(x + tw), y0, Blend(InpSellCol, fade), true);
      if(InpShowPoc && r == poc) { DRect(BarTime(x), y1, BarTime(x + tw), y0, Blend(InpPocCol, 88), true); DRect(BarTime(x), y1, BarTime(x + tw), y0, InpPocCol, false, 2); }
      if(InpShowLvlRows)
        {
         int side = LevelRow(y0, y1);
         if(side != 0) { DRect(BarTime(x), y1, BarTime(x + tw), y0, Blend(InpCoreCol, 93), true); DRect(BarTime(x), y1, BarTime(x + tw), y0, side > 0 ? InpSupCol : InpResCol, false, 2); }
        }
     }
   if(InpShowPoc)
     {
      DLine(BarTime(MathMax(0, last - 18)), g_poc, BarTime(x), g_poc, Blend(InpPocCol, 25), 2, STYLE_SOLID);
      DText(BarTime(x + InpProfW + 2), g_poc, "POC " + Px(g_poc), InpPocCol, 7, ANCHOR_LEFT, "", "Arial Bold");
     }
   if(InpShowVA)
     {
      DLine(BarTime(x), g_vah, BarTime(x + InpProfW), g_vah, Blend(InpVaCol, 30), 1, STYLE_DOT);
      DLine(BarTime(x), g_val, BarTime(x + InpProfW), g_val, Blend(InpVaCol, 30), 1, STYLE_DOT);
      DText(BarTime(x + InpProfW + 2), g_vah, "VAH", InpVaCol, 7, ANCHOR_LEFT);
      DText(BarTime(x + InpProfW + 2), g_val, "VAL", InpVaCol, 7, ANCHOR_LEFT);
     }
  }

//+------------------------------------------------------------------+
//| UTT DASHBOARD                                                    |
//+------------------------------------------------------------------+
#define DASH_ROWS 14
void DashLabel(const int row, const string txt, const color clr, const bool bold = false)
  {
   string name = g_prefix + "DS" + S(row);
   int rowH = InpDashFont + 7;
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
     }
   ObjectSetString(0, name, OBJPROP_FONT, bold ? "Consolas Bold" : "Consolas");
   ObjectSetInteger(0, name, OBJPROP_CORNER, InpDashCorner);
   ENUM_ANCHOR_POINT anchor = ANCHOR_LEFT_UPPER;
   if(InpDashCorner == CORNER_RIGHT_UPPER) anchor = ANCHOR_RIGHT_UPPER;
   if(InpDashCorner == CORNER_LEFT_LOWER)  anchor = ANCHOR_LEFT_LOWER;
   if(InpDashCorner == CORNER_RIGHT_LOWER) anchor = ANCHOR_RIGHT_LOWER;
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, InpDashX);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, InpDashY + row * rowH);
   ObjectSetString(0, name, OBJPROP_TEXT, txt);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, InpDashFont);
  }

string PctS(const int h, const int b) { return (h + b == 0) ? "n/a" : S((int)MathRound(100.0 * h / (h + b))) + "%"; }
string RelRow(const string name, const int idx0)   // idx0 = band; sums support+resistance
  {
   int h = g_relHold[idx0] + g_relHold[3 + idx0], b = g_relBreak[idx0] + g_relBreak[3 + idx0];
   return name + " held " + PctS(h, b) + " (" + S(h) + "/" + S(h + b) + ")   S " + PctS(g_relHold[idx0], g_relBreak[idx0]) + " / R " + PctS(g_relHold[3 + idx0], g_relBreak[3 + idx0]);
  }

void RenderDashboard(const int last, const double &close[])
  {
   if(!InpShowDash) { for(int r = 0; r < DASH_ROWS; r++) ObjectDelete(0, g_prefix + "DS" + S(r)); return; }
   double px = close[last];
   double atr = AtrBuf[last] > 0 ? AtrBuf[last] : g_tick;
   double atrN = 0; int n = 0;
   for(int k = last; k >= 0 && n < ATR_NORM_LEN; k--, n++) atrN += AtrBuf[k];
   atrN = n > 0 ? atrN / n : atr;
   double volRatio = atrN > 0 ? atr / atrN : 1.0;

   // nearest levels
   int si = -1, ri = -1;
   for(int i = 0; i < ArraySize(g_lv); i++)
     {
      if(g_lv[i].supp  && g_lv[i].p <= px && (si < 0 || g_lv[i].p > g_lv[si].p)) si = i;
      if(!g_lv[i].supp && g_lv[i].p >= px && (ri < 0 || g_lv[i].p < g_lv[ri].p)) ri = i;
     }
   string tf = StringSubstr(EnumToString((ENUM_TIMEFRAMES)_Period), 7);
   string spd = g_tickSec > 0 ? S(g_tickSec) + "s ticks" : "";
   string volTxt = volRatio >= 1.3 ? "HIGH" : volRatio <= 0.75 ? "LOW" : "normal";

   // bias
   string bias, biasWhy;
   if(g_poc <= 0) { bias = "Bias: profile not ready"; biasWhy = ""; }
   else
     {
      bool aboveVA = px > g_vah, belowVA = px < g_val, abovePoc = px > g_poc;
      if(aboveVA)      { bias = "Bias: BUYERS in control (price above value area)"; biasWhy = "pullbacks toward VAH " + Px(g_vah) + " are buy-side interest"; }
      else if(belowVA) { bias = "Bias: SELLERS in control (price below value area)"; biasWhy = "bounces toward VAL " + Px(g_val) + " are sell-side interest"; }
      else             { bias = "Bias: BALANCED inside value (" + (abovePoc ? "above" : "below") + " POC " + Px(g_poc) + ")"; biasWhy = "expect rotation between VAL " + Px(g_val) + " and VAH " + Px(g_vah); }
     }

   // read line
   string read = "";
   if(si >= 0 && (px - g_lv[si].p) <= 0.5 * atr)
     {
      int b = Band(g_lv[si].sc); int h = g_relHold[b], br = g_relBreak[b];
      read = "READ: testing SUPPORT " + Px(g_lv[si].p) + " (score " + S((int)MathRound(g_lv[si].sc)) + ") - this band held " + PctS(h, br) +
             " here; close below " + Px(g_lv[si].p - atr * InpBreakAtr * g_mBreakSup) + " invalidates";
     }
   else if(ri >= 0 && (g_lv[ri].p - px) <= 0.5 * atr)
     {
      int b = Band(g_lv[ri].sc); int h = g_relHold[3 + b], br = g_relBreak[3 + b];
      read = "READ: testing RESISTANCE " + Px(g_lv[ri].p) + " (score " + S((int)MathRound(g_lv[ri].sc)) + ") - this band held " + PctS(h, br) +
             " here; close above " + Px(g_lv[ri].p + atr * InpBreakAtr * g_mBreakRes) + " invalidates";
     }
   else if(si >= 0 || ri >= 0)
      read = "READ: no level within 0.5 ATR - wait for price to reach a level, then trade the reaction";
   else
      read = "READ: no active levels yet - the engine needs confirmed swings with profile evidence";

   int r = 0;
   DashLabel(r++, "UTT  BUYERS & SELLERS PROFILE   " + _Symbol + "  " + tf, InpDashBrand, true);
   DashLabel(r++, "Market: " + g_mktName + (spd == "" ? "" : "  " + spd) + "  |  ATR " + Px(atr) + " (" + DoubleToString(volRatio, 2) + "x " + volTxt + ")  |  volume = " + (g_useActivity ? "activity" : "ticks") + (g_useSub ? ", sub-bars " + StringSubstr(EnumToString(g_subTf), 7) : ""), InpDashMuted);
   DashLabel(r++, bias, InpDashText, true);
   if(biasWhy != "") DashLabel(r++, "  " + biasWhy, InpDashMuted);
   DashLabel(r++, si >= 0 ? "Support    " + Px(g_lv[si].p) + "  " + DoubleToString((px - g_lv[si].p) / atr, 2) + " ATR below  score " + S((int)MathRound(g_lv[si].sc)) + "  held " + S(g_lv[si].holds) + "/" + S(g_lv[si].holds + g_lv[si].breaks)
                          : "Support    none below price", InpSupCol);
   DashLabel(r++, ri >= 0 ? "Resistance " + Px(g_lv[ri].p) + "  " + DoubleToString((g_lv[ri].p - px) / atr, 2) + " ATR above  score " + S((int)MathRound(g_lv[ri].sc)) + "  held " + S(g_lv[ri].holds) + "/" + S(g_lv[ri].holds + g_lv[ri].breaks)
                          : "Resistance none above price", InpResCol);
   DashLabel(r++, "LEVEL RELIABILITY  (retests on this market, " + tf + ")", InpDashBrand, true);
   DashLabel(r++, RelRow("  Score 80+  ", 0), InpDashText);
   DashLabel(r++, RelRow("  Score 60-79", 1), InpDashText);
   DashLabel(r++, RelRow("  Score <60  ", 2), InpDashText);
   int th = 0, tb = 0; for(int k = 0; k < 6; k++) { th += g_relHold[k]; tb += g_relBreak[k]; }
   DashLabel(r++, "  All levels  held " + PctS(th, tb) + " (" + S(th) + "/" + S(th + tb) + ")   held = bounced " + DoubleToString(InpHoldAtr, 2) + " ATR away before a close through", InpDashMuted);
   DashLabel(r++, read, InpDashText);
   for(; r < DASH_ROWS; r++) ObjectDelete(0, g_prefix + "DS" + S(r));
  }

//+------------------------------------------------------------------+
void Render(const int last, const double &open[], const double &high[], const double &low[], const double &close[],
            const long &tick_volume[], const long &volume[])
  {
   datetime tNow = BarTime(last);
   for(int i = 0; i < ArraySize(g_lv); i++) LineSet(g_lv[i], tNow);
   DrawBegin();
   DrawMarkers();
   DrawEdge(last);
   DrawProfile(last, InpShowProf, open, high, low, close, tick_volume, volume);
   DrawEnd();
   PocBuf[last] = g_poc; VahBuf[last] = g_vah; ValBuf[last] = g_val;

   double sup = 0.0, res = 0.0;
   for(int i = 0; i < ArraySize(g_lv); i++)
     {
      if(g_lv[i].supp  && g_lv[i].p <= close[last] && (sup == 0.0 || g_lv[i].p > sup)) sup = g_lv[i].p;
      if(!g_lv[i].supp && g_lv[i].p >= close[last] && (res == 0.0 || g_lv[i].p < res)) res = g_lv[i].p;
     }
   SupBuf[last] = sup; ResBuf[last] = res;
   RenderDashboard(last, close);
  }

//+------------------------------------------------------------------+
//| RE-INDEX after the chart dropped / added bars on the LEFT         |
//| ("Max bars in chart" trims the oldest bar on every new bar on     |
//| 24/7 Deriv symbols). All stored bar indices move by `delta`.      |
//+------------------------------------------------------------------+
void Rebase(const int delta)
  {
   if(delta == 0) return;
   g_lastProcessed += delta;
   for(int i = 0; i < ArraySize(g_lv); i++)
     {
      g_lv[i].bornBar += delta;
      if(g_lv[i].retestStart >= 0) g_lv[i].retestStart += delta;
     }
   if(g_useSub && ArraySize(g_subStart) > 0)
     {
      int n = ArraySize(g_subStart);
      if(delta < 0)
        {
         int d = MathMin(-delta, n);
         int drop = 0; for(int k = 0; k < d; k++) drop += g_subCount[k];
         if(drop > 0)
           {
            ArrayRemove(g_subL, 0, drop); ArrayRemove(g_subH, 0, drop); ArrayRemove(g_subO, 0, drop);
            ArrayRemove(g_subC, 0, drop); ArrayRemove(g_subW, 0, drop);
            g_subTotal -= drop;
           }
         for(int k = d; k < n; k++) { g_subStart[k - d] = MathMax(0, g_subStart[k] - drop); g_subCount[k - d] = g_subCount[k]; }
         ArrayResize(g_subStart, n - d); ArrayResize(g_subCount, n - d);
        }
      else
        {
         ArrayResize(g_subStart, n + delta); ArrayResize(g_subCount, n + delta);
         for(int k = n - 1; k >= 0; k--) { g_subStart[k + delta] = g_subStart[k]; g_subCount[k + delta] = g_subCount[k]; }
         for(int k = 0; k < delta; k++) { g_subStart[k] = 0; g_subCount[k] = 0; }
        }
      g_subLoadedTo += delta;
      if(g_subLoadedTo < -1) g_subLoadedTo = -1;
     }
   g_dirty = true;
  }

//+------------------------------------------------------------------+
void ResetEngine()
  {
   ObjectsDeleteAll(0, g_prefix);
   ArrayResize(g_lv, 0);
   ArrayInitialize(g_relHold, 0); ArrayInitialize(g_relBreak, 0);
   g_nextId = 1; g_lastProcessed = -1; g_liveMode = false; g_dirty = true; g_nDraw = 0; g_maxDraw = 0;
  }

int OnInit()
  {
   g_prefix = "UTTBSP_";                       // fixed name space: also removes orphans left by templates / other charts
   ObjectsDeleteAll(0, g_prefix);
   g_bg = InpAutoBackground ? (color)ChartGetInteger(0, CHART_COLOR_BACKGROUND) : InpBackgroundCol;
   g_tick = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(g_tick <= 0) g_tick = _Point;
   if(g_tick <= 0) g_tick = MathPow(10.0, -_Digits);
   g_absRad = MathMin(3, InpSwingLen);
   SYM_DOT = ShortToString(0x25CF);
   DetectMarket();
   Print("UTT BSP: ", _Symbol, " ", EnumToString((ENUM_TIMEFRAMES)_Period), " | market=", g_mktName, " tick=", g_tickSec, "s",
         " | volume=", g_useActivity ? "activity" : "ticks", " | sub-bars=", g_useSub ? EnumToString(g_subTf) : "off",
         " | lookback=", g_profLb, " bars | scale search x", DoubleToString(g_mSrch, 2), " merge x", DoubleToString(g_mMerge, 2),
         " break S x", DoubleToString(g_mBreakSup, 2), " R x", DoubleToString(g_mBreakRes, 2));

   SetIndexBuffer(0, SupBuf,    INDICATOR_DATA);
   SetIndexBuffer(1, ResBuf,    INDICATOR_DATA);
   SetIndexBuffer(2, PocBuf,    INDICATOR_DATA);
   SetIndexBuffer(3, VahBuf,    INDICATOR_DATA);
   SetIndexBuffer(4, ValBuf,    INDICATOR_DATA);
   SetIndexBuffer(5, ActBuf,    INDICATOR_DATA);
   SetIndexBuffer(6, AvgVolBuf, INDICATOR_CALCULATIONS);
   SetIndexBuffer(7, AtrBuf,    INDICATOR_CALCULATIONS);
   ArraySetAsSeries(SupBuf, false); ArraySetAsSeries(ResBuf, false); ArraySetAsSeries(PocBuf, false);
   ArraySetAsSeries(VahBuf, false); ArraySetAsSeries(ValBuf, false); ArraySetAsSeries(ActBuf, false);
   ArraySetAsSeries(AvgVolBuf, false); ArraySetAsSeries(AtrBuf, false);
   for(int p = 0; p < 6; p++) PlotIndexSetDouble(p, PLOT_EMPTY_VALUE, 0.0);

   hAtr = iATR(_Symbol, _Period, 14);
   if(hAtr == INVALID_HANDLE) return INIT_FAILED;
   if(g_useSub) { MqlRates tmp[]; CopyRates(_Symbol, g_subTf, 0, 10, tmp); }   // kick off history download
   IndicatorSetString(INDICATOR_SHORTNAME, "UTT Buyers & Sellers Profile (Deriv)");
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   ResetEngine();
   g_firstBarTime = 0; g_atrWait = 0;
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, g_prefix);
   if(hAtr != INVALID_HANDLE) IndicatorRelease(hAtr);
  }

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[],
                const double &open[], const double &high[], const double &low[], const double &close[],
                const long &tick_volume[], const long &volume[], const int &spread[])
  {
   int warm = VOL_LEN + InpSwingLen * 2 + 8;
   if(rates_total < warm + 2) return 0;

   // no-blink guard (Deriv 1s indices): never wipe on a transient handle failure
   if(BarsCalculated(hAtr) < rates_total)
     {
      g_atrWait++;
      if(g_atrWait > 200) { IndicatorRelease(hAtr); hAtr = iATR(_Symbol, _Period, 14); g_atrWait = 0; }
      return prev_calculated;
     }
   g_atrWait = 0;

   g_ratesTotal = rates_total; g_lastTime = time[rates_total - 1];
   bool hardReset = false;
   if(g_lastProcessed < 0) hardReset = true;
   else if(time[0] != g_firstBarTime || rates_total < g_prevRates)
     {
      // bars were added / removed on the left: find where our last processed bar went
      int shift = (g_lastProcessedTime > 0) ? iBarShift(_Symbol, _Period, g_lastProcessedTime, true) : -1;
      if(shift < 0) hardReset = true;
      else
        {
         int newIdx = rates_total - 1 - shift;
         Rebase(newIdx - g_lastProcessed);
         g_firstBarTime = time[0];
        }
     }
   else if(prev_calculated > 0 && prev_calculated < g_lastProcessed - 1) hardReset = true;
   if(hardReset)
     {
      ResetEngine();
      ArrayInitialize(SupBuf, 0.0); ArrayInitialize(ResBuf, 0.0); ArrayInitialize(PocBuf, 0.0);
      ArrayInitialize(VahBuf, 0.0); ArrayInitialize(ValBuf, 0.0); ArrayInitialize(ActBuf, 0.0); ArrayInitialize(AvgVolBuf, 0.0);
      SubReset(rates_total);
      g_firstBarTime = time[0];
     }
   g_prevRates = rates_total;

   int toCopy = (prev_calculated == 0 || hardReset) ? rates_total : rates_total - prev_calculated + 1;
   if(CopyBuffer(hAtr, 0, 0, toCopy, AtrBuf) <= 0) return prev_calculated;

   int last = rates_total - 1, lastClosed = rates_total - 2;
   int start0 = MathMax(warm, rates_total - 1 - InpMaxHistory);

   // sub-bar cache: history once, then one range per new closed bar
   if(g_useSub)
     {
      SubEnsureSize(rates_total);
      if(hardReset)
        {
         int from = MathMax(0, start0 - g_profLb);
         if(g_subLoadedTo < 0)
           {
            // wait a few ticks for lower-TF history to arrive before the first pass
            MqlRates probe[];
            int np = CopyRates(_Symbol, g_subTf, time[lastClosed], time[last] - 1, probe);
            if(np <= 0 && g_subWait < 30) { g_subWait++; g_lastProcessed = -1; return 0; }   // lower-TF history still downloading
            g_subWait = 0;
            SubLoad(from, lastClosed, time);
           }
        }
      else if(g_subLoadedTo < lastClosed) SubLoad(g_subLoadedTo + 1, lastClosed, time);
     }

   // activity / effective volume + 40-bar baseline
   int sStart = (hardReset || prev_calculated == 0) ? 0 : MathMax(0, prev_calculated - 1);
   for(int i = sStart; i < rates_total; i++)
     {
      int cnt = (g_useSub && i < ArraySize(g_subCount)) ? g_subCount[i] : 0;
      if(cnt > 0 && i < last) { double a = 0; for(int j = g_subStart[i]; j < g_subStart[i] + cnt; j++) a += g_subW[j]; ActBuf[i] = a; }
      else ActBuf[i] = VolAt(i, open, high, low, close, tick_volume, volume);
     }
   for(int i = sStart; i < rates_total; i++)
     {
      if(i < VOL_LEN - 1) { AvgVolBuf[i] = 0.0; continue; }
      double s = 0; for(int k = i - VOL_LEN + 1; k <= i; k++) s += ActBuf[k];
      AvgVolBuf[i] = s / VOL_LEN;
     }

   int start = (g_lastProcessed < 0) ? start0 : g_lastProcessed + 1;
   for(int i = start; i <= lastClosed; i++) ProcessConfirmedBar(i, time, open, high, low, close, tick_volume, volume);
   g_lastProcessed = MathMax(g_lastProcessed, lastClosed);
   if(g_lastProcessed >= 0 && g_lastProcessed < rates_total) g_lastProcessedTime = time[g_lastProcessed];
   g_liveMode = true;

   uint now = GetTickCount();
   bool newBar = (time[last] != g_lastRedrawBar);
   if(newBar || g_dirty || InpRedrawMs <= 0 || now - g_lastRedraw >= (uint)InpRedrawMs)
     {
      Render(last, open, high, low, close, tick_volume, volume);
      ChartRedraw();
      g_lastRedraw = now; g_lastRedrawBar = time[last]; g_dirty = false;
     }
   return rates_total;
  }
//+------------------------------------------------------------------+
