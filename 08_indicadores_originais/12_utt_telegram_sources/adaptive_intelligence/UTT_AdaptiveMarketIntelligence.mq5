//+------------------------------------------------------------------+
//|                          UTT_AdaptiveMarketIntelligence.mq5      |
//|        Adaptive Market Intelligence Engine - UTT Edition (AMIE)  |
//|                            Copyright 2026, UltimateTrading.tools |
//|                                  https://ultimatetrading.tools   |
//+------------------------------------------------------------------+
//|                                                                  |
//|  MetaTrader 5 port of                                            |
//|  "Buy-Sell with Adaptive Market Intelligence Engine" (Pine v6)   |
//|  Original Pine Script (c) InvestyourAsset.                       |
//|  Original work licensed under the Mozilla Public License 2.0     |
//|  https://mozilla.org/MPL/2.0/                                    |
//|  This port is a derivative work and remains under MPL 2.0.       |
//|  MPL 2.0 permits commercial use and distribution provided this   |
//|  notice is kept and the source of MPL-covered files stays        |
//|  available to recipients.                                        |
//|                                                                  |
//|  SEVEN ENGINES, ONE VERDICT                                      |
//|    Trend       EMA stack plus higher-timeframe confirmation      |
//|    Structure   internal + major pivots, BOS / CHOCH, retests,    |
//|                gradient strength bands between swing pairs       |
//|    Regime      ADX/DMI, Bollinger compression, ATR expansion     |
//|    Momentum    RSI and MACD histogram                            |
//|    Location    session VWAP (intraday) or mean EMA               |
//|    Volume      participation against its own average             |
//|    Score       all of the above resolved into 0-100 per side     |
//|                                                                  |
//|  A signal fires only at the START of a new trend: the score must |
//|  clear the minimum, beat the other side by the required margin,  |
//|  and pass every enabled filter.  One signal per trend, then the  |
//|  engine locks until the trend fails for N bars or reverses.      |
//|                                                                  |
//|  NON-REPAINTING                                                  |
//|  The original gates structure, retests and the signal state      |
//|  machine on barstate.isconfirmed.  This port takes EVERY         |
//|  decision on closed bars (rates_total-2).  Higher-timeframe data |
//|  reproduces Pine's lookahead_on + [1] idiom by reading the HTF   |
//|  bar that had already CLOSED - no future leak.                   |
//|                                                                  |
//|  INSTALLATION - single self-contained file, no includes          |
//|    MQL5/Indicators/UTT/UTT_AdaptiveMarketIntelligence.mq5        |
//|    Compile in MetaEditor (F7).                                   |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "UltimateTrading.tools - port of InvestyourAsset (MPL 2.0)"
#property link      "https://ultimatetrading.tools"
#property version   "1.00"
#property description "Adaptive Market Intelligence Engine (UTT Edition)."
#property description "Trend, structure, regime, momentum, location and participation"
#property description "resolved into a single 0-100 confluence score per side."
#property description "Non-repainting: all decisions taken on closed bars."
#property icon        "ULTIMATE LOGO.ICO"
#property indicator_chart_window
#property indicator_buffers 31
#property indicator_plots   24

//--- Plot 0 : EMA ribbon fill (buffers 0,1)
#property indicator_label1  "Ribbon"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  clrGreen,clrMaroon
//--- Plot 1 : fast EMA (buffers 2,3)
#property indicator_label2  "EMA Fast"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrLime,clrRed,clrGray
#property indicator_width2  1
//--- Plot 2 : slow EMA (buffers 4,5)
#property indicator_label3  "EMA Slow"
#property indicator_type3   DRAW_COLOR_LINE
#property indicator_color3  clrGreen,clrRed,clrGray
#property indicator_width3  2
//--- Plot 3 : VWAP / mean (buffer 6)
#property indicator_label4  "VWAP / Mean"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrDodgerBlue
#property indicator_width4  2
//--- Plot 4 : confluence candle colouring (buffers 7..11)
#property indicator_label5  "AMIE-O;AMIE-H;AMIE-L;AMIE-C"
#property indicator_type5   DRAW_COLOR_CANDLES
#property indicator_width5  1
//--- Plot 5 : new bull trend (buffer 12)
#property indicator_label6  "AMIE Buy"
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrLime
#property indicator_width6  3
//--- Plot 6 : new bear trend (buffer 13)
#property indicator_label7  "AMIE Sell"
#property indicator_type7   DRAW_ARROW
#property indicator_color7  clrRed
#property indicator_width7  3
//--- Plots 7..23 : machine-readable state (buffers 14..30) for iCustom
#property indicator_type8   DRAW_NONE
#property indicator_type9   DRAW_NONE
#property indicator_type10  DRAW_NONE
#property indicator_type11  DRAW_NONE
#property indicator_type12  DRAW_NONE
#property indicator_type13  DRAW_NONE
#property indicator_type14  DRAW_NONE
#property indicator_type15  DRAW_NONE
#property indicator_type16  DRAW_NONE
#property indicator_type17  DRAW_NONE
#property indicator_type18  DRAW_NONE
#property indicator_type19  DRAW_NONE
#property indicator_type20  DRAW_NONE
#property indicator_type21  DRAW_NONE
#property indicator_type22  DRAW_NONE
#property indicator_type23  DRAW_NONE
#property indicator_type24  DRAW_NONE

//==================================================================//
//                          ENUMERATIONS                            //
//==================================================================//
enum ENUM_AMIE_SIZE
  {
   AMIE_SIZE_AUTO   = 0, // Auto (by chart timeframe)
   AMIE_SIZE_TINY   = 1, // Tiny
   AMIE_SIZE_SMALL  = 2, // Small
   AMIE_SIZE_NORMAL = 3, // Normal
   AMIE_SIZE_LARGE  = 4  // Large
  };

enum ENUM_AMIE_VOLSRC
  {
   AMIE_VOL_TICK = 0, // Tick Volume (synthetics / crypto / FX)
   AMIE_VOL_REAL = 1  // Real Volume (exchange feeds)
  };

//--- regime codes, also published on a state buffer
#define AMIE_REG_TRANSITION  0
#define AMIE_REG_COMPRESSION 1
#define AMIE_REG_RANGE       2
#define AMIE_REG_TRENDEXP    3
#define AMIE_REG_TRENDING    4
#define AMIE_REG_VOLEXP      5

//==================================================================//
//                             INPUTS                               //
//==================================================================//

input group                 "=== 01. TREND ENGINE ==="
input int    InpFastLen          = 21;         // Fast EMA
input int    InpSlowLen          = 50;         // Slow EMA
input int    InpMeanLen          = 20;         // Non-intraday mean EMA
input bool   InpUseHTF           = true;       // Use higher-timeframe confirmation
input ENUM_TIMEFRAMES InpHTF     = PERIOD_H4;  // Higher timeframe

input group                 "=== 02. STRUCTURE ENGINE ==="
input int    InpInternalSwing    = 3;     // Internal swing length
input int    InpMajorSwing       = 8;     // Major swing length
input double InpBreakBufferATR   = 0.05;  // Structure break buffer (ATR)
input int    InpRetestWindow     = 18;    // Retest window (bars)
input double InpRetestTolATR     = 0.18;  // Retest tolerance (ATR)
input double InpRetestMaxPenATR  = 0.40;  // Maximum retest penetration (ATR)
input int    InpMinBandStrength  = 58;    // Minimum structure band strength
input double InpMinBandLegATR    = 0.70;  // Minimum band leg size (ATR)
input double InpBandWidthATR     = 0.18;  // Structure band width (ATR)
input int    InpRequiredPairs    = 2;     // Consecutive structure pairs

input group                 "=== 03. REGIME FILTER ==="
input int    InpDiLen            = 14;    // DMI length
input int    InpAdxSmooth        = 14;    // ADX smoothing
input double InpTrendAdx         = 22.0;  // Trending ADX
input double InpRangeAdx         = 18.0;  // Range ADX
input double InpMinEmaSepATR     = 0.20;  // Minimum EMA separation / ATR
input double InpStructSepATR     = 0.30;  // Structure activation separation / ATR
input int    InpAtrLen           = 14;    // ATR length
input int    InpAtrBaselineLen   = 50;    // ATR baseline
input double InpExpansionMult    = 1.10;  // Volatility expansion multiplier
input int    InpBbLen            = 20;    // Compression length
input double InpBbMult           = 2.0;   // BB deviation
input int    InpBbBaselineLen    = 50;    // Bandwidth baseline
input double InpCompressionMult  = 0.75;  // Compression threshold

input group                 "=== 04. MOMENTUM ENGINE ==="
input int    InpRsiLen           = 14;    // RSI length
input int    InpMacdFast         = 12;    // MACD fast
input int    InpMacdSlow         = 26;    // MACD slow
input int    InpMacdSignal       = 9;     // MACD signal

input group                 "=== 05. PARTICIPATION ==="
input bool   InpUseVolume        = true;  // Use volume
input int    InpVolumeLen        = 20;    // Volume average
input double InpVolumeMult       = 1.0;   // General volume multiplier
input ENUM_AMIE_VOLSRC InpVolSource = AMIE_VOL_TICK; // Volume source

input group                 "=== 06. NEW TREND SIGNAL ENGINE ==="
input int    InpMinSignalScore   = 86;    // New trend minimum score
input int    InpMinScoreAdvantage= 25;    // Minimum bull/bear advantage
input bool   InpRequireHTF       = true;  // Require HTF alignment
input bool   InpRequireVolume    = true;  // Require participation
input double InpSignalVolumeMult = 1.05;  // Signal volume multiplier
input int    InpTrendResetBars   = 6;     // Trend reset bars
input bool   InpRequireStructure = true;  // Require major structure alignment
input bool   InpRequireStrongADX = true;  // Require strong ADX / DMI

input group                 "=== 07. VISUAL SETTINGS ==="
input bool   InpShowRibbon       = true;            // EMA trend ribbon
input bool   InpShowMean         = true;            // VWAP / mean
input bool   InpShowBands        = true;            // Structure gradient bands
input color  InpBullBandColor    = clrLime;         // Uptrend structure band
input color  InpBearBandColor    = clrRed;          // Downtrend structure band
input int    InpBandTransparency = 87;              // Structure band transparency
input bool   InpShowInternal     = false;           // Internal structure labels
input bool   InpShowBreakLabels  = true;            // BOS / CHOCH labels
input bool   InpShowBreakLines   = true;            // BOS / CHOCH dashed lines
input bool   InpShowRetests      = true;            // Retest labels
input bool   InpColorCandles     = true;            // Confluence candle colouring
input bool   InpShowDashboard    = true;            // Market intelligence dashboard
input int    InpMaxBands         = 60;              // Max structure bands kept
input int    InpMaxMarkers       = 250;             // Max labels / markers kept

input group                 "=== UTT PANEL ==="
input ENUM_AMIE_SIZE InpPanelSize = AMIE_SIZE_AUTO; // Panel text size
input string InpFontName         = "Consolas";      // Panel / label font

input group                 "=== ALERTS ==="
input bool   InpEnableAlerts     = true;            // Enable alerts (master switch)
input bool   InpAlertPopup       = true;            // Alert: terminal popup
input bool   InpAlertPush        = false;           // Alert: mobile push notification
input bool   InpAlertEmail       = false;           // Alert: email
input bool   InpAlertSound       = true;            // Alert: sound
input string InpSoundFile        = "alert.wav";     // Alert sound file
input bool   InpAlertStructure   = false;           // Also alert on BOS / CHOCH

input group                 "=== PERFORMANCE ==="
input int    InpMaxBars          = 5000;  // Max bars to analyse
input int    InpInstanceId       = 1;     // Instance id (change for a 2nd copy on one chart)

//==================================================================//
//                       INDICATOR BUFFERS                          //
//==================================================================//
double BufFillA[];     // 0  ribbon fill upper
double BufFillB[];     // 1  ribbon fill lower
double BufFast[];      // 2  fast EMA
double BufFastC[];     // 3  fast EMA colour index
double BufSlow[];      // 4  slow EMA
double BufSlowC[];     // 5  slow EMA colour index
double BufMean[];      // 6  VWAP / mean
double BufCndO[];      // 7  confluence candle open
double BufCndH[];      // 8  high
double BufCndL[];      // 9  low
double BufCndC[];      // 10 close
double BufCndCol[];    // 11 candle colour index 0..10
double BufBuy[];       // 12 new bull trend arrow price
double BufSell[];      // 13 new bear trend arrow price
double BufBullScore[]; // 14 bull confluence score 0..100
double BufBearScore[]; // 15 bear confluence score 0..100
double BufScoreDiff[]; // 16 bull - bear
double BufSignal[];    // 17 new trend signal +1 / -1 / 0
double BufGrade[];     // 18 signal grade 0 none, 1 = A, 2 = A+
double BufTrendState[];// 19 trend state +1 / -1 / 0
double BufRegime[];    // 20 regime code 0..5
double BufBias[];      // 21 bias -2..+2
double BufStructDir[]; // 22 major structure +1 / -1 / 0
double BufAdx[];       // 23 ADX
double BufPlusDI[];    // 24 +DI
double BufMinusDI[];   // 25 -DI
double BufMajorHigh[]; // 26 last major swing high
double BufMajorLow[];  // 27 last major swing low
double BufRangeLoc[];  // 28 0 n/a, 1 discount, 2 equilibrium, 3 premium
double BufBreak[];     // 29 0 none, 1 bull BOS, 2 bull CHOCH, -1 bear BOS, -2 bear CHOCH
double BufRetest[];    // 30 retest +1 bull / -1 bear / 0

//==================================================================//
//                          CONSTANTS                               //
//==================================================================//
#define AMIE_SHORT  "UTT-AMIE"
string AMIE_PREFIX = "UAMIE_";     // made instance-unique in OnInit

//==================================================================//
//                       CACHED SERIES                              //
//  Indexed with (barIndex - g_off).  Everything is computed here    //
//  rather than through iXXX handles, because three of the series    //
//  MetaTrader ships do NOT match their Pine counterparts:           //
//    ta.atr  is Wilder's RMA;  iATR  is an SMA of true range        |
//    ta.macd signal is an EMA;  iMACD signal is an SMA              |
//    ta.dmi  takes separate DI and ADX lengths;  iADX takes one     |
//  Getting any of those wrong shifts every score and every signal.  |
//==================================================================//
double g_emaFast[];
double g_emaSlow[];
double g_emaMean[];
double g_rsi[];
double g_macdHist[];
double g_atr[];
double g_atrBase[];
double g_plusDI[];
double g_minusDI[];
double g_adx[];
double g_bbWidth[];
double g_bbWidthBase[];
double g_volD[];
double g_avgVol[];
double g_meanLine[];
double g_htfFast[];
double g_htfSlow[];
double g_htfClose[];

int    g_off   = 0;
int    g_count = 0;

//--- scratch for the HTF mapper
datetime g_chartTimes[];
datetime g_htfTimes[];
double   g_htfSrcClose[];
long     g_volRaw[];

ENUM_TIMEFRAMES g_htfTF     = PERIOD_H4;
int             g_htfRetries = 0;
bool            g_mtfOk       = true;  // HTF readings usable on THIS pass
bool            g_htfConfigOk = true;  // user configured a usable HTF at all
bool            g_htfDegraded = false; // committed on the chart fallback; reset in OnInit

//==================================================================//
//                        ENGINE STATE                              //
//==================================================================//
//--- internal structure
double g_prevInternalHigh = 0.0;
double g_prevInternalLow  = 0.0;
bool   g_hasInternalHigh  = false;
bool   g_hasInternalLow   = false;

//--- major structure
double g_prevMajorHigh = 0.0;
double g_prevMajorLow  = 0.0;
bool   g_hasPrevMajorHigh = false;
bool   g_hasPrevMajorLow  = false;

double g_lastMajorHigh = 0.0;
double g_lastMajorLow  = 0.0;
int    g_lastMajorHighBar = -1;
int    g_lastMajorLowBar  = -1;
int    g_lastMajorHighStrength = 0;
int    g_lastMajorLowStrength  = 0;
double g_lastMajorHighATR = 0.0;
double g_lastMajorLowATR  = 0.0;
bool   g_lastMajorHighBroken = false;
bool   g_lastMajorLowBroken  = false;
int    g_lastHighType = 0;    // 1 = HH, -1 = LH
int    g_lastLowType  = 0;    // 1 = HL, -1 = LL

int    g_bullPairCount = 0;
int    g_bearPairCount = 0;

//--- break / retest
int    g_externalDir       = 0;   // +1 after a bull break, -1 after a bear break
double g_lastBullBreakLevel = 0.0;
double g_lastBearBreakLevel = 0.0;
int    g_lastBullBreakBar  = -1;
int    g_lastBearBreakBar  = -1;
bool   g_bullRetestUsed    = true;
bool   g_bearRetestUsed    = true;

//--- signal state machine
int    g_trendState   = 0;
int    g_trendFailure = 0;

//--- object registries
int    g_bandIds[];
int    g_bandCount = 0;
int    g_markIds[];
int    g_markCount = 0;
int    g_objSeq    = 0;

//--- misc
datetime g_lastProcTime  = 0;
bool     g_firstPass     = true;
datetime g_liveBarTime   = 0;
datetime g_alertBarBull  = 0;
datetime g_alertBarBear  = 0;
datetime g_alertBarStructBull = 0;
datetime g_alertBarStructBear = 0;
int      g_warmup        = 400;
bool     g_dashDrawn     = false;  // cleared by AMIE_DeleteAll
int      g_shortCleared  = -1;    // buffer-wipe latches, reset in OnInit
int      g_waitCleared   = -1;

//--- dashboard snapshot (latest closed bar)
int    g_pBullScore  = 0;
int    g_pBearScore  = 0;
int    g_pScoreDiff  = 0;
int    g_pRegime     = AMIE_REG_TRANSITION;
string g_pBias       = "NEUTRAL";
string g_pTrendState = "NEUTRAL / ARMED";
string g_pSequence   = "MIXED";
string g_pStructure  = "UNDEFINED";
string g_pHtf        = "NEUTRAL";
string g_pSignalState= "WAIT";
string g_pRangeLoc   = "N/A";
double g_pAdx        = 0.0;
int    g_pResAge     = 9999;
int    g_pSupAge     = 9999;

//==================================================================//
//                       SMALL UTILITIES                            //
//==================================================================//
int AMIE_ClampI(const int v, const int lo, const int hi)
  {
   if(v < lo)
      return(lo);
   if(v > hi)
      return(hi);
   return(v);
  }

double AMIE_Clamp(const double v, const double lo, const double hi)
  {
   if(v < lo)
      return(lo);
   if(v > hi)
      return(hi);
   return(v);
  }

double AMIE_At(const double &arr[], const int bar)
  {
   int k = bar - g_off;
   if(k < 0 || k >= g_count)
      return(0.0);
   return(arr[k]);
  }

bool AMIE_HasBar(const int bar)
  {
   int k = bar - g_off;
   return(k >= 0 && k < g_count);
  }

//--- MQL5 colour is 0x00BBGGRR ------------------------------------
void AMIE_Split(const color c, int &r, int &g, int &b)
  {
   uint v = (uint)c;
   r = (int)(v & 0xFF);
   g = (int)((v >> 8) & 0xFF);
   b = (int)((v >> 16) & 0xFF);
  }

color AMIE_Make(const int r, const int g, const int b)
  {
   return((color)((uint)AMIE_ClampI(r, 0, 255)
                  | ((uint)AMIE_ClampI(g, 0, 255) << 8)
                  | ((uint)AMIE_ClampI(b, 0, 255) << 16)));
  }

//+------------------------------------------------------------------+
//| Pine's color.new(col, transparency) has no MT5 equivalent -      |
//| graphical objects are opaque.  Blending toward the chart          |
//| background reproduces what the eye sees on TradingView.           |
//+------------------------------------------------------------------+
color AMIE_Fade(const color c, const int transpPct)
  {
   int t = AMIE_ClampI(transpPct, 0, 100);
   if(t <= 0)
      return(c);

   color bgc = (color)ChartGetInteger(0, CHART_COLOR_BACKGROUND, 0);
   int r1, g1, b1, r2, g2, b2;
   AMIE_Split(c, r1, g1, b1);
   AMIE_Split(bgc, r2, g2, b2);

   double a = 1.0 - (double)t / 100.0;
   return(AMIE_Make((int)MathRound(r1 * a + r2 * (1.0 - a)),
                    (int)MathRound(g1 * a + g2 * (1.0 - a)),
                    (int)MathRound(b1 * a + b2 * (1.0 - a))));
  }

//--- linear colour interpolation (Pine color.from_gradient) --------
color AMIE_Lerp(const color a, const color b, const double t)
  {
   double u = AMIE_Clamp(t, 0.0, 1.0);
   int r1, g1, b1, r2, g2, b2;
   AMIE_Split(a, r1, g1, b1);
   AMIE_Split(b, r2, g2, b2);
   return(AMIE_Make((int)MathRound(r1 + (r2 - r1) * u),
                    (int)MathRound(g1 + (g2 - g1) * u),
                    (int)MathRound(b1 + (b2 - b1) * u)));
  }

color AMIE_PanelText()
  {
   return((color)ChartGetInteger(0, CHART_COLOR_FOREGROUND, 0));
  }

datetime AMIE_BarTime(const int idx, const int rates_total, const datetime &time[])
  {
   if(idx < 0)
      return(time[0]);
   if(idx <= rates_total - 1)
      return(time[idx]);
   int secs = PeriodSeconds((ENUM_TIMEFRAMES)_Period);
   return((datetime)(time[rates_total - 1] + (datetime)((idx - (rates_total - 1)) * secs)));
  }

//==================================================================//
//                       OBJECT HELPERS                             //
//==================================================================//
void AMIE_DeletePrefix(const string pfx)
  {
   int total = ObjectsTotal(0, -1, -1);
   for(int k = total - 1; k >= 0; k--)
     {
      string nm = ObjectName(0, k, -1, -1);
      if(StringFind(nm, pfx, 0) == 0)
         ObjectDelete(0, nm);
     }
  }

void AMIE_DeleteAll()
  {
   AMIE_DeletePrefix(AMIE_PREFIX);
   g_dashDrawn = false;   // the dashboard went with it - allow a redraw
  }

string AMIE_BandTag(const int id)
  {
   return(AMIE_PREFIX + "B" + IntegerToString(id) + "_");
  }

string AMIE_MarkTag(const int id)
  {
   return(AMIE_PREFIX + "M" + IntegerToString(id) + "_");
  }

void AMIE_RegisterBand(const int id)
  {
   int n = ArraySize(g_bandIds);
   if(ArrayResize(g_bandIds, n + 1) != n + 1)
      return;
   g_bandIds[n] = id;
   g_bandCount  = n + 1;

   int cap = MathMax(1, InpMaxBands);
   while(g_bandCount > cap)
     {
      AMIE_DeletePrefix(AMIE_BandTag(g_bandIds[0]));
      for(int k = 1; k < g_bandCount; k++)
         g_bandIds[k - 1] = g_bandIds[k];
      g_bandCount--;
      ArrayResize(g_bandIds, g_bandCount);
     }
  }

void AMIE_RegisterMark(const int id)
  {
   int n = ArraySize(g_markIds);
   if(ArrayResize(g_markIds, n + 1) != n + 1)
      return;
   g_markIds[n] = id;
   g_markCount  = n + 1;

   int cap = MathMax(1, InpMaxMarkers);
   while(g_markCount > cap)
     {
      AMIE_DeletePrefix(AMIE_MarkTag(g_markIds[0]));
      for(int k = 1; k < g_markCount; k++)
         g_markIds[k - 1] = g_markIds[k];
      g_markCount--;
      ArrayResize(g_markIds, g_markCount);
     }
  }

//+------------------------------------------------------------------+
//| A Pine linefill between two SLOPED lines is a parallelogram.     |
//| MT5 rectangles are axis-aligned and cannot follow a slope, so    |
//| each band half is drawn as two filled triangles sharing a        |
//| diagonal - the only MT5 primitive that fills a slanted shape.    |
//+------------------------------------------------------------------+
void AMIE_Tri(const string name,
              const datetime t1, const double p1,
              const datetime t2, const double p2,
              const datetime t3, const double p3,
              const color fill)
  {
   if(ObjectFind(0, name) < 0)
      if(!ObjectCreate(0, name, OBJ_TRIANGLE, 0, t1, p1, t2, p2, t3, p3))
         return;

   ObjectSetInteger(0, name, OBJPROP_TIME,  0, t1);
   ObjectSetDouble(0,  name, OBJPROP_PRICE, 0, p1);
   ObjectSetInteger(0, name, OBJPROP_TIME,  1, t2);
   ObjectSetDouble(0,  name, OBJPROP_PRICE, 1, p2);
   ObjectSetInteger(0, name, OBJPROP_TIME,  2, t3);
   ObjectSetDouble(0,  name, OBJPROP_PRICE, 2, p3);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      fill);
   ObjectSetInteger(0, name, OBJPROP_FILL,       true);
   ObjectSetInteger(0, name, OBJPROP_BACK,       true);
   ObjectSetInteger(0, name, OBJPROP_STYLE,      STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      1);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED,   false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,     true);
  }

void AMIE_Seg(const string name, const datetime t1, const double p1,
              const datetime t2, const double p2,
              const color clr, const ENUM_LINE_STYLE style, const int width)
  {
   if(ObjectFind(0, name) < 0)
      if(!ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2))
         return;

   ObjectSetInteger(0, name, OBJPROP_TIME,  0, t1);
   ObjectSetDouble(0,  name, OBJPROP_PRICE, 0, p1);
   ObjectSetInteger(0, name, OBJPROP_TIME,  1, t2);
   ObjectSetDouble(0,  name, OBJPROP_PRICE, 1, p2);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE,      style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      width);
   ObjectSetInteger(0, name, OBJPROP_RAY_LEFT,   false);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT,  false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED,   false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,     true);
   ObjectSetInteger(0, name, OBJPROP_BACK,       false);
  }

void AMIE_Text(const string name, const datetime t, const double p, const string txt,
               const color clr, const int fsize, const ENUM_ANCHOR_POINT anchor)
  {
   if(ObjectFind(0, name) < 0)
      if(!ObjectCreate(0, name, OBJ_TEXT, 0, t, p))
         return;

   ObjectSetInteger(0, name, OBJPROP_TIME,       0, t);
   ObjectSetDouble(0,  name, OBJPROP_PRICE,      0, p);
   ObjectSetString(0,  name, OBJPROP_TEXT,       txt);
   ObjectSetString(0,  name, OBJPROP_FONT,       InpFontName);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,   fsize);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR,     anchor);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED,   false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,     true);
   ObjectSetInteger(0, name, OBJPROP_BACK,       false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER,     10);
  }

//==================================================================//
//                    STRUCTURE STRENGTH (f_strength)               //
//==================================================================//
int AMIE_Strength(const double reactionATR, const double legATR,
                  const double volumeRatio, const bool htfAligned)
  {
   double reactionScore = AMIE_Clamp(reactionATR, 0.0, 2.0) / 2.0 * 30.0;
   double legScore      = AMIE_Clamp(legATR,      0.0, 4.0) / 4.0 * 25.0;
   double volumeScore   = AMIE_Clamp(volumeRatio, 0.0, 2.0) / 2.0 * 20.0;
   double htfScore      = (htfAligned ? 10.0 : 0.0);
   double total = 15.0 + reactionScore + legScore + volumeScore + htfScore;
   return((int)MathRound(MathMin(total, 100.0)));
  }

string AMIE_RegimeText(const int code)
  {
   switch(code)
     {
      case AMIE_REG_COMPRESSION:
         return("COMPRESSION");
      case AMIE_REG_RANGE:
         return("RANGE");
      case AMIE_REG_TRENDEXP:
         return("TREND EXPANSION");
      case AMIE_REG_TRENDING:
         return("TRENDING");
      case AMIE_REG_VOLEXP:
         return("VOL EXPANSION");
      default:
         return("TRANSITION");
     }
  }

string AMIE_Freshness(const int age)
  {
   if(age <= 20)
      return("FRESH");
   if(age <= 50)
      return("ACTIVE");
   return("AGED");
  }

//==================================================================//
//                     STRUCTURE GRADIENT BAND                      //
//==================================================================//
void AMIE_DrawBand(const int x1, const double y1, const int x2, const double y2,
                   const double referenceATR, const bool bullish, const int strength,
                   const int rates_total, const datetime &time[])
  {
   if(!InpShowBands)
      return;

   color baseColor = (bullish ? InpBullBandColor : InpBearBandColor);

   int coreTransp  = AMIE_ClampI(InpBandTransparency, 70, 96);
   int outerTransp = MathMin(coreTransp + 8, 99);

   //--- Pine: color.from_gradient(strength, 55, 100, faint, solid)
   double t = AMIE_Clamp(((double)strength - 55.0) / 45.0, 0.0, 1.0);
   int outerFadeT = (int)MathRound(99.0 + ((double)outerTransp - 99.0) * t);
   int innerFadeT = (int)MathRound(96.0 + ((double)coreTransp  - 96.0) * t);

   color outerFill = AMIE_Fade(baseColor, outerFadeT);
   color innerFill = AMIE_Fade(baseColor, innerFadeT);

   double outerOffset = referenceATR * InpBandWidthATR;
   double innerOffset = outerOffset * 0.52;

   g_objSeq++;
   int    id  = g_objSeq;
   string tag = AMIE_BandTag(id);

   datetime tA = AMIE_BarTime(x1, rates_total, time);
   datetime tB = AMIE_BarTime(x2, rates_total, time);

   //--- outer band: two triangles sharing the diagonal
   AMIE_Tri(tag + "O1", tA, y1 + outerOffset, tB, y2 + outerOffset,
            tB, y2 - outerOffset, outerFill);
   AMIE_Tri(tag + "O2", tA, y1 + outerOffset, tB, y2 - outerOffset,
            tA, y1 - outerOffset, outerFill);

   //--- inner band
   AMIE_Tri(tag + "I1", tA, y1 + innerOffset, tB, y2 + innerOffset,
            tB, y2 - innerOffset, innerFill);
   AMIE_Tri(tag + "I2", tA, y1 + innerOffset, tB, y2 - innerOffset,
            tA, y1 - innerOffset, innerFill);

   AMIE_RegisterBand(id);
  }

//==================================================================//
//                          DATA LAYER                              //
//==================================================================//
//--- Wilder's RMA step ---------------------------------------------
double AMIE_RmaStep(const double prev, const double value, const int len)
  {
   return((prev * (double)(len - 1) + value) / (double)len);
  }

//+------------------------------------------------------------------+
//| Map the higher timeframe onto chart bars.                        |
//|                                                                  |
//| The original uses request.security(..., close[1],                |
//| lookahead=barmerge.lookahead_on).  That idiom means "the HTF bar |
//| that had already CLOSED at this chart bar" - lookahead_on gives  |
//| correct alignment and the [1] offset removes the future leak.    |
//| Reading the last closed HTF bar reproduces it exactly.           |
//+------------------------------------------------------------------+
bool AMIE_MapHTF(const int count)
  {
   ArrayResize(g_htfFast,  count);
   ArrayResize(g_htfSlow,  count);
   ArrayResize(g_htfClose, count);
   ArrayInitialize(g_htfFast,  0.0);
   ArrayInitialize(g_htfSlow,  0.0);
   ArrayInitialize(g_htfClose, 0.0);

   //--- gate on the CONFIGURATION, not on g_mtfOk: while degraded
   //--- g_mtfOk is false and this must keep genuinely retrying,
   //--- otherwise it would report a phantom recovery every bar.
   if(!InpUseHTF || !g_htfConfigOk)
      return(true);

   double ratio = (double)PeriodSeconds(g_htfTF)
                  / (double)MathMax(1, PeriodSeconds((ENUM_TIMEFRAMES)_Period));
   int needH = (int)MathCeil((double)count / MathMax(1.0, ratio)) + 120;
   needH = MathMax(needH, 250);

   int availH = Bars(_Symbol, g_htfTF);
   if(availH <= 80)
      return(false);
   needH = MathMin(needH, availH);

   ArraySetAsSeries(g_htfTimes,    false);
   ArraySetAsSeries(g_htfSrcClose, false);
   ArraySetAsSeries(g_chartTimes,  false);

   if(CopyTime(_Symbol, g_htfTF, 0, needH, g_htfTimes) != needH)
      return(false);
   if(CopyClose(_Symbol, g_htfTF, 0, needH, g_htfSrcClose) != needH)
      return(false);
   if(CopyTime(_Symbol, PERIOD_CURRENT, 0, count, g_chartTimes) != count)
      return(false);

   //--- EMAs on the HTF close series, seeded with an SMA
   double hf[];
   double hs[];
   if(ArrayResize(hf, needH) != needH || ArrayResize(hs, needH) != needH)
      return(false);

   int    lf = MathMax(2, InpFastLen);
   int    ls = MathMax(3, InpSlowLen);
   double af = 2.0 / (lf + 1.0);
   double as = 2.0 / (ls + 1.0);
   double sf = 0.0, ss = 0.0;

   for(int k = 0; k < needH; k++)
     {
      double c = g_htfSrcClose[k];

      if(k < lf)
        {
         sf += c;
         hf[k] = sf / (double)(k + 1);
        }
      else
         hf[k] = (c - hf[k - 1]) * af + hf[k - 1];

      if(k < ls)
        {
         ss += c;
         hs[k] = ss / (double)(k + 1);
        }
      else
         hs[k] = (c - hs[k - 1]) * as + hs[k - 1];
     }

   //--- linear merge: both time arrays ascend
   int p = 0;
   for(int k = 0; k < count; k++)
     {
      datetime t = g_chartTimes[k];
      while(p + 1 < needH && g_htfTimes[p + 1] <= t)
         p++;

      //--- g_htfTimes[p] contains t and is still forming; the last
      //--- fully closed HTF bar is therefore p-1.
      int src = p - 1;
      if(g_htfTimes[p] > t)
         src = -1;
      if(src >= 0)
        {
         g_htfFast[k]  = hf[src];
         g_htfSlow[k]  = hs[src];
         g_htfClose[k] = g_htfSrcClose[src];
        }
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| Rebuild every cached series (once per new bar)                   |
//+------------------------------------------------------------------+
bool AMIE_UpdateData(const int rates_total, const datetime lastBarTime, const bool force,
                     const datetime &time[], const double &high[], const double &low[],
                     const double &close[], const long &tick_volume[], const long &real_volume[])
  {
   static datetime s_last = 0;

   if(!force && lastBarTime == s_last && g_count > 0)
      return(true);

   int need = MathMin(rates_total, MathMax(600, InpMaxBars) + g_warmup + 50);
   if(need < g_warmup + 10)
     {
      g_count = 0;
      return(false);
     }

   g_count = 0;                       // invalidate while filling
   int off = rates_total - need;

   //--- ta.vwap() accumulates from the true session start.  If the
   //--- rolling window happens to begin mid-session the first session's
   //--- VWAP would be wrong, which flips aboveMean/belowMean and moves
   //--- 10 confluence points - so pull the window back to the nearest
   //--- session boundary before anything is computed.
   bool intraday = (PeriodSeconds((ENUM_TIMEFRAMES)_Period) < 86400);
   if(intraday && off > 0)
     {
      MqlDateTime da, db;
      int guard = 0;
      while(off > 0 && guard < 2000)
        {
         TimeToStruct(time[off],     da);
         TimeToStruct(time[off - 1], db);
         if(da.day != db.day || da.mon != db.mon || da.year != db.year)
            break;
         off--;
         need++;
         guard++;
        }
     }

   if(ArrayResize(g_emaFast, need)     != need || ArrayResize(g_emaSlow, need)   != need ||
      ArrayResize(g_emaMean, need)     != need || ArrayResize(g_rsi, need)       != need ||
      ArrayResize(g_macdHist, need)    != need || ArrayResize(g_atr, need)       != need ||
      ArrayResize(g_atrBase, need)     != need || ArrayResize(g_plusDI, need)    != need ||
      ArrayResize(g_minusDI, need)     != need || ArrayResize(g_adx, need)       != need ||
      ArrayResize(g_bbWidth, need)     != need || ArrayResize(g_bbWidthBase, need) != need ||
      ArrayResize(g_volD, need)        != need || ArrayResize(g_avgVol, need)    != need ||
      ArrayResize(g_meanLine, need)    != need)
      return(false);

   //--- volume ------------------------------------------------------
   ArraySetAsSeries(g_volRaw, false);
   if(ArrayResize(g_volRaw, need) != need)
      return(false);

   int gotV = 0;
   if(InpVolSource == AMIE_VOL_REAL)
      gotV = CopyRealVolume(_Symbol, PERIOD_CURRENT, 0, need, g_volRaw);
   else
      gotV = CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, need, g_volRaw);
   if(gotV != need)
     {
      gotV = CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, need, g_volRaw);
      if(gotV != need)
         return(false);
     }

   //--- lengths -----------------------------------------------------
   int lf   = MathMax(2, InpFastLen);
   int ls   = MathMax(3, InpSlowLen);
   int lm   = MathMax(2, InpMeanLen);
   int lr   = MathMax(2, InpRsiLen);
   int lmf  = MathMax(2, InpMacdFast);
   int lmls = MathMax(3, InpMacdSlow);
   int lmsg = MathMax(2, InpMacdSignal);
   int lAtr = MathMax(2, InpAtrLen);
   int lAtrB= MathMax(10, InpAtrBaselineLen);
   int lDi  = MathMax(2, InpDiLen);
   int lAdx = MathMax(2, InpAdxSmooth);
   int lBb  = MathMax(5, InpBbLen);
   int lBbB = MathMax(10, InpBbBaselineLen);
   int lVol = MathMax(2, InpVolumeLen);

   double aF = 2.0 / (lf + 1.0);
   double aS = 2.0 / (ls + 1.0);
   double aM = 2.0 / (lm + 1.0);
   double aMF = 2.0 / (lmf + 1.0);
   double aMS = 2.0 / (lmls + 1.0);
   double aSG = 2.0 / (lmsg + 1.0);

   //--- running accumulators ---------------------------------------
   double sF = 0.0, sS = 0.0, sM = 0.0, sMF = 0.0, sMS = 0.0;
   double gainSum = 0.0, lossSum = 0.0, avgGain = 0.0, avgLoss = 0.0;
   double trSum = 0.0, trSumD = 0.0, pdmSum = 0.0, mdmSum = 0.0;
   double smTR = 0.0, smPDM = 0.0, smMDM = 0.0;
   double dxSum = 0.0, adxVal = 0.0;
   double macdEmaFast = 0.0, macdEmaSlow = 0.0, macdSig = 0.0, sigSum = 0.0;
   int    dxCount = 0;

   double vwapPV = 0.0, vwapV = 0.0;
   int    prevDay = -1;

   for(int k = 0; k < need; k++)
     {
      int    i = off + k;
      double c = close[k + off];

      //---------------- EMAs ---------------------------------------
      if(k < lf)
        {
         sF += c;
         g_emaFast[k] = sF / (double)(k + 1);
        }
      else
         g_emaFast[k] = (c - g_emaFast[k - 1]) * aF + g_emaFast[k - 1];

      if(k < ls)
        {
         sS += c;
         g_emaSlow[k] = sS / (double)(k + 1);
        }
      else
         g_emaSlow[k] = (c - g_emaSlow[k - 1]) * aS + g_emaSlow[k - 1];

      if(k < lm)
        {
         sM += c;
         g_emaMean[k] = sM / (double)(k + 1);
        }
      else
         g_emaMean[k] = (c - g_emaMean[k - 1]) * aM + g_emaMean[k - 1];

      //---------------- RSI (Wilder) --------------------------------
      if(k == 0)
        {
         g_rsi[k] = 50.0;
        }
      else
        {
         double diff = c - close[i - 1];
         double gain = (diff > 0.0 ? diff : 0.0);
         double loss = (diff < 0.0 ? -diff : 0.0);

         if(k <= lr)
           {
            gainSum += gain;
            lossSum += loss;
            avgGain  = gainSum / (double)lr;
            avgLoss  = lossSum / (double)lr;
           }
         else
           {
            avgGain = AMIE_RmaStep(avgGain, gain, lr);
            avgLoss = AMIE_RmaStep(avgLoss, loss, lr);
           }

         if(avgLoss <= 0.0)
            g_rsi[k] = (avgGain > 0.0 ? 100.0 : 50.0);
         else
           {
            double rs = avgGain / avgLoss;
            g_rsi[k] = 100.0 - 100.0 / (1.0 + rs);
           }
        }

      //---------------- MACD (EMA signal, like Pine) ----------------
      if(k < lmf)
        {
         sMF += c;
         macdEmaFast = sMF / (double)(k + 1);
        }
      else
         macdEmaFast = (c - macdEmaFast) * aMF + macdEmaFast;

      if(k < lmls)
        {
         sMS += c;
         macdEmaSlow = sMS / (double)(k + 1);
        }
      else
         macdEmaSlow = (c - macdEmaSlow) * aMS + macdEmaSlow;

      double macdLine = macdEmaFast - macdEmaSlow;

      if(k < lmsg)
        {
         sigSum += macdLine;
         macdSig = sigSum / (double)(k + 1);
        }
      else
         macdSig = (macdLine - macdSig) * aSG + macdSig;

      g_macdHist[k] = macdLine - macdSig;

      //---------------- true range ---------------------------------
      double tr = (i > 0
                   ? MathMax(high[i], close[i - 1]) - MathMin(low[i], close[i - 1])
                   : high[i] - low[i]);

      //---------------- ATR (Wilder) -------------------------------
      if(k < lAtr)
        {
         trSum += tr;
         g_atr[k] = trSum / (double)(k + 1);
        }
      else
         g_atr[k] = AMIE_RmaStep(g_atr[k - 1], tr, lAtr);

      //---------------- DMI / ADX (Pine ta.dmi) --------------------
      double upMove   = (i > 0 ? high[i] - high[i - 1] : 0.0);
      double downMove = (i > 0 ? low[i - 1] - low[i]   : 0.0);
      double plusDM   = ((upMove > downMove && upMove > 0.0) ? upMove : 0.0);
      double minusDM  = ((downMove > upMove && downMove > 0.0) ? downMove : 0.0);

      //--- Pine's ta.rma seeds with the SMA of the first `len` values
      if(k < lDi)
        {
         trSumD += tr;
         pdmSum += plusDM;
         mdmSum += minusDM;
         smTR   = trSumD / (double)(k + 1);
         smPDM  = pdmSum / (double)(k + 1);
         smMDM  = mdmSum / (double)(k + 1);
        }
      else
        {
         smTR  = AMIE_RmaStep(smTR,  tr,      lDi);
         smPDM = AMIE_RmaStep(smPDM, plusDM,  lDi);
         smMDM = AMIE_RmaStep(smMDM, minusDM, lDi);
        }

      double pdi = (smTR > 0.0 ? 100.0 * smPDM / smTR : 0.0);
      double mdi = (smTR > 0.0 ? 100.0 * smMDM / smTR : 0.0);
      g_plusDI[k]  = pdi;
      g_minusDI[k] = mdi;

      double diSum = pdi + mdi;
      double dx    = (diSum > 0.0 ? MathAbs(pdi - mdi) / diSum * 100.0 : 0.0);

      if(k >= lDi)
        {
         dxCount++;
         if(dxCount <= lAdx)
           {
            dxSum += dx;
            adxVal = dxSum / (double)dxCount;
           }
         else
            adxVal = AMIE_RmaStep(adxVal, dx, lAdx);
        }
      g_adx[k] = adxVal;

      //---------------- Bollinger bandwidth ------------------------
      if(k >= lBb - 1)
        {
         double sum = 0.0;
         for(int j = k - lBb + 1; j <= k; j++)
            sum += close[off + j];
         double basis = sum / (double)lBb;

         double var = 0.0;
         for(int j = k - lBb + 1; j <= k; j++)
           {
            double d = close[off + j] - basis;
            var += d * d;
           }
         double sd = MathSqrt(var / (double)lBb) * InpBbMult;

         g_bbWidth[k] = (MathAbs(basis) > DBL_EPSILON
                         ? 2.0 * sd / basis * 100.0
                         : 0.0);
        }
      else
         g_bbWidth[k] = 0.0;

      //---------------- volume -------------------------------------
      g_volD[k] = (double)g_volRaw[k];

      //---------------- session VWAP / mean ------------------------
      if(intraday)
        {
         MqlDateTime st;
         TimeToStruct(time[i], st);
         int dayId = st.year * 10000 + st.mon * 100 + st.day;
         if(dayId != prevDay)
           {
            vwapPV  = 0.0;
            vwapV   = 0.0;
            prevDay = dayId;
           }
         double hlc3 = (high[i] + low[i] + close[i]) / 3.0;
         vwapPV += hlc3 * g_volD[k];
         vwapV  += g_volD[k];
         g_meanLine[k] = (vwapV > 0.0 ? vwapPV / vwapV : g_emaMean[k]);
        }
      else
         g_meanLine[k] = g_emaMean[k];
     }

   //--- simple-moving-average baselines ------------------------------
   double run = 0.0;
   for(int k = 0; k < need; k++)
     {
      run += g_atr[k];
      if(k >= lAtrB)
         run -= g_atr[k - lAtrB];
      g_atrBase[k] = run / (double)MathMin(k + 1, lAtrB);
     }

   run = 0.0;
   for(int k = 0; k < need; k++)
     {
      run += g_bbWidth[k];
      if(k >= lBbB)
         run -= g_bbWidth[k - lBbB];
      g_bbWidthBase[k] = run / (double)MathMin(k + 1, lBbB);
     }

   run = 0.0;
   for(int k = 0; k < need; k++)
     {
      run += g_volD[k];
      if(k >= lVol)
         run -= g_volD[k - lVol];
      g_avgVol[k] = run / (double)MathMin(k + 1, lVol);
     }

   //--- higher timeframe ---------------------------------------------
   if(!AMIE_MapHTF(need))
     {
      g_htfRetries++;
      if(g_htfRetries <= 40)
        {
         g_count = 0;
         return(false);
        }
      if(g_htfRetries == 41)
         Print(AMIE_SHORT, ": higher timeframe data unavailable - falling back to the "
               "chart series, exactly as the original does when HTF is switched off.");
      //--- leaving g_mtfOk true here would zero every HTF reading, cap the
      //--- score at 80 and make signals impossible; the chart fallback is
      //--- what the original does when useHTF is false.
      g_mtfOk       = false;
      g_htfDegraded = true;
     }
   else
      if(g_htfDegraded)
        {
         //--- HTF finally arrived after a degraded commit: force one
         //--- repair pass so history is rescored with real HTF data
         g_htfDegraded = false;
         g_htfRetries  = 0;
         g_mtfOk       = g_htfConfigOk;
         g_count       = 0;
         Print(AMIE_SHORT, ": higher timeframe data available - rescoring history.");
         return(false);
        }
      else
         g_htfRetries = 0;

   g_off   = off;
   g_count = need;
   s_last  = lastBarTime;
   return(true);
  }

//==================================================================//
//                            PIVOTS                                //
//==================================================================//
//+------------------------------------------------------------------+
//| ta.pivothigh(high, L, L): confirmed at bar i, centred on i-L.    |
//| TradingView does not document tie handling; the reading its own  |
//| "Pivot Points High Low" ships with disqualifies an OLDER bar at  |
//| >= the centre and a NEWER bar only at > the centre, so a plateau |
//| yields a pivot at its first bar.  That is used here.             |
//+------------------------------------------------------------------+
bool AMIE_PivotHigh(const int i, const int L, const double &high[], double &value)
  {
   int c = i - L;
   if(c - L < 0)
      return(false);

   double hc = high[c];
   for(int j = c - L; j <= c + L; j++)
     {
      if(j == c)
         continue;
      if(j < c)
        {
         if(high[j] >= hc)
            return(false);
        }
      else
         if(high[j] > hc)
            return(false);
     }
   value = hc;
   return(true);
  }

bool AMIE_PivotLow(const int i, const int L, const double &low[], double &value)
  {
   int c = i - L;
   if(c - L < 0)
      return(false);

   double lc = low[c];
   for(int j = c - L; j <= c + L; j++)
     {
      if(j == c)
         continue;
      if(j < c)
        {
         if(low[j] <= lc)
            return(false);
        }
      else
         if(low[j] < lc)
            return(false);
     }
   value = lc;
   return(true);
  }

//==================================================================//
//                       BUFFER MAINTENANCE                         //
//==================================================================//
void AMIE_ClearBar(const int i)
  {
   if(i < 0 || i >= ArraySize(BufFast))
      return;
   BufFillA[i]     = EMPTY_VALUE;
   BufFillB[i]     = EMPTY_VALUE;
   BufFast[i]      = EMPTY_VALUE;
   BufFastC[i]     = 2.0;
   BufSlow[i]      = EMPTY_VALUE;
   BufSlowC[i]     = 2.0;
   BufMean[i]      = EMPTY_VALUE;
   BufCndO[i]      = EMPTY_VALUE;
   BufCndH[i]      = EMPTY_VALUE;
   BufCndL[i]      = EMPTY_VALUE;
   BufCndC[i]      = EMPTY_VALUE;
   BufCndCol[i]    = 5.0;
   BufBuy[i]       = EMPTY_VALUE;
   BufSell[i]      = EMPTY_VALUE;
   BufBullScore[i] = 0.0;
   BufBearScore[i] = 0.0;
   BufScoreDiff[i] = 0.0;
   BufSignal[i]    = 0.0;
   BufGrade[i]     = 0.0;
   BufTrendState[i]= 0.0;
   BufRegime[i]    = 0.0;
   BufBias[i]      = 0.0;
   BufStructDir[i] = 0.0;
   BufAdx[i]       = 0.0;
   BufPlusDI[i]    = 0.0;
   BufMinusDI[i]   = 0.0;
   BufMajorHigh[i] = 0.0;
   BufMajorLow[i]  = 0.0;
   BufRangeLoc[i]  = 0.0;
   BufBreak[i]     = 0.0;
   BufRetest[i]    = 0.0;
  }

void AMIE_ClearBuffers()
  {
   ArrayInitialize(BufFillA,     EMPTY_VALUE);
   ArrayInitialize(BufFillB,     EMPTY_VALUE);
   ArrayInitialize(BufFast,      EMPTY_VALUE);
   ArrayInitialize(BufFastC,     2.0);
   ArrayInitialize(BufSlow,      EMPTY_VALUE);
   ArrayInitialize(BufSlowC,     2.0);
   ArrayInitialize(BufMean,      EMPTY_VALUE);
   ArrayInitialize(BufCndO,      EMPTY_VALUE);
   ArrayInitialize(BufCndH,      EMPTY_VALUE);
   ArrayInitialize(BufCndL,      EMPTY_VALUE);
   ArrayInitialize(BufCndC,      EMPTY_VALUE);
   ArrayInitialize(BufCndCol,    5.0);
   ArrayInitialize(BufBuy,       EMPTY_VALUE);
   ArrayInitialize(BufSell,      EMPTY_VALUE);
   ArrayInitialize(BufBullScore, 0.0);
   ArrayInitialize(BufBearScore, 0.0);
   ArrayInitialize(BufScoreDiff, 0.0);
   ArrayInitialize(BufSignal,    0.0);
   ArrayInitialize(BufGrade,     0.0);
   ArrayInitialize(BufTrendState,0.0);
   ArrayInitialize(BufRegime,    0.0);
   ArrayInitialize(BufBias,      0.0);
   ArrayInitialize(BufStructDir, 0.0);
   ArrayInitialize(BufAdx,       0.0);
   ArrayInitialize(BufPlusDI,    0.0);
   ArrayInitialize(BufMinusDI,   0.0);
   ArrayInitialize(BufMajorHigh, 0.0);
   ArrayInitialize(BufMajorLow,  0.0);
   ArrayInitialize(BufRangeLoc,  0.0);
   ArrayInitialize(BufBreak,     0.0);
   ArrayInitialize(BufRetest,    0.0);
  }

void AMIE_ResetState()
  {
   g_lastProcTime = 0;

   g_prevInternalHigh = 0.0;
   g_prevInternalLow  = 0.0;
   g_hasInternalHigh  = false;
   g_hasInternalLow   = false;

   g_prevMajorHigh = 0.0;
   g_prevMajorLow  = 0.0;
   g_hasPrevMajorHigh = false;
   g_hasPrevMajorLow  = false;

   g_lastMajorHigh = 0.0;
   g_lastMajorLow  = 0.0;
   g_lastMajorHighBar = -1;
   g_lastMajorLowBar  = -1;
   g_lastMajorHighStrength = 0;
   g_lastMajorLowStrength  = 0;
   g_lastMajorHighATR = 0.0;
   g_lastMajorLowATR  = 0.0;
   g_lastMajorHighBroken = false;
   g_lastMajorLowBroken  = false;
   g_lastHighType = 0;
   g_lastLowType  = 0;

   g_bullPairCount = 0;
   g_bearPairCount = 0;

   g_externalDir        = 0;
   g_lastBullBreakLevel = 0.0;
   g_lastBearBreakLevel = 0.0;
   g_lastBullBreakBar   = -1;
   g_lastBearBreakBar   = -1;
   g_bullRetestUsed     = true;
   g_bearRetestUsed     = true;

   g_trendState   = 0;
   g_trendFailure = 0;

   g_bandCount = 0;
   g_markCount = 0;
   ArrayResize(g_bandIds, 0);
   ArrayResize(g_markIds, 0);
   g_objSeq = 0;

   g_pBullScore  = 0;
   g_pBearScore  = 0;
   g_pScoreDiff  = 0;
   g_pRegime     = AMIE_REG_TRANSITION;
   g_pBias       = "NEUTRAL";
   g_pTrendState = "NEUTRAL / ARMED";
   g_pSequence   = "MIXED";
   g_pStructure  = "UNDEFINED";
   g_pHtf        = "NEUTRAL";
   g_pSignalState= "WAIT";
   g_pRangeLoc   = "N/A";
   g_pAdx        = 0.0;
   g_pResAge     = 9999;
   g_pSupAge     = 9999;
  }

//==================================================================//
//                           ALERTS                                 //
//==================================================================//
bool AMIE_IsLiveBar(const datetime bt)
  {
   if(g_liveBarTime == 0)
      return(false);
   return(bt == g_liveBarTime);
  }

void AMIE_Dispatch(const string subject, const string body)
  {
   if(!InpEnableAlerts)
      return;

   string full = AMIE_SHORT + " " + _Symbol + " "
                 + EnumToString((ENUM_TIMEFRAMES)_Period)
                 + " | " + subject + " | " + body;

   if(InpAlertPopup)
      Alert(full);
   if(InpAlertPush)
      SendNotification(full);
   if(InpAlertEmail)
      SendMail(AMIE_SHORT + " " + subject, full);
   if(InpAlertSound && StringLen(InpSoundFile) > 0)
      PlaySound(InpSoundFile);

   Print(full);
  }

void AMIE_AlertSignal(const bool bullish, const datetime bt, const string grade,
                      const int score, const int diff,
                      const string regimeTxt, const string htfTxt)
  {
   if(!AMIE_IsLiveBar(bt))
      return;

   if(bullish)
     {
      if(g_alertBarBull == bt)
         return;
      g_alertBarBull = bt;
     }
   else
     {
      if(g_alertBarBear == bt)
         return;
      g_alertBarBear = bt;
     }

   AMIE_Dispatch(grade + (bullish ? " BUY - NEW TREND" : " SELL - NEW TREND"),
                 StringFormat("score %d | advantage %+d | regime %s | HTF %s",
                              score, diff, regimeTxt, htfTxt));
  }

void AMIE_AlertStructure(const string what, const datetime bt, const double level,
                         const bool bullish)
  {
   if(!InpAlertStructure || !AMIE_IsLiveBar(bt))
      return;

   //--- a bull and a bear break can land on the same closed bar
   if(bullish)
     {
      if(g_alertBarStructBull == bt)
         return;
      g_alertBarStructBull = bt;
     }
   else
     {
      if(g_alertBarStructBear == bt)
         return;
      g_alertBarStructBear = bt;
     }

   AMIE_Dispatch(what, "level " + DoubleToString(level, _Digits));
  }

//==================================================================//
//                      PER-BAR STATE MACHINE                       //
//==================================================================//
bool AMIE_ProcessBar(const int i, const int rates_total,
                     const datetime &time[], const double &open[], const double &high[],
                     const double &low[], const double &close[])
  {
   if(!AMIE_HasBar(i) || i < 2)
      return(false);

   AMIE_ClearBar(i);

//================== cached series for this bar =====================
   double emaFast = AMIE_At(g_emaFast, i);
   double emaSlow = AMIE_At(g_emaSlow, i);
   double meanLn  = AMIE_At(g_meanLine, i);
   double rsi     = AMIE_At(g_rsi, i);
   double macdH   = AMIE_At(g_macdHist, i);
   double atr     = AMIE_At(g_atr, i);
   double atrBase = AMIE_At(g_atrBase, i);
   double pdi     = AMIE_At(g_plusDI, i);
   double mdi     = AMIE_At(g_minusDI, i);
   double adx     = AMIE_At(g_adx, i);
   double bbw     = AMIE_At(g_bbWidth, i);
   double bbwBase = AMIE_At(g_bbWidthBase, i);
   double vol     = AMIE_At(g_volD, i);
   double avgVol  = AMIE_At(g_avgVol, i);

   double c = close[i];

//================== trend =========================================
   bool bullTrend = (emaFast > emaSlow && c > emaFast);
   bool bearTrend = (emaFast < emaSlow && c < emaFast);

//================== higher timeframe ==============================
   bool htfBull = false;
   bool htfBear = false;
   if(InpUseHTF && g_mtfOk)
     {
      double hf = AMIE_At(g_htfFast, i);
      double hs = AMIE_At(g_htfSlow, i);
      double hc = AMIE_At(g_htfClose, i);
      if(hf > 0.0 && hs > 0.0 && hc > 0.0)
        {
         htfBull = (hf > hs && hc > hf);
         htfBear = (hf < hs && hc < hf);
        }
     }
   else
     {
      //--- Pine falls back to the chart series when HTF is disabled
      htfBull = (emaFast > emaSlow && c > emaFast);
      htfBear = (emaFast < emaSlow && c < emaFast);
     }

   bool aboveMean = (c > meanLn);
   bool belowMean = (c < meanLn);

//================== momentum ======================================
   bool bullRSI  = (rsi > 52.0);
   bool bearRSI  = (rsi < 48.0);
   bool bullMACD = (macdH > 0.0);
   bool bearMACD = (macdH < 0.0);

//================== volatility / regime ===========================
   bool volatilityExpansion = (atrBase > 0.0 && atr > atrBase * InpExpansionMult);
   bool bullishADX = (adx >= InpTrendAdx && pdi > mdi);
   bool bearishADX = (adx >= InpTrendAdx && mdi > pdi);

   bool compression = (bbwBase > 0.0 && bbw < bbwBase * InpCompressionMult);

   double emaSepATR = (atr > 0.0 ? MathAbs(emaFast - emaSlow) / atr : 0.0);

   bool rangeBound = (compression ||
                      (adx < InpRangeAdx && emaSepATR < InpMinEmaSepATR));

   bool directionalRegime = (!rangeBound &&
                             (adx >= InpTrendAdx ||
                              emaSepATR >= InpStructSepATR ||
                              volatilityExpansion));

   //--- Pine gates this on barstate.isconfirmed; every bar we
   //--- process here is already closed, so the gate is implicit.
   bool structureAllowed = (directionalRegime && !rangeBound && !compression);

   int regimeCode = AMIE_REG_TRANSITION;
   if(compression)
      regimeCode = AMIE_REG_COMPRESSION;
   else
      if(rangeBound)
         regimeCode = AMIE_REG_RANGE;
      else
         if(directionalRegime && volatilityExpansion)
            regimeCode = AMIE_REG_TRENDEXP;
         else
            if(directionalRegime)
               regimeCode = AMIE_REG_TRENDING;
            else
               if(volatilityExpansion)
                  regimeCode = AMIE_REG_VOLEXP;

//================== volume ========================================
   bool hasVolume = (avgVol > 0.0);
   bool bullVolume = (hasVolume && vol > avgVol * InpVolumeMult && c > close[i - 1]);
   bool bearVolume = (hasVolume && vol > avgVol * InpVolumeMult && c < close[i - 1]);

//================== internal structure ============================
   int LI = MathMax(2, InpInternalSwing);
   double ipv;
   if(AMIE_PivotHigh(i, LI, high, ipv))
     {
      string txt = "iH";
      if(g_hasInternalHigh)
         txt = (ipv > g_prevInternalHigh ? "iHH" : "iLH");

      if(InpShowInternal)
        {
         g_objSeq++;
         string tag = AMIE_MarkTag(g_objSeq);
         AMIE_Text(tag + "T", AMIE_BarTime(i - LI, rates_total, time), ipv, txt,
                   AMIE_Fade(InpBearBandColor, 20), 7, ANCHOR_LEFT_LOWER);
         AMIE_RegisterMark(g_objSeq);
        }
      g_prevInternalHigh = ipv;
      g_hasInternalHigh  = true;
     }

   if(AMIE_PivotLow(i, LI, low, ipv))
     {
      string txt = "iL";
      if(g_hasInternalLow)
         txt = (ipv > g_prevInternalLow ? "iHL" : "iLL");

      if(InpShowInternal)
        {
         g_objSeq++;
         string tag = AMIE_MarkTag(g_objSeq);
         AMIE_Text(tag + "T", AMIE_BarTime(i - LI, rates_total, time), ipv, txt,
                   AMIE_Fade(InpBullBandColor, 20), 7, ANCHOR_LEFT_UPPER);
         AMIE_RegisterMark(g_objSeq);
        }
      g_prevInternalLow = ipv;
      g_hasInternalLow  = true;
     }

//================== major structure ===============================
   int LM = MathMax(4, InpMajorSwing);
   double mpv;

   //---------------------------- major HIGH -------------------------
   if(AMIE_PivotHigh(i, LM, high, mpv))
     {
      int pivotBar = i - LM;

      int currentHighType = 0;
      if(g_hasPrevMajorHigh)
         currentHighType = (mpv > g_prevMajorHigh ? 1 : -1);

      double pivotATR = AMIE_At(g_atr, pivotBar);
      if(pivotATR <= 0.0)
         pivotATR = atr;

      double reactionATR = 0.0;
      if(pivotATR > 0.0)
         reactionATR = MathMax(mpv - c, 0.0) / pivotATR;

      double legATR = 1.0;
      if(g_lastMajorLowBar >= 0 && pivotATR > 0.0)
         legATR = MathAbs(mpv - g_lastMajorLow) / pivotATR;

      double volumeRatio = 1.0;
      double pivAvgVol = AMIE_At(g_avgVol, pivotBar);
      if(pivAvgVol > 0.0)
         volumeRatio = AMIE_At(g_volD, pivotBar) / pivAvgVol;

      int strength = AMIE_Strength(reactionATR, legATR, volumeRatio, htfBear);

      bool bullishSeq = (currentHighType == 1 && g_lastLowType == 1);
      bool bearishSeq = (currentHighType == -1 && g_lastLowType == -1);

      if(InpShowBands && g_lastMajorLowBar >= 0 && (bullishSeq || bearishSeq))
        {
         int seqStrength = (int)MathRound((strength + g_lastMajorLowStrength) / 2.0);
         double seqATR = pivotATR;
         if(g_lastMajorLowATR > 0.0)
            seqATR = (pivotATR + g_lastMajorLowATR) / 2.0;

         if(seqStrength >= InpMinBandStrength && legATR >= InpMinBandLegATR)
            AMIE_DrawBand(g_lastMajorLowBar, g_lastMajorLow, pivotBar, mpv,
                          seqATR, bullishSeq, seqStrength, rates_total, time);
        }

      if(currentHighType == 1)
         g_bearPairCount = 0;
      else
         if(currentHighType == -1)
            g_bullPairCount = 0;

      g_lastMajorHigh         = mpv;
      g_lastMajorHighBar      = pivotBar;
      g_lastMajorHighStrength = strength;
      g_lastMajorHighATR      = pivotATR;
      g_lastMajorHighBroken   = false;
      g_lastHighType          = currentHighType;
      g_prevMajorHigh         = mpv;
      g_hasPrevMajorHigh      = true;
     }

   //---------------------------- major LOW --------------------------
   if(AMIE_PivotLow(i, LM, low, mpv))
     {
      int pivotBar = i - LM;

      int currentLowType = 0;
      if(g_hasPrevMajorLow)
         currentLowType = (mpv > g_prevMajorLow ? 1 : -1);

      double pivotATR = AMIE_At(g_atr, pivotBar);
      if(pivotATR <= 0.0)
         pivotATR = atr;

      double reactionATR = 0.0;
      if(pivotATR > 0.0)
         reactionATR = MathMax(c - mpv, 0.0) / pivotATR;

      double legATR = 1.0;
      if(g_lastMajorHighBar >= 0 && pivotATR > 0.0)
         legATR = MathAbs(g_lastMajorHigh - mpv) / pivotATR;

      double volumeRatio = 1.0;
      double pivAvgVol = AMIE_At(g_avgVol, pivotBar);
      if(pivAvgVol > 0.0)
         volumeRatio = AMIE_At(g_volD, pivotBar) / pivAvgVol;

      int strength = AMIE_Strength(reactionATR, legATR, volumeRatio, htfBull);

      bool bullishSeq = (currentLowType == 1 && g_lastHighType == 1);
      bool bearishSeq = (currentLowType == -1 && g_lastHighType == -1);

      if(InpShowBands && g_lastMajorHighBar >= 0 && (bullishSeq || bearishSeq))
        {
         int seqStrength = (int)MathRound((strength + g_lastMajorHighStrength) / 2.0);
         double seqATR = pivotATR;
         if(g_lastMajorHighATR > 0.0)
            seqATR = (pivotATR + g_lastMajorHighATR) / 2.0;

         if(seqStrength >= InpMinBandStrength && legATR >= InpMinBandLegATR)
            AMIE_DrawBand(g_lastMajorHighBar, g_lastMajorHigh, pivotBar, mpv,
                          seqATR, bullishSeq, seqStrength, rates_total, time);
        }

      bool completedBull = (currentLowType == 1 && g_lastHighType == 1);
      bool completedBear = (currentLowType == -1 && g_lastHighType == -1);

      if(completedBull)
        {
         g_bearPairCount = 0;
         g_bullPairCount++;
        }
      else
         if(completedBear)
           {
            g_bullPairCount = 0;
            g_bearPairCount++;
           }
         else
           {
            if(currentLowType == -1)
               g_bullPairCount = 0;
            if(currentLowType == 1)
               g_bearPairCount = 0;
           }

      g_lastMajorLow         = mpv;
      g_lastMajorLowBar      = pivotBar;
      g_lastMajorLowStrength = strength;
      g_lastMajorLowATR      = pivotATR;
      g_lastMajorLowBroken   = false;
      g_lastLowType          = currentLowType;
      g_prevMajorLow         = mpv;
      g_hasPrevMajorLow      = true;
     }

//================== BOS / CHOCH ===================================
   bool bullBreak = false, bearBreak = false;
   bool bullCHOCH = false, bearCHOCH = false;

   bool bullCandidate = (g_lastMajorHighBar >= 0 && !g_lastMajorHighBroken &&
                         c > g_lastMajorHigh + atr * InpBreakBufferATR);
   bool bearCandidate = (g_lastMajorLowBar >= 0 && !g_lastMajorLowBroken &&
                         c < g_lastMajorLow - atr * InpBreakBufferATR);

   if(structureAllowed && bullCandidate)
     {
      bullBreak = true;
      bullCHOCH = (g_externalDir == -1);
      g_lastMajorHighBroken = true;
     }
   if(structureAllowed && bearCandidate)
     {
      bearBreak = true;
      bearCHOCH = (g_externalDir == 1);
      g_lastMajorLowBroken = true;
     }

   if(bullBreak)
     {
      string txt = (bullCHOCH ? "CHOCH" : "BOS");
      color  clr = (bullCHOCH ? clrAqua : InpBullBandColor);

      if(InpShowBreakLines || InpShowBreakLabels)
        {
         g_objSeq++;
         string tag = AMIE_MarkTag(g_objSeq);
         if(InpShowBreakLines)
            AMIE_Seg(tag + "L", AMIE_BarTime(g_lastMajorHighBar, rates_total, time),
                     g_lastMajorHigh, AMIE_BarTime(i, rates_total, time), g_lastMajorHigh,
                     AMIE_Fade(clr, 20), STYLE_DASH, 2);
         if(InpShowBreakLabels)
            AMIE_Text(tag + "T", AMIE_BarTime(i, rates_total, time), g_lastMajorHigh,
                      txt, clr, 8, ANCHOR_LEFT_UPPER);
         AMIE_RegisterMark(g_objSeq);
        }

      g_lastBullBreakLevel = g_lastMajorHigh;
      g_lastBullBreakBar   = i;
      g_bullRetestUsed     = false;
      g_bearRetestUsed     = true;
      g_externalDir        = 1;

      BufBreak[i] = (bullCHOCH ? 2.0 : 1.0);
      AMIE_AlertStructure(bullCHOCH ? "BULL CHOCH" : "BULL BOS", time[i], g_lastMajorHigh, true);
     }

   if(bearBreak)
     {
      string txt = (bearCHOCH ? "CHOCH" : "BOS");
      color  clr = (bearCHOCH ? clrOrange : InpBearBandColor);

      if(InpShowBreakLines || InpShowBreakLabels)
        {
         g_objSeq++;
         string tag = AMIE_MarkTag(g_objSeq);
         if(InpShowBreakLines)
            AMIE_Seg(tag + "L", AMIE_BarTime(g_lastMajorLowBar, rates_total, time),
                     g_lastMajorLow, AMIE_BarTime(i, rates_total, time), g_lastMajorLow,
                     AMIE_Fade(clr, 20), STYLE_DASH, 2);
         if(InpShowBreakLabels)
            AMIE_Text(tag + "T", AMIE_BarTime(i, rates_total, time), g_lastMajorLow,
                      txt, clr, 8, ANCHOR_LEFT_LOWER);
         AMIE_RegisterMark(g_objSeq);
        }

      g_lastBearBreakLevel = g_lastMajorLow;
      g_lastBearBreakBar   = i;
      g_bearRetestUsed     = false;
      g_bullRetestUsed     = true;
      g_externalDir        = -1;

      BufBreak[i] = (bearCHOCH ? -2.0 : -1.0);
      AMIE_AlertStructure(bearCHOCH ? "BEAR CHOCH" : "BEAR BOS", time[i], g_lastMajorLow, false);
     }

//================== retest ========================================
   bool bullWindow = (g_lastBullBreakBar >= 0 && i > g_lastBullBreakBar &&
                      i <= g_lastBullBreakBar + InpRetestWindow);
   bool bearWindow = (g_lastBearBreakBar >= 0 && i > g_lastBearBreakBar &&
                      i <= g_lastBearBreakBar + InpRetestWindow);

   bool bullTouch = (bullWindow && !g_bullRetestUsed &&
                     low[i] <= g_lastBullBreakLevel + atr * InpRetestTolATR &&
                     low[i] >= g_lastBullBreakLevel - atr * InpRetestMaxPenATR);
   bool bearTouch = (bearWindow && !g_bearRetestUsed &&
                     high[i] >= g_lastBearBreakLevel - atr * InpRetestTolATR &&
                     high[i] <= g_lastBearBreakLevel + atr * InpRetestMaxPenATR);

   if(!rangeBound && bullTouch && c > g_lastBullBreakLevel && c > open[i])
     {
      g_bullRetestUsed = true;
      BufRetest[i] = 1.0;
      if(InpShowRetests)
        {
         g_objSeq++;
         string tag = AMIE_MarkTag(g_objSeq);
         AMIE_Text(tag + "R", AMIE_BarTime(i, rates_total, time), low[i],
                   "R>S RETEST", InpBullBandColor, 7, ANCHOR_LEFT_UPPER);
         AMIE_RegisterMark(g_objSeq);
        }
     }

   if(!rangeBound && bearTouch && c < g_lastBearBreakLevel && c < open[i])
     {
      g_bearRetestUsed = true;
      BufRetest[i] = -1.0;
      if(InpShowRetests)
        {
         g_objSeq++;
         string tag = AMIE_MarkTag(g_objSeq);
         AMIE_Text(tag + "R", AMIE_BarTime(i, rates_total, time), high[i],
                   "S>R RETEST", InpBearBandColor, 7, ANCHOR_LEFT_LOWER);
         AMIE_RegisterMark(g_objSeq);
        }
     }

//================== major range ===================================
   int rangeLoc = 0;
   bool validRange = (g_lastMajorHighBar >= 0 && g_lastMajorLowBar >= 0 &&
                      g_lastMajorHigh > g_lastMajorLow);
   if(validRange)
     {
      double rng  = g_lastMajorHigh - g_lastMajorLow;
      double eq   = (g_lastMajorHigh + g_lastMajorLow) / 2.0;
      double tol  = rng * 0.05;
      if(c > eq + tol)
         rangeLoc = 3;                  // PREMIUM
      else
         if(c < eq - tol)
            rangeLoc = 1;               // DISCOUNT
         else
            rangeLoc = 2;               // EQUILIBRIUM
     }

//================== confluence score ==============================
   bool bullishStructure = (g_externalDir == 1);
   bool bearishStructure = (g_externalDir == -1);

   int bullScore = 0;
   int bearScore = 0;

   bullScore += (bullTrend ? 15 : 0);
   bearScore += (bearTrend ? 15 : 0);
   bullScore += (htfBull ? 20 : 0);
   bearScore += (htfBear ? 20 : 0);
   bullScore += (bullishStructure ? 20 : 0);
   bearScore += (bearishStructure ? 20 : 0);
   bullScore += (bullRSI ? 10 : 0) + (bullMACD ? 5 : 0);
   bearScore += (bearRSI ? 10 : 0) + (bearMACD ? 5 : 0);
   bullScore += (aboveMean ? 10 : 0);
   bearScore += (belowMean ? 10 : 0);

   if(InpUseVolume && hasVolume)
     {
      bullScore += (bullVolume ? 10 : 0);
      bearScore += (bearVolume ? 10 : 0);
     }
   else
     {
      bullScore += 5;
      bearScore += 5;
     }

   bullScore += (bullishADX ? 10 : 0);
   bearScore += (bearishADX ? 10 : 0);

   int scoreDiff = bullScore - bearScore;

   int biasCode = 0;
   if(scoreDiff >= 35)
      biasCode = 2;
   else
      if(scoreDiff >= 15)
         biasCode = 1;
      else
         if(scoreDiff <= -35)
            biasCode = -2;
         else
            if(scoreDiff <= -15)
               biasCode = -1;

//================== signal filters ================================
   bool bullHtfOK = true, bearHtfOK = true;
   if(InpRequireHTF && InpUseHTF && g_mtfOk)
     {
      bullHtfOK = htfBull;
      bearHtfOK = htfBear;
     }

   bool bullPartOK = true, bearPartOK = true;
   if(InpRequireVolume && InpUseVolume && hasVolume)
     {
      bullPartOK = (vol >= avgVol * InpSignalVolumeMult && c > open[i]);
      bearPartOK = (vol >= avgVol * InpSignalVolumeMult && c < open[i]);
     }

   bool bullStructOK = true, bearStructOK = true;
   if(InpRequireStructure)
     {
      bullStructOK = bullishStructure;
      bearStructOK = bearishStructure;
     }

   bool bullAdxOK = true, bearAdxOK = true;
   if(InpRequireStrongADX)
     {
      bullAdxOK = bullishADX;
      bearAdxOK = bearishADX;
     }

   bool confirmedBull = (!rangeBound && !compression && directionalRegime &&
                         bullTrend && aboveMean && bullHtfOK && bullStructOK &&
                         bullAdxOK && bullPartOK &&
                         bullScore >= InpMinSignalScore &&
                         scoreDiff >= InpMinScoreAdvantage);

   bool confirmedBear = (!rangeBound && !compression && directionalRegime &&
                         bearTrend && belowMean && bearHtfOK && bearStructOK &&
                         bearAdxOK && bearPartOK &&
                         bearScore >= InpMinSignalScore &&
                         scoreDiff <= -InpMinScoreAdvantage);

//================== one signal per trend ==========================
   bool newBull = false, newBear = false;

   if(g_trendState == 0)
     {
      g_trendFailure = 0;
      if(confirmedBull)
        {
         g_trendState = 1;
         newBull = true;
        }
      else
         if(confirmedBear)
           {
            g_trendState = -1;
            newBear = true;
           }
     }
   else
      if(g_trendState == 1)
        {
         if(confirmedBear)
           {
            g_trendState   = -1;
            g_trendFailure = 0;
            newBear = true;
           }
         else
           {
            bool healthy = (bullTrend && !rangeBound && !compression && scoreDiff > 0);
            if(healthy)
               g_trendFailure = 0;
            else
               g_trendFailure++;

            if(g_trendFailure >= InpTrendResetBars)
              {
               g_trendState   = 0;
               g_trendFailure = 0;
              }
           }
        }
      else
         if(g_trendState == -1)
           {
            if(confirmedBull)
              {
               g_trendState   = 1;
               g_trendFailure = 0;
               newBull = true;
              }
            else
              {
               bool healthy = (bearTrend && !rangeBound && !compression && scoreDiff < 0);
               if(healthy)
                  g_trendFailure = 0;
               else
                  g_trendFailure++;

               if(g_trendFailure >= InpTrendResetBars)
                 {
                  g_trendState   = 0;
                  g_trendFailure = 0;
                 }
              }
           }

//================== dashboard snapshot ============================
   g_pBullScore = bullScore;
   g_pBearScore = bearScore;
   g_pScoreDiff = scoreDiff;
   g_pRegime    = regimeCode;
   g_pAdx       = adx;
   g_pResAge    = (g_lastMajorHighBar >= 0 ? i - g_lastMajorHighBar : 9999);
   g_pSupAge    = (g_lastMajorLowBar  >= 0 ? i - g_lastMajorLowBar  : 9999);

   g_pBias = "NEUTRAL";
   if(biasCode == 2)
      g_pBias = "STRONG BULLISH";
   else
      if(biasCode == 1)
         g_pBias = "BULLISH";
      else
         if(biasCode == -2)
            g_pBias = "STRONG BEARISH";
         else
            if(biasCode == -1)
               g_pBias = "BEARISH";

   g_pTrendState = "NEUTRAL / ARMED";
   if(g_trendState == 1)
      g_pTrendState = "BULL TREND ACTIVE";
   else
      if(g_trendState == -1)
         g_pTrendState = "BEAR TREND ACTIVE";

   g_pSequence = "MIXED";
   if(g_bullPairCount >= InpRequiredPairs)
      g_pSequence = "BULL x" + IntegerToString(g_bullPairCount);
   else
      if(g_bearPairCount >= InpRequiredPairs)
         g_pSequence = "BEAR x" + IntegerToString(g_bearPairCount);
      else
         if(g_bullPairCount > 0)
            g_pSequence = StringFormat("BULL BUILD %d/%d", g_bullPairCount, InpRequiredPairs);
         else
            if(g_bearPairCount > 0)
               g_pSequence = StringFormat("BEAR BUILD %d/%d", g_bearPairCount, InpRequiredPairs);

   g_pStructure = "UNDEFINED";
   if(bullishStructure)
      g_pStructure = "BULLISH";
   else
      if(bearishStructure)
         g_pStructure = "BEARISH";

   g_pHtf = "NEUTRAL";
   if(htfBull)
      g_pHtf = "BULLISH";
   else
      if(htfBear)
         g_pHtf = "BEARISH";

   g_pRangeLoc = "N/A";
   if(rangeLoc == 1)
      g_pRangeLoc = "DISCOUNT";
   else
      if(rangeLoc == 2)
         g_pRangeLoc = "EQUILIBRIUM";
      else
         if(rangeLoc == 3)
            g_pRangeLoc = "PREMIUM";

   g_pSignalState = "WAIT";
   if(rangeBound || compression)
      g_pSignalState = "WAIT - RANGE";
   else
      if(g_trendState == 1)
         g_pSignalState = "BUY USED";
      else
         if(g_trendState == -1)
            g_pSignalState = "SELL USED";
         else
            if(confirmedBull)
               g_pSignalState = "BULL START READY";
            else
               if(confirmedBear)
                  g_pSignalState = "BEAR START READY";


//================== signal grade + labels =========================
   string bullGrade = ((bullScore >= 92 && scoreDiff >= 35) ? "A+" : "A");
   string bearGrade = ((bearScore >= 92 && scoreDiff <= -35) ? "A+" : "A");

   if(newBull)
     {
      BufBuy[i]    = low[i] - atr * 0.45;
      BufSignal[i] = 1.0;
      BufGrade[i]  = (bullGrade == "A+" ? 2.0 : 1.0);

      g_objSeq++;
      string tag = AMIE_MarkTag(g_objSeq);
      AMIE_Text(tag + "S", AMIE_BarTime(i, rates_total, time), low[i] - atr * 0.25,
                bullGrade + " BUY  NEW TREND",
                (bullGrade == "A+" ? InpBullBandColor : clrGreen), 9, ANCHOR_LEFT_UPPER);
      AMIE_RegisterMark(g_objSeq);

      AMIE_AlertSignal(true, time[i], bullGrade, bullScore, scoreDiff,
                       AMIE_RegimeText(regimeCode), g_pHtf);
     }

   if(newBear)
     {
      BufSell[i]   = high[i] + atr * 0.45;
      BufSignal[i] = -1.0;
      BufGrade[i]  = (bearGrade == "A+" ? 2.0 : 1.0);

      g_objSeq++;
      string tag = AMIE_MarkTag(g_objSeq);
      AMIE_Text(tag + "S", AMIE_BarTime(i, rates_total, time), high[i] + atr * 0.25,
                bearGrade + " SELL  NEW TREND",
                (bearGrade == "A+" ? InpBearBandColor : clrMaroon), 9, ANCHOR_LEFT_LOWER);
      AMIE_RegisterMark(g_objSeq);

      AMIE_AlertSignal(false, time[i], bearGrade, bearScore, scoreDiff,
                       AMIE_RegimeText(regimeCode), g_pHtf);
     }

//================== plot buffers ==================================
   if(InpShowRibbon)
     {
      BufFast[i]  = emaFast;
      BufSlow[i]  = emaSlow;
      BufFillA[i] = emaFast;
      BufFillB[i] = emaSlow;
      double ci = 2.0;
      if(bullTrend)
         ci = 0.0;
      else
         if(bearTrend)
            ci = 1.0;
      BufFastC[i] = ci;
      BufSlowC[i] = ci;
     }

   if(InpShowMean)
      BufMean[i] = meanLn;

   if(InpColorCandles)
     {
      BufCndO[i] = open[i];
      BufCndH[i] = high[i];
      BufCndL[i] = low[i];
      BufCndC[i] = close[i];
      //--- Pine: color.from_gradient(scoreDiff, -100, 100, red, lime)
      double t = AMIE_Clamp(((double)scoreDiff + 100.0) / 200.0, 0.0, 1.0);
      BufCndCol[i] = MathRound(t * 10.0);
     }

//================== state buffers =================================
   BufBullScore[i]  = (double)bullScore;
   BufBearScore[i]  = (double)bearScore;
   BufScoreDiff[i]  = (double)scoreDiff;
   BufTrendState[i] = (double)g_trendState;
   BufRegime[i]     = (double)regimeCode;
   BufBias[i]       = (double)biasCode;
   BufStructDir[i]  = (double)g_externalDir;
   BufAdx[i]        = adx;
   BufPlusDI[i]     = pdi;
   BufMinusDI[i]    = mdi;
   BufMajorHigh[i]  = (g_lastMajorHighBar >= 0 ? g_lastMajorHigh : 0.0);
   BufMajorLow[i]   = (g_lastMajorLowBar  >= 0 ? g_lastMajorLow  : 0.0);
   BufRangeLoc[i]   = (double)rangeLoc;

   return(true);
  }

//==================================================================//
//                          DASHBOARD                               //
//==================================================================//
int AMIE_FontSize()
  {
   ENUM_AMIE_SIZE s = InpPanelSize;
   if(s == AMIE_SIZE_AUTO)
     {
      int secs = PeriodSeconds((ENUM_TIMEFRAMES)_Period);
      if(secs <= 300)
         s = AMIE_SIZE_TINY;
      else
         if(secs <= 1800)
            s = AMIE_SIZE_SMALL;
         else
            if(secs <= 86400)
               s = AMIE_SIZE_NORMAL;
            else
               s = AMIE_SIZE_LARGE;
     }
   switch(s)
     {
      case AMIE_SIZE_TINY:
         return(6);
      case AMIE_SIZE_SMALL:
         return(7);
      case AMIE_SIZE_LARGE:
         return(10);
      default:
         return(8);
     }
  }

//--- measured text width; guessing character widths is what makes
//--- panels overlap on narrow charts
int AMIE_TextW(const string s, const int fs, int &heightOut)
  {
   uint w = 0, h = 0;
   if(TextGetSize(s, w, h) && w > 0)
     {
      heightOut = (int)h;
      return((int)w);
     }
   heightOut = fs + 4;
   return((int)MathRound(StringLen(s) * (fs * 0.62 + 1.0)));
  }

void AMIE_PanelBg(const string name, const int x, const int y, const int w, const int h)
  {
   if(ObjectFind(0, name) < 0)
      if(!ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
         return;

   ObjectSetInteger(0, name, OBJPROP_CORNER,      CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,   x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,   y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE,       w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,       h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,     AMIE_Fade(AMIE_PanelText(), 88));
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_COLOR,       AMIE_Fade(AMIE_PanelText(), 55));
   ObjectSetInteger(0, name, OBJPROP_BACK,        false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,  false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED,    false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,      true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER,      0);
  }

void AMIE_PanelRule(const string name, const int x, const int y, const int w)
  {
   if(ObjectFind(0, name) < 0)
      if(!ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
         return;

   ObjectSetInteger(0, name, OBJPROP_CORNER,      CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,   x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,   y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE,       w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,       1);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,     AMIE_Fade(AMIE_PanelText(), 60));
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_COLOR,       AMIE_Fade(AMIE_PanelText(), 60));
   ObjectSetInteger(0, name, OBJPROP_BACK,        false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,  false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED,    false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,      true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER,      1);
  }

void AMIE_Cell(const string name, const int x, const int y, const string txt,
               const color clr, const int fsize, const ENUM_ANCHOR_POINT anchor)
  {
   if(ObjectFind(0, name) < 0)
      if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
         return;

   ObjectSetInteger(0, name, OBJPROP_CORNER,     CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,  x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,  y);
   ObjectSetString(0,  name, OBJPROP_TEXT,       txt);
   ObjectSetString(0,  name, OBJPROP_FONT,       InpFontName);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,   fsize);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR,     anchor);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED,   false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,     true);
   ObjectSetInteger(0, name, OBJPROP_BACK,       false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER,     5);
  }

void AMIE_DrawDashboard()
  {
   static bool s_cleared = false;
   if(!InpShowDashboard)
     {
      if(!s_cleared)
        {
         AMIE_DeletePrefix(AMIE_PREFIX + "P");
         s_cleared   = true;
         g_dashDrawn = false;
        }
      return;
     }
   s_cleared = false;

   const int ROWS = 12;
   string labFull[12], labShort[12], valFull[12], valShort[12];
   color  valCol[12];

   color txt  = AMIE_PanelText();
   color dim  = AMIE_Fade(txt, 42);
   color bull = InpBullBandColor;
   color bear = InpBearBandColor;

   string regimeTxt = "TRANSITION";
   color  regimeCol = dim;
   if(g_pRegime == AMIE_REG_COMPRESSION)
     {
      regimeTxt = "COMPRESSION";
      regimeCol = clrOrange;
     }
   else
      if(g_pRegime == AMIE_REG_RANGE)
        {
         regimeTxt = "RANGE";
         regimeCol = clrOrange;
        }
      else
         if(g_pRegime == AMIE_REG_TRENDEXP)
           {
            regimeTxt = "TREND EXPANSION";
            regimeCol = clrDodgerBlue;
           }
         else
            if(g_pRegime == AMIE_REG_TRENDING)
              {
               regimeTxt = "TRENDING";
               regimeCol = txt;
              }
            else
               if(g_pRegime == AMIE_REG_VOLEXP)
                 {
                  regimeTxt = "VOL EXPANSION";
                  regimeCol = clrDodgerBlue;
                 }

   color biasCol = dim;
   if(StringFind(g_pBias, "BULL", 0) >= 0)
      biasCol = bull;
   else
      if(StringFind(g_pBias, "BEAR", 0) >= 0)
         biasCol = bear;

   labFull[0]  = "Regime";          labShort[0] = "Regime";
   valFull[0]  = regimeTxt;         valShort[0] = regimeTxt;
   valCol[0]   = regimeCol;

   labFull[1]  = "Bias";            labShort[1] = "Bias";
   valFull[1]  = g_pBias;           valShort[1] = g_pBias;
   valCol[1]   = biasCol;

   color tsCol = clrOrange;
   if(g_trendState == 1)
      tsCol = bull;
   else
      if(g_trendState == -1)
         tsCol = bear;
   labFull[2]  = "Trend State";     labShort[2] = "Trend";
   valFull[2]  = g_pTrendState;     valShort[2] = g_pTrendState;
   valCol[2]   = tsCol;

   color seqCol = dim;
   if(StringFind(g_pSequence, "BULL", 0) >= 0)
      seqCol = bull;
   else
      if(StringFind(g_pSequence, "BEAR", 0) >= 0)
         seqCol = bear;
   labFull[3]  = "Structure Build"; labShort[3] = "Build";
   valFull[3]  = g_pSequence;       valShort[3] = g_pSequence;
   valCol[3]   = seqCol;

   labFull[4]  = "Bull Score";      labShort[4] = "Bull";
   valFull[4]  = StringFormat("%d/100", g_pBullScore);
   valShort[4] = IntegerToString(g_pBullScore);
   valCol[4]   = bull;

   labFull[5]  = "Bear Score";      labShort[5] = "Bear";
   valFull[5]  = StringFormat("%d/100", g_pBearScore);
   valShort[5] = IntegerToString(g_pBearScore);
   valCol[5]   = bear;

   color stCol = dim;
   if(g_pStructure == "BULLISH")
      stCol = bull;
   else
      if(g_pStructure == "BEARISH")
         stCol = bear;
   labFull[6]  = "Major Structure"; labShort[6] = "Struct";
   valFull[6]  = g_pStructure;      valShort[6] = g_pStructure;
   valCol[6]   = stCol;

   color htfCol = dim;
   if(g_pHtf == "BULLISH")
      htfCol = bull;
   else
      if(g_pHtf == "BEARISH")
         htfCol = bear;
   labFull[7]  = "HTF";             labShort[7] = "HTF";
   valFull[7]  = g_pHtf;            valShort[7] = g_pHtf;
   valCol[7]   = htfCol;

   string resTxt = "N/A";
   string resShort = "-";
   if(g_lastMajorHighBar >= 0)
     {
      resTxt = DoubleToString(g_lastMajorHigh, _Digits) + " | "
               + IntegerToString(g_lastMajorHighStrength) + " | "
               + AMIE_Freshness(g_pResAge);
      resShort = DoubleToString(g_lastMajorHigh, _Digits);
     }
   labFull[8]  = "Resistance";      labShort[8] = "Res";
   valFull[8]  = resTxt;            valShort[8] = resShort;
   valCol[8]   = bear;

   string supTxt = "N/A";
   string supShort = "-";
   if(g_lastMajorLowBar >= 0)
     {
      supTxt = DoubleToString(g_lastMajorLow, _Digits) + " | "
               + IntegerToString(g_lastMajorLowStrength) + " | "
               + AMIE_Freshness(g_pSupAge);
      supShort = DoubleToString(g_lastMajorLow, _Digits);
     }
   labFull[9]  = "Support";         labShort[9] = "Sup";
   valFull[9]  = supTxt;            valShort[9] = supShort;
   valCol[9]   = bull;

   color rlCol = dim;
   if(g_pRangeLoc == "DISCOUNT")
      rlCol = bull;
   else
      if(g_pRangeLoc == "PREMIUM")
         rlCol = clrOrange;
   labFull[10] = "Range Location";  labShort[10] = "Range";
   valFull[10] = g_pRangeLoc;       valShort[10] = g_pRangeLoc;
   valCol[10]  = rlCol;

   color ssCol = clrOrange;
   if(StringFind(g_pSignalState, "BUY", 0) >= 0 || StringFind(g_pSignalState, "BULL", 0) >= 0)
      ssCol = bull;
   else
      if(StringFind(g_pSignalState, "SELL", 0) >= 0 || StringFind(g_pSignalState, "BEAR", 0) >= 0)
         ssCol = bear;
   labFull[11] = "Signal State";    labShort[11] = "Signal";
   valFull[11] = g_pSignalState;    valShort[11] = g_pSignalState;
   valCol[11]  = ssCol;

   string headFull  = "UTT  ADAPTIVE MARKET INTELLIGENCE";
   string headShort = "UTT  AMIE";

//--- measured fit ---------------------------------------------------
   static int    s_fs       = 0;
   static int    s_W        = 0;
   static int    s_H        = 0;
   static int    s_rowH     = 0;
   static bool   s_useShort = false;
   static long   s_chartW   = -1;
   static string s_sig      = "";

   long chartW = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);
   if(chartW <= 0)
      chartW = 800;

   int    fsBase = AMIE_FontSize();
   //--- the palette feeds every cell colour, so a chart colour-scheme
   //--- change must invalidate the cache too
   string sig    = IntegerToString(fsBase) + "|" + InpFontName + "|"
                   + IntegerToString((long)ChartGetInteger(0, CHART_COLOR_FOREGROUND, 0)) + "|"
                   + IntegerToString((long)ChartGetInteger(0, CHART_COLOR_BACKGROUND, 0)) + "|";
   for(int r = 0; r < ROWS; r++)
      sig += valFull[r] + "|";

   bool changed = (sig != s_sig || chartW != s_chartW);
   if(changed)
     {
      s_sig    = sig;
      s_chartW = chartW;

      int pad = 8, gap = 12, margin = 6;
      int maxW = (int)chartW - margin - 6;
      if(maxW < 90)
         maxW = 90;

      bool fitted = false;
      for(int attempt = 0; attempt < 2 && !fitted; attempt++)
        {
         bool useShort = (attempt == 1);
         for(int fs = fsBase; fs >= 6; fs--)
           {
            TextSetFont(InpFontName, -fs * 10, 0, 0);
            int th = 0, tw = 0, rowH = 0, labW = 0, valW = 0;

            int headW = AMIE_TextW(useShort ? headShort : headFull, fs, th);
            if(th > rowH)
               rowH = th;

            for(int r = 0; r < ROWS; r++)
              {
               tw = AMIE_TextW(useShort ? labShort[r] : labFull[r], fs, th);
               if(tw > labW)
                  labW = tw;
               if(th > rowH)
                  rowH = th;

               tw = AMIE_TextW(useShort ? valShort[r] : valFull[r], fs, th);
               if(tw > valW)
                  valW = tw;
               if(th > rowH)
                  rowH = th;
              }

            if(rowH <= 0)
               rowH = fs + 4;

            int inner = MathMax(headW, labW + gap + valW);
            int W = inner + pad * 2;

            if(W <= maxW || (fs == 6 && useShort))
              {
               s_fs       = fs;
               s_W        = MathMin(W, maxW);
               s_rowH     = rowH + 5;
               s_H        = pad * 2 + (s_rowH + 6) + ROWS * s_rowH;
               s_useShort = useShort;
               fitted     = (W <= maxW);
               if(fitted)
                  break;
              }
           }
        }
     }

//--- draw ------------------------------------------------------------
//--- nothing to repaint when neither the text nor the geometry moved
   if(!changed && g_dashDrawn)
      return;
   g_dashDrawn = true;

   int fs   = (s_fs > 0 ? s_fs : fsBase);
   int W    = (s_W  > 0 ? s_W  : 200);
   int H    = (s_H  > 0 ? s_H  : 200);
   int rowH = (s_rowH > 0 ? s_rowH : fs + 7);
   int pad  = 8;
   int mX   = 6;
   int mY   = 16;

   string P = AMIE_PREFIX + "P";
   AMIE_PanelBg(P + "BG", mX, mY, W, H);

   int xL = mX + W - pad;
   int xR = mX + pad;
   int y  = mY + pad;

   AMIE_Cell(P + "H", xL, y, (s_useShort ? headShort : headFull), txt, fs, ANCHOR_LEFT_UPPER);
   y += rowH + 2;

   AMIE_PanelRule(P + "RULE", xL, y, W - pad * 2);
   y += 4;

   for(int r = 0; r < ROWS; r++)
     {
      string tag = P + "R" + IntegerToString(r);
      AMIE_Cell(tag + "a", xL, y, (s_useShort ? labShort[r] : labFull[r]),
                dim, fs, ANCHOR_LEFT_UPPER);
      AMIE_Cell(tag + "b", xR, y, (s_useShort ? valShort[r] : valFull[r]),
                valCol[r], fs, ANCHOR_RIGHT_UPPER);
      y += rowH;
     }
  }

//+------------------------------------------------------------------+
//| Custom indicator initialisation function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,  BufFillA,      INDICATOR_DATA);
   SetIndexBuffer(1,  BufFillB,      INDICATOR_DATA);
   SetIndexBuffer(2,  BufFast,       INDICATOR_DATA);
   SetIndexBuffer(3,  BufFastC,      INDICATOR_COLOR_INDEX);
   SetIndexBuffer(4,  BufSlow,       INDICATOR_DATA);
   SetIndexBuffer(5,  BufSlowC,      INDICATOR_COLOR_INDEX);
   SetIndexBuffer(6,  BufMean,       INDICATOR_DATA);
   SetIndexBuffer(7,  BufCndO,       INDICATOR_DATA);
   SetIndexBuffer(8,  BufCndH,       INDICATOR_DATA);
   SetIndexBuffer(9,  BufCndL,       INDICATOR_DATA);
   SetIndexBuffer(10, BufCndC,       INDICATOR_DATA);
   SetIndexBuffer(11, BufCndCol,     INDICATOR_COLOR_INDEX);
   SetIndexBuffer(12, BufBuy,        INDICATOR_DATA);
   SetIndexBuffer(13, BufSell,       INDICATOR_DATA);
   SetIndexBuffer(14, BufBullScore,  INDICATOR_DATA);
   SetIndexBuffer(15, BufBearScore,  INDICATOR_DATA);
   SetIndexBuffer(16, BufScoreDiff,  INDICATOR_DATA);
   SetIndexBuffer(17, BufSignal,     INDICATOR_DATA);
   SetIndexBuffer(18, BufGrade,      INDICATOR_DATA);
   SetIndexBuffer(19, BufTrendState, INDICATOR_DATA);
   SetIndexBuffer(20, BufRegime,     INDICATOR_DATA);
   SetIndexBuffer(21, BufBias,       INDICATOR_DATA);
   SetIndexBuffer(22, BufStructDir,  INDICATOR_DATA);
   SetIndexBuffer(23, BufAdx,        INDICATOR_DATA);
   SetIndexBuffer(24, BufPlusDI,     INDICATOR_DATA);
   SetIndexBuffer(25, BufMinusDI,    INDICATOR_DATA);
   SetIndexBuffer(26, BufMajorHigh,  INDICATOR_DATA);
   SetIndexBuffer(27, BufMajorLow,   INDICATOR_DATA);
   SetIndexBuffer(28, BufRangeLoc,   INDICATOR_DATA);
   SetIndexBuffer(29, BufBreak,      INDICATOR_DATA);
   SetIndexBuffer(30, BufRetest,     INDICATOR_DATA);

   for(int p = 0; p < 24; p++)
      PlotIndexSetDouble(p, PLOT_EMPTY_VALUE, EMPTY_VALUE);

//--- ribbon fill and EMA colours ------------------------------------
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 0, AMIE_Fade(InpBullBandColor, 89));
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 1, AMIE_Fade(InpBearBandColor, 89));

   PlotIndexSetInteger(1, PLOT_COLOR_INDEXES, 3);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, 0, InpBullBandColor);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, 1, InpBearBandColor);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, 2, clrGray);

   PlotIndexSetInteger(2, PLOT_COLOR_INDEXES, 3);
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, 0, AMIE_Fade(InpBullBandColor, 10));
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, 1, AMIE_Fade(InpBearBandColor, 10));
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, 2, clrGray);

//--- confluence candle gradient: 11 steps from bear to bull ---------
   PlotIndexSetInteger(4, PLOT_COLOR_INDEXES, 11);
   for(int s = 0; s < 11; s++)
     {
      color g = AMIE_Lerp(InpBearBandColor, InpBullBandColor, (double)s / 10.0);
      PlotIndexSetInteger(4, PLOT_LINE_COLOR, s, AMIE_Fade(g, 48));
     }

   PlotIndexSetInteger(5, PLOT_ARROW, 233);
   PlotIndexSetInteger(6, PLOT_ARROW, 234);
   PlotIndexSetInteger(5, PLOT_ARROW_SHIFT,  14);
   PlotIndexSetInteger(6, PLOT_ARROW_SHIFT, -14);
   PlotIndexSetInteger(5, PLOT_LINE_COLOR, InpBullBandColor);
   PlotIndexSetInteger(6, PLOT_LINE_COLOR, InpBearBandColor);

   PlotIndexSetString(7,  PLOT_LABEL, "BullScore");
   PlotIndexSetString(8,  PLOT_LABEL, "BearScore");
   PlotIndexSetString(9,  PLOT_LABEL, "ScoreDiff");
   PlotIndexSetString(10, PLOT_LABEL, "Signal");
   PlotIndexSetString(11, PLOT_LABEL, "Grade");
   PlotIndexSetString(12, PLOT_LABEL, "TrendState");
   PlotIndexSetString(13, PLOT_LABEL, "Regime");
   PlotIndexSetString(14, PLOT_LABEL, "Bias");
   PlotIndexSetString(15, PLOT_LABEL, "StructureDir");
   PlotIndexSetString(16, PLOT_LABEL, "ADX");
   PlotIndexSetString(17, PLOT_LABEL, "PlusDI");
   PlotIndexSetString(18, PLOT_LABEL, "MinusDI");
   PlotIndexSetString(19, PLOT_LABEL, "MajorHigh");
   PlotIndexSetString(20, PLOT_LABEL, "MajorLow");
   PlotIndexSetString(21, PLOT_LABEL, "RangeLocation");
   PlotIndexSetString(22, PLOT_LABEL, "BreakEvent");
   PlotIndexSetString(23, PLOT_LABEL, "Retest");

   IndicatorSetString(INDICATOR_SHORTNAME, AMIE_SHORT);
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

//--- warm-up must cover every lookback plus Wilder seed decay -------
   int maxLen = MathMax(MathMax(InpSlowLen, InpMacdSlow + InpMacdSignal),
                        MathMax(InpAtrBaselineLen, InpBbBaselineLen));
   g_warmup = MathMax(maxLen * 3, 2 * InpMajorSwing + 20) + 120;

   for(int p = 0; p < 24; p++)
      PlotIndexSetInteger(p, PLOT_DRAW_BEGIN, g_warmup);

//--- higher timeframe validation ------------------------------------
   g_htfTF = (InpHTF == PERIOD_CURRENT ? (ENUM_TIMEFRAMES)_Period : InpHTF);
   g_htfConfigOk = (PeriodSeconds(g_htfTF) > PeriodSeconds((ENUM_TIMEFRAMES)_Period));
   g_mtfOk       = g_htfConfigOk;
   if(InpUseHTF && !g_htfConfigOk)
      Print(AMIE_SHORT, ": WARNING - higher timeframe (", EnumToString(g_htfTF),
            ") must be larger than the chart timeframe. MTF layer disabled.");

   if(InpMinScoreAdvantage > InpMinSignalScore)
      Print(AMIE_SHORT, ": WARNING - minimum advantage exceeds minimum score; "
            "signals will be very rare.");

   AMIE_PREFIX = "UAMIE" + IntegerToString(InpInstanceId < 1 ? 1 : InpInstanceId) + "_";

   AMIE_ResetState();
   g_shortCleared  = -1;
   g_waitCleared   = -1;
   g_htfRetries    = 0;      // re-init must restore the full HTF grace window
   g_htfDegraded   = false;  // ...and must not report a phantom recovery
   g_firstPass     = true;
   g_alertBarBull       = 0;
   g_alertBarBear       = 0;
   g_alertBarStructBull = 0;
   g_alertBarStructBear = 0;
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator de-initialisation function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   AMIE_DeleteAll();
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
   if(rates_total < g_warmup + 20)
     {
      if(g_shortCleared != rates_total)
        {
         AMIE_ClearBuffers();
         g_shortCleared = rates_total;
        }
      return(0);
     }

   bool fullPass = (prev_calculated == 0);

   if(!AMIE_UpdateData(rates_total, time[rates_total - 1], fullPass,
                       time, high, low, close, tick_volume, volume))
     {
      //--- Seven plotted series here, including DRAW_FILLING and
      //--- DRAW_COLOR_CANDLES.  A stray 0.0 in any of them drags the
      //--- price scale to zero, so they must be wiped while we wait
      //--- for the HTF / history to load.
      if(g_waitCleared != rates_total)
        {
         AMIE_ClearBuffers();
         g_waitCleared = rates_total;
        }
      return(0);
     }

   if(fullPass)
     {
      AMIE_ResetState();
      AMIE_DeleteAll();
      AMIE_ClearBuffers();
     }

//--- alerts fire only for this exact bar; on the first attach the
//--- de-dupe cursors are seeded so the pre-attach bar stays silent
   g_liveBarTime = time[rates_total - 2];
   if(fullPass && g_firstPass)
     {
      g_alertBarBull       = g_liveBarTime;
      g_alertBarBear       = g_liveBarTime;
      g_alertBarStructBull = g_liveBarTime;
      g_alertBarStructBear = g_liveBarTime;
     }

   int lastClosed = rates_total - 2;
   int first      = g_off + g_warmup;
   if(prev_calculated > 1)
      first = MathMax(first, prev_calculated - 2);
   if(first < 2)
      first = 2;

   for(int i = first; i <= lastClosed; i++)
     {
      if(time[i] <= g_lastProcTime)
         continue;
      if(AMIE_ProcessBar(i, rates_total, time, open, high, low, close))
         g_lastProcTime = time[i];
     }

   if(!fullPass)
      g_firstPass = false;

//--- the forming bar carries no signal, but the plotted overlays
//--- extend onto it so the ribbon and mean line do not stop short
   AMIE_ClearBar(rates_total - 1);

   int live = rates_total - 1;
   if(AMIE_HasBar(lastClosed))
     {
      if(InpShowRibbon)
        {
         BufFast[live]  = AMIE_At(g_emaFast, lastClosed);
         BufSlow[live]  = AMIE_At(g_emaSlow, lastClosed);
         BufFillA[live] = BufFast[live];
         BufFillB[live] = BufSlow[live];
         BufFastC[live] = BufFastC[lastClosed];
         BufSlowC[live] = BufSlowC[lastClosed];
        }
      if(InpShowMean)
         BufMean[live] = AMIE_At(g_meanLine, lastClosed);
     }

   AMIE_DrawDashboard();
   ChartRedraw();

   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Keep the dashboard anchored when the chart is resized            |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   if(id == CHARTEVENT_CHART_CHANGE)
     {
      AMIE_DrawDashboard();
      ChartRedraw();
     }
  }
//+------------------------------------------------------------------+
