//+------------------------------------------------------------------+
//|                                  UTT_WickSequenceBreakout.mq5    |
//|                  Wick Sequence Breakout  -  UTT Edition (WSB)    |
//|                            Copyright 2026, UltimateTrading.tools |
//|                                  https://ultimatetrading.tools   |
//+------------------------------------------------------------------+
//|                                                                  |
//|  MetaTrader 5 port of "Wick Sequence Breakout" (Pine v6)         |
//|  Original Pine Script (c) Uncle_the_shooter.                     |
//|  Original work licensed under the Mozilla Public License 2.0     |
//|  https://mozilla.org/MPL/2.0/                                    |
//|  This port is a derivative work and remains under MPL 2.0.       |
//|  MPL 2.0 permits commercial use and distribution provided this   |
//|  notice is kept and the source of MPL-covered files stays        |
//|  available to recipients.                                        |
//|                                                                  |
//|  THE IDEA                                                        |
//|  A cluster of candles rejecting from one side (long upper wicks  |
//|  = sellers defending; long lower wicks = buyers defending) marks  |
//|  a zone.  The high/low of that cluster becomes a box.  A signal   |
//|  fires only when price breaks the box AND the breakout direction  |
//|  agrees with the side that owned the volume inside the box.       |
//|                                                                  |
//|  PIPELINE                                                        |
//|    1. classify each candle as a bull-wick / bear-wick candle      |
//|    2. count them inside a rolling window (min N of Y)             |
//|    3. on a fresh one-sided formation, open a box at the window's  |
//|       high/low and split the enclosed volume buy vs sell          |
//|    4. wait for a break of the box (high/low or close)             |
//|    5. signal only when break direction == dominant volume side    |
//|    6. draw Entry / SL / TP1 / TP2 / TP3 with risk-reward fills    |
//|                                                                  |
//|  NON-REPAINTING                                                   |
//|  Every classification, formation, breakout, timeout and signal    |
//|  decision is taken on CLOSED bars only (rates_total-2 gate).      |
//|  The original Pine evaluates the breakout intrabar; this port      |
//|  deliberately waits for the bar to close so a printed signal can   |
//|  never be withdrawn.  Boxes and TP/SL lines still extend to the   |
//|  live bar for monitoring - that is presentation, not logic.       |
//|                                                                  |
//|  INSTALLATION - single self-contained file, no includes           |
//|    MQL5/Indicators/UTT/UTT_WickSequenceBreakout.mq5               |
//|    Compile in MetaEditor (F7).                                    |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "UltimateTrading.tools - port of Uncle_the_shooter (MPL 2.0)"
#property link      "https://ultimatetrading.tools"
#property version   "1.00"
#property description "Wick Sequence Breakout (UTT Edition) - wick-cluster formation boxes,"
#property description "volume-validated breakouts, adaptive TP/SL with risk-reward fills."
#property description "Non-repainting: all decisions taken on closed bars."

#property indicator_chart_window
#property indicator_buffers 19
#property indicator_plots   15

//--- Plot 0 : wick-candle highlight (replaces Pine's barcolor)
#property indicator_label1  "WSB-O;WSB-H;WSB-L;WSB-C"
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  clrGreen,clrCrimson
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- Plot 1 : bullish breakout signal
#property indicator_label2  "WSB Bull"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrLime
#property indicator_width2  2
//--- Plot 2 : bearish breakout signal
#property indicator_label3  "WSB Bear"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrRed
#property indicator_width3  2
//--- Plots 3..14 = BUFFERS 7..18 : machine-readable state (iCustom / EA)
#property indicator_type4   DRAW_NONE
#property indicator_type5   DRAW_NONE
#property indicator_type6   DRAW_NONE
#property indicator_type7   DRAW_NONE
#property indicator_type8   DRAW_NONE
#property indicator_type9   DRAW_NONE
#property indicator_type10  DRAW_NONE
#property indicator_type11  DRAW_NONE
#property indicator_type12  DRAW_NONE
#property indicator_type13  DRAW_NONE
#property indicator_type14  DRAW_NONE
#property indicator_type15  DRAW_NONE

//==================================================================//
//                          ENUMERATIONS                            //
//==================================================================//
enum ENUM_WSB_VOLSRC
  {
   WSB_VOL_TICK = 0,   // Tick Volume (synthetics / crypto / FX)
   WSB_VOL_REAL = 1    // Real Volume (exchange feeds)
  };

enum ENUM_WSB_SIZE
  {
   WSB_SIZE_AUTO   = 0, // Auto (by chart timeframe)
   WSB_SIZE_TINY   = 1, // Tiny
   WSB_SIZE_SMALL  = 2, // Small
   WSB_SIZE_NORMAL = 3, // Normal
   WSB_SIZE_LARGE  = 4  // Large
  };

//==================================================================//
//                             INPUTS                               //
//==================================================================//

input group                 "=== CANDLE & SIGNAL SETTINGS ==="
input int    InpMinWickBars    = 3;      // Min. number of wick candles
input int    InpWindowSize     = 5;      // Window size (candles)
input double InpMinUpperBear   = 45.0;   // Min. upper wick share - bearish formation (%)
input double InpMaxLowerBear   = 25.0;   // Max. lower wick share - bearish formation (%)
input double InpMinLowerBull   = 45.0;   // Min. lower wick share - bullish formation (%)
input double InpMaxUpperBull   = 25.0;   // Max. upper wick share - bullish formation (%)
input int    InpMaxWaitBars    = 100;    // Breakout wait limit (bars, 0 = no limit)
input bool   InpUseCloseBO     = false;  // Breakout by close price

input group                 "=== SIGNAL FILTERS ==="
input bool   InpUseMinRange    = true;   // Filter small candles (ATR)
input double InpMinAtrMult     = 0.3;    // ATR multiplier
input int    InpAtrLen         = 14;     // ATR period
input bool   InpUseSizeFilter  = false;  // Filter by breakout candle size
input double InpSizeMult       = 1.5;    // Size multiplier
input int    InpSizeLen        = 20;     // Average candle size period
input bool   InpShowBearSig    = true;   // Show bearish signals
input bool   InpShowBullSig    = true;   // Show bullish signals
input bool   InpRemoveBadBox   = true;   // Remove box on mismatched signal

input group                 "=== COLOURS & VISUALISATION ==="
input bool   InpPaintWicks     = true;             // Highlight wick candles
input color  InpColBull        = C'6,162,47';      // Bullish colour
input color  InpColBear        = C'207,23,23';     // Bearish colour
input color  InpColNeutral     = C'120,123,134';   // Neutral colour (Pine color.gray)
input int    InpBoxFillTransp  = 85;               // Box background transparency (0-100)
input int    InpBoxBordTransp  = 60;               // Box border transparency (0-100)
input bool   InpShowVolBars    = true;             // Show volume bars
input bool   InpShowVolPct     = true;             // Show % label
input ENUM_WSB_VOLSRC InpVolSource = WSB_VOL_TICK; // Volume source

input group                 "=== TP / SL ==="
input bool   InpShowTargets    = true;   // Show TP/SL levels
input bool   InpUseAtrSL       = true;   // SL = ATR
input int    InpTpAtrPeriod    = 14;     // ATR period (TP/SL)
input double InpSlAtrMult      = 1.5;    // ATR multiplier for SL
input double InpSlPercent      = 1.0;    // SL % from Entry
input double InpRrTP1          = 1.0;    // RR for TP1
input double InpRrTP2          = 2.0;    // RR for TP2
input double InpRrTP3          = 3.0;    // RR for TP3

input group                 "=== TP / SL - DISPLAY ==="
input bool   InpShowSlLevel    = true;   // Show SL level
input bool   InpShowTp1Level   = true;   // Show TP1 level
input bool   InpShowTp2Level   = true;   // Show TP2 level
input bool   InpShowTp3Level   = true;   // Show TP3 level
input bool   InpShowRiskFill   = true;   // Shade the risk / reward zones

input group                 "=== UTT PANEL ==="
input bool   InpShowPanel      = true;         // Show status panel (top right)
input ENUM_WSB_SIZE InpPanelSize = WSB_SIZE_AUTO; // Panel text size
input string InpFontName       = "Consolas";   // Panel / label font

input group                 "=== ALERTS ==="
input bool   InpEnableAlerts   = true;         // Enable alerts (master switch)
input bool   InpAlertPopup     = true;         // Alert: terminal popup
input bool   InpAlertPush      = false;        // Alert: mobile push notification
input bool   InpAlertEmail     = false;        // Alert: email
input bool   InpAlertSound     = true;         // Alert: sound
input string InpSoundFile      = "alert.wav";  // Alert sound file

input group                 "=== PERFORMANCE ==="
input int    InpMaxBars        = 3000;   // Max bars to analyse
input int    InpMaxBoxes       = 60;     // Max historical boxes kept on chart

//==================================================================//
//                       INDICATOR BUFFERS                          //
//==================================================================//
double BufWickO[];     // 0  wick-candle open      (DRAW_COLOR_CANDLES)
double BufWickH[];     // 1  wick-candle high
double BufWickL[];     // 2  wick-candle low
double BufWickC[];     // 3  wick-candle close
double BufWickCol[];   // 4  colour index 0 = bull wick, 1 = bear wick
double BufBullArr[];   // 5  bullish signal arrow price
double BufBearArr[];   // 6  bearish signal arrow price
double BufBuy[];       // 7  bt_buy_score   1 / 0
double BufSell[];      // 8  bt_sell_score  1 / 0
double BufDir[];       // 9  signal direction +1 / -1 / 0
double BufEntry[];     // 10 entry price
double BufSL[];        // 11 stop loss
double BufTP1[];       // 12 take profit 1
double BufTP2[];       // 13 take profit 2
double BufTP3[];       // 14 take profit 3
double BufBoxTop[];    // 15 active box top
double BufBoxBot[];    // 16 active box bottom
double BufBuyPct[];    // 17 buy volume share inside the box (0..100)
double BufBoxState[];  // 18 0 idle 1 active 2 closed-bull 3 closed-bear
//                     //    4 closed-invalid 5 timed out

//==================================================================//
//                         CONSTANTS                                //
//==================================================================//
#define WSB_SHORT   "UTT-WSB"
#define WSB_PREFIX  "UWSB_"

//==================================================================//
//                        GLOBAL STATE                              //
//==================================================================//
//--- cached series, indexed with (barIndex - g_off)
double g_atrF[];
double g_atrT[];
double g_avgRng[];
double g_volD[];
char   g_isBull[];        // 1 = candle qualifies as a bull-wick candle
char   g_isBear[];
int    g_off   = 0;
int    g_count = 0;

//--- the single live formation box (mirrors Pine's `boxActive` model)
bool     g_boxActive  = false;
int      g_boxId      = 0;
int      g_boxLeft    = 0;      // bar index of the box's left edge
int      g_boxForm    = 0;      // bar index the box was created on
double   g_boxTop     = 0.0;
double   g_boxBottom  = 0.0;
double   g_boxBullVol = 0.0;
double   g_boxBearVol = 0.0;
int      g_boxSeq     = 0;      // monotonic id, used in object names

//--- rolling registry so old boxes can be pruned oldest-first
int      g_boxIds[];
int      g_boxCount = 0;

//--- TP/SL state (Pine keeps exactly one set alive)
int      g_tpDir     = 0;       // +1 long, -1 short, 0 none
int      g_tpEntryBar = 0;
double   g_tpEntry   = 0.0;
double   g_tpSL      = 0.0;
double   g_tp1       = 0.0;
double   g_tp2       = 0.0;
double   g_tp3       = 0.0;
double   g_tpExtreme = 0.0;     // furthest displayed TP, used for the hit test
bool     g_tpHasExtreme = false;
bool     g_tpClosed  = false;

//--- misc
datetime g_lastProcTime = 0;
bool     g_suppressAlerts = false;
bool     g_firstPass      = true;   // suppress only the very first attach
datetime g_liveBarTime    = 0;      // time of the bar that has just closed
datetime g_alertBar = 0;
int      g_warmup   = 120;

//--- last snapshot for the panel
int      g_pBullCount = 0;
int      g_pBearCount = 0;
double   g_pBuyPct    = 50.0;
string   g_pBoxState  = "IDLE";
int      g_pWait      = 0;

//==================================================================//
//                      SMALL UTILITIES                             //
//==================================================================//
int WSB_ClampI(const int v, const int lo, const int hi)
  {
   if(v < lo)
      return(lo);
   if(v > hi)
      return(hi);
   return(v);
  }

double WSB_At(const double &arr[], const int bar)
  {
   int k = bar - g_off;
   if(k < 0 || k >= g_count)
      return(0.0);
   return(arr[k]);
  }

bool WSB_Flag(const char &arr[], const int bar)
  {
   int k = bar - g_off;
   if(k < 0 || k >= g_count)
      return(false);
   return(arr[k] != 0);
  }

bool WSB_HasBar(const int bar)
  {
   int k = bar - g_off;
   return(k >= 0 && k < g_count);
  }

//+------------------------------------------------------------------+
//| Pine's color.new(col, transparency) has no direct MT5 equivalent |
//| - graphical objects are opaque.  We emulate it by blending the    |
//| colour towards the chart background, which is what the eye        |
//| actually sees on TradingView.                                     |
//+------------------------------------------------------------------+
color WSB_Fade(const color c, const int transpPct)
  {
   int t = WSB_ClampI(transpPct, 0, 100);
   if(t <= 0)
      return(c);

   color  bgc = (color)ChartGetInteger(0, CHART_COLOR_BACKGROUND, 0);
   uint   v   = (uint)c;
   uint   b   = (uint)bgc;

   double a = 1.0 - (double)t / 100.0;

   int r1 = (int)(v & 0xFF);
   int g1 = (int)((v >> 8) & 0xFF);
   int b1 = (int)((v >> 16) & 0xFF);
   int r2 = (int)(b & 0xFF);
   int g2 = (int)((b >> 8) & 0xFF);
   int b2 = (int)((b >> 16) & 0xFF);

   int rr = (int)MathRound(r1 * a + r2 * (1.0 - a));
   int gg = (int)MathRound(g1 * a + g2 * (1.0 - a));
   int bb = (int)MathRound(b1 * a + b2 * (1.0 - a));

   rr = WSB_ClampI(rr, 0, 255);
   gg = WSB_ClampI(gg, 0, 255);
   bb = WSB_ClampI(bb, 0, 255);

   return((color)((uint)rr | ((uint)gg << 8) | ((uint)bb << 16)));
  }

//--- time of a bar index, extrapolated forward past the last bar ---
datetime WSB_BarTime(const int idx, const int rates_total, const datetime &time[])
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
void WSB_DeletePrefix(const string pfx)
  {
   int total = ObjectsTotal(0, -1, -1);
   for(int k = total - 1; k >= 0; k--)
     {
      string nm = ObjectName(0, k, -1, -1);
      if(StringFind(nm, pfx, 0) == 0)
         ObjectDelete(0, nm);
     }
  }

void WSB_DeleteAll()
  {
   WSB_DeletePrefix(WSB_PREFIX);
  }

//+------------------------------------------------------------------+
//| A filled OBJ_RECTANGLE in MT5 paints with OBJPROP_COLOR -         |
//| OBJPROP_BGCOLOR is only honoured by OBJ_EDIT / OBJ_BUTTON /       |
//| OBJ_RECTANGLE_LABEL.  So a single rectangle cannot carry an       |
//| independent fill and border colour the way a Pine box does.       |
//| When both are wanted we lay an unfilled outline rectangle over    |
//| the filled one, sharing the same two anchors.                     |
//+------------------------------------------------------------------+
void WSB_Box(const string name, const datetime t1, const double p1,
             const datetime t2, const double p2,
             const color fill, const color border, const bool back,
             const bool drawBorder)
  {
   if(ObjectFind(0, name) < 0)
      if(!ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, p1, t2, p2))
         return;

   ObjectSetInteger(0, name, OBJPROP_TIME,  0, t1);
   ObjectSetDouble(0,  name, OBJPROP_PRICE, 0, p1);
   ObjectSetInteger(0, name, OBJPROP_TIME,  1, t2);
   ObjectSetDouble(0,  name, OBJPROP_PRICE, 1, p2);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      fill);   // fill == COLOR when FILL is on
   ObjectSetInteger(0, name, OBJPROP_FILL,       true);
   ObjectSetInteger(0, name, OBJPROP_BACK,       back);
   ObjectSetInteger(0, name, OBJPROP_STYLE,      STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      1);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED,   false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,     true);

   if(!drawBorder)
      return;

   string bn = name + "BRD";
   if(ObjectFind(0, bn) < 0)
      if(!ObjectCreate(0, bn, OBJ_RECTANGLE, 0, t1, p1, t2, p2))
         return;

   ObjectSetInteger(0, bn, OBJPROP_TIME,  0, t1);
   ObjectSetDouble(0,  bn, OBJPROP_PRICE, 0, p1);
   ObjectSetInteger(0, bn, OBJPROP_TIME,  1, t2);
   ObjectSetDouble(0,  bn, OBJPROP_PRICE, 1, p2);
   ObjectSetInteger(0, bn, OBJPROP_COLOR,      border);
   ObjectSetInteger(0, bn, OBJPROP_FILL,       false);
   ObjectSetInteger(0, bn, OBJPROP_BACK,       back);
   ObjectSetInteger(0, bn, OBJPROP_STYLE,      STYLE_SOLID);
   ObjectSetInteger(0, bn, OBJPROP_WIDTH,      1);
   ObjectSetInteger(0, bn, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, bn, OBJPROP_SELECTED,   false);
   ObjectSetInteger(0, bn, OBJPROP_HIDDEN,     true);
  }

void WSB_Seg(const string name, const datetime t1, const datetime t2, const double p,
             const color clr, const ENUM_LINE_STYLE style, const int width)
  {
   if(ObjectFind(0, name) < 0)
      if(!ObjectCreate(0, name, OBJ_TREND, 0, t1, p, t2, p))
         return;

   ObjectSetInteger(0, name, OBJPROP_TIME,  0, t1);
   ObjectSetDouble(0,  name, OBJPROP_PRICE, 0, p);
   ObjectSetInteger(0, name, OBJPROP_TIME,  1, t2);
   ObjectSetDouble(0,  name, OBJPROP_PRICE, 1, p);
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

void WSB_Text(const string name, const datetime t, const double p, const string txt,
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
//                        SIZE / PANEL                              //
//==================================================================//
int WSB_FontSize()
  {
   ENUM_WSB_SIZE s = InpPanelSize;
   if(s == WSB_SIZE_AUTO)
     {
      int secs = PeriodSeconds((ENUM_TIMEFRAMES)_Period);
      if(secs <= 300)
         s = WSB_SIZE_TINY;
      else
         if(secs <= 1800)
            s = WSB_SIZE_SMALL;
         else
            if(secs <= 86400)
               s = WSB_SIZE_NORMAL;
            else
               s = WSB_SIZE_LARGE;
     }
   switch(s)
     {
      case WSB_SIZE_TINY:
         return(6);
      case WSB_SIZE_SMALL:
         return(7);
      case WSB_SIZE_LARGE:
         return(10);
      default:
         return(8);
     }
  }

void WSB_PanelBg(const string name, const int x, const int y, const int w, const int h)
  {
   if(ObjectFind(0, name) < 0)
      if(!ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
         return;

   ObjectSetInteger(0, name, OBJPROP_CORNER,      CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,   x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,   y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE,       w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,       h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,     WSB_Fade(InpColNeutral, 88));
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_COLOR,       WSB_Fade(InpColNeutral, 45));
   ObjectSetInteger(0, name, OBJPROP_BACK,        false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,  false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED,    false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,      true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER,      0);
  }

void WSB_Cell(const string name, const int x, const int y, const string txt,
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

void WSB_DrawPanel()
  {
   static bool s_cleared = false;
   if(!InpShowPanel)
     {
      if(!s_cleared)
        {
         WSB_DeletePrefix(WSB_PREFIX + "P");
         s_cleared = true;
        }
      return;
     }
   s_cleared = false;

   int fs   = WSB_FontSize();
   int cw   = (int)MathMax(4.0, MathRound(fs * 0.62));
   int rowH = fs + 7;
   int pad  = 7;
   int W    = cw * 30 + pad * 2;
   int H    = rowH * 7 + pad * 2 + 4;
   int mX   = 8;
   int mY   = 18;

   string P = WSB_PREFIX + "P";
   WSB_PanelBg(P + "BG", mX, mY, W, H);

   int xL = mX + W - pad;          // left aligned column
   int xR = mX + pad;              // right aligned column
   int y  = mY + pad;

   color dim  = WSB_Fade(InpColNeutral, 25);
   color head = WSB_Fade(InpColNeutral, 0);

   WSB_Cell(P + "H", xL, y, "UTT  WICK SEQUENCE BREAKOUT", head, fs, ANCHOR_LEFT_UPPER);
   y += rowH + 4;

   WSB_Cell(P + "R0a", xL, y, "Wick candles", dim, fs, ANCHOR_LEFT_UPPER);
   WSB_Cell(P + "R0b", xR, y,
            StringFormat("%d bull / %d bear", g_pBullCount, g_pBearCount),
            head, fs, ANCHOR_RIGHT_UPPER);
   y += rowH;

   WSB_Cell(P + "R1a", xL, y, "Need", dim, fs, ANCHOR_LEFT_UPPER);
   WSB_Cell(P + "R1b", xR, y,
            StringFormat("%d of %d", InpMinWickBars, InpWindowSize),
            head, fs, ANCHOR_RIGHT_UPPER);
   y += rowH;

   color stClr = dim;
   if(g_pBoxState == "ACTIVE")
      stClr = WSB_Fade(InpColNeutral, 0);
   else
      if(g_pBoxState == "BULL BO")
         stClr = InpColBull;
      else
         if(g_pBoxState == "BEAR BO")
            stClr = InpColBear;

   WSB_Cell(P + "R2a", xL, y, "Box", dim, fs, ANCHOR_LEFT_UPPER);
   WSB_Cell(P + "R2b", xR, y, g_pBoxState, stClr, fs, ANCHOR_RIGHT_UPPER);
   y += rowH;

   WSB_Cell(P + "R3a", xL, y, "Volume split", dim, fs, ANCHOR_LEFT_UPPER);
   WSB_Cell(P + "R3b", xR, y,
            StringFormat("B %.0f%% / S %.0f%%", g_pBuyPct, 100.0 - g_pBuyPct),
            (g_pBuyPct >= 50.0 ? InpColBull : InpColBear), fs, ANCHOR_RIGHT_UPPER);
   y += rowH;

   WSB_Cell(P + "R4a", xL, y, "Bars waiting", dim, fs, ANCHOR_LEFT_UPPER);
   WSB_Cell(P + "R4b", xR, y,
            (!g_boxActive ? "-"
             : (InpMaxWaitBars > 0 ? StringFormat("%d / %d", g_pWait, InpMaxWaitBars)
                : StringFormat("%d / no limit", g_pWait))),
            head, fs, ANCHOR_RIGHT_UPPER);
   y += rowH;

   string trTxt = "NONE";
   color  trClr = dim;
   if(g_tpDir != 0)
     {
      trTxt = (g_tpDir > 0 ? "LONG" : "SHORT");
      trClr = (g_tpDir > 0 ? InpColBull : InpColBear);
     }
   WSB_Cell(P + "R5a", xL, y, "Active setup", dim, fs, ANCHOR_LEFT_UPPER);
   WSB_Cell(P + "R5b", xR, y, trTxt, trClr, fs, ANCHOR_RIGHT_UPPER);
  }

//==================================================================//
//                           ALERTS                                 //
//==================================================================//
bool WSB_IsLiveBar(const datetime bt)
  {
   //--- Only the bar that has just closed in real time may alert.
   //--- Matching bar times (rather than a wall-clock age window)
   //--- stays correct across weekend gaps, session breaks and thin
   //--- symbols where the next bar can be hours away - and it does
   //--- not swallow a genuine signal when MT5 forces a history
   //--- resync on the very bar that produced it.
   if(g_suppressAlerts || g_liveBarTime == 0)
      return(false);
   return(bt == g_liveBarTime);
  }

void WSB_Alert(const bool bullish, const datetime bt,
               const double entry, const double sl, const double tp1)
  {
   if(!InpEnableAlerts || !WSB_IsLiveBar(bt))
      return;
   if(g_alertBar == bt)
      return;
   g_alertBar = bt;

   string dirTxt = (bullish
                    ? "UPWARD breakout, aligned with dominant buy volume - bullish signal"
                    : "DOWNWARD breakout, aligned with dominant sell volume - bearish signal");

   string full = StringFormat("%s %s %s | Formation: %s | Entry %s  SL %s  TP1 %s",
                              WSB_SHORT, _Symbol,
                              EnumToString((ENUM_TIMEFRAMES)_Period),
                              dirTxt,
                              DoubleToString(entry, _Digits),
                              DoubleToString(sl,    _Digits),
                              DoubleToString(tp1,   _Digits));

   if(InpAlertPopup)
      Alert(full);
   if(InpAlertPush)
      SendNotification(full);
   if(InpAlertEmail)
      SendMail(WSB_SHORT + " signal", full);
   if(InpAlertSound && StringLen(InpSoundFile) > 0)
      PlaySound(InpSoundFile);

   Print(full);
  }

//==================================================================//
//                     BOX OBJECT MANAGEMENT                        //
//==================================================================//
string WSB_BoxTag(const int id)
  {
   return(WSB_PREFIX + "B" + IntegerToString(id) + "_");
  }

void WSB_RegisterBox(const int id)
  {
   int n = ArraySize(g_boxIds);
   if(ArrayResize(g_boxIds, n + 1) != n + 1)
      return;
   g_boxIds[n] = id;
   g_boxCount  = n + 1;

   int cap = MathMax(5, InpMaxBoxes);
   while(g_boxCount > cap)
     {
      WSB_DeletePrefix(WSB_BoxTag(g_boxIds[0]));
      for(int k = 1; k < g_boxCount; k++)
         g_boxIds[k - 1] = g_boxIds[k];
      g_boxCount--;
      ArrayResize(g_boxIds, g_boxCount);
     }
  }

void WSB_DeleteBoxObjects(const int id)
  {
   WSB_DeletePrefix(WSB_BoxTag(id));
  }

//+------------------------------------------------------------------+
//| Draw / refresh the active formation box, its volume bars and the |
//| percentage label.  Mirrors the Pine block that runs while the    |
//| box is waiting for a breakout.                                   |
//+------------------------------------------------------------------+
void WSB_RenderBox(const int rightBar, const int rates_total, const datetime &time[],
                   const double atrNow, const color fill, const color border,
                   const int volRightBar)
  {
   string tag = WSB_BoxTag(g_boxId);

   datetime tL = WSB_BarTime(g_boxLeft, rates_total, time);
   datetime tR = WSB_BarTime(rightBar,  rates_total, time);

   WSB_Box(tag + "MAIN", tL, g_boxTop, tR, g_boxBottom, fill, border, true, true);

   if(!InpShowVolBars && !InpShowVolPct)
      return;

   double atr = MathMax(atrNow, _Point * 10.0);
   double barH   = atr * 0.18;
   double gapH   = atr * 0.08;
   double bullTop = g_boxBottom - gapH;
   double bullBot = bullTop - barH;
   double bearTop = bullBot - gapH;
   double bearBot = bearTop - barH;

   if(InpShowVolBars)
     {
      double total = g_boxBullVol + g_boxBearVol;
      int fullWidth = MathMax(volRightBar - g_boxLeft, 1);
      double bullShare = (total > 0.0 ? g_boxBullVol / total : 0.5);
      double bearShare = (total > 0.0 ? g_boxBearVol / total : 0.5);

      //--- a minority share can round to zero bars; keep it visible
      int bullRight = g_boxLeft + MathMax(1, (int)MathRound(fullWidth * bullShare));
      int bearRight = g_boxLeft + MathMax(1, (int)MathRound(fullWidth * bearShare));

      WSB_Box(tag + "VB", tL, bullTop,
              WSB_BarTime(bullRight, rates_total, time), bullBot,
              WSB_Fade(InpColBull, 15), WSB_Fade(InpColBull, 15), false, false);
      WSB_Box(tag + "VS", tL, bearTop,
              WSB_BarTime(bearRight, rates_total, time), bearBot,
              WSB_Fade(InpColBear, 15), WSB_Fade(InpColBear, 15), false, false);
     }

   if(InpShowVolPct)
     {
      double total   = g_boxBullVol + g_boxBearVol;
      double bullPct = (total > 0.0 ? g_boxBullVol / total * 100.0 : 50.0);
      double sellPct = 100.0 - bullPct;
      color  txtCol  = (bullPct >= 50.0 ? InpColBull : InpColBear);
      int    fs      = WSB_FontSize();

      //--- MT5 text objects are single line, so the Pine two-line
      //--- label becomes two stacked objects.
      WSB_Text(tag + "PCT1", tL, bearBot - gapH * 0.5,
               StringFormat("Buy %.1f%%", bullPct), txtCol, fs, ANCHOR_LEFT_UPPER);
      WSB_Text(tag + "PCT2", tL, bearBot - gapH * 0.5 - barH * 0.85,
               StringFormat("Sell %.1f%%", sellPct), txtCol, fs, ANCHOR_LEFT_UPPER);
     }
  }

//==================================================================//
//                      TP / SL MANAGEMENT                          //
//==================================================================//
void WSB_ClearTpsl()
  {
   WSB_DeletePrefix(WSB_PREFIX + "TP");
  }

void WSB_RenderTpsl(const int rightBar, const int rates_total, const datetime &time[])
  {
   if(g_tpDir == 0 || !InpShowTargets)
      return;

   string   tag = WSB_PREFIX + "TP";
   datetime t1  = WSB_BarTime(g_tpEntryBar, rates_total, time);
   datetime t2  = WSB_BarTime(rightBar,     rates_total, time);

   bool  isBuy   = (g_tpDir > 0);
   color entryC  = WSB_Fade(isBuy ? InpColBull : InpColBear, 40);
   color slC     = WSB_Fade(isBuy ? InpColBear : InpColBull, 40);
   color tpC     = WSB_Fade(isBuy ? InpColBull : InpColBear, 40);
   color riskC   = WSB_Fade(isBuy ? InpColBear : InpColBull, 80);
   color rewardC = WSB_Fade(isBuy ? InpColBull : InpColBear, 80);
   int   fs      = WSB_FontSize();

   //--- Pine's linefill becomes a filled rectangle between the two
   //--- price levels over the same x-range.
   if(InpShowRiskFill)
     {
      if(InpShowSlLevel)
         WSB_Box(tag + "FRISK", t1, g_tpEntry, t2, g_tpSL, riskC, riskC, true, false);

      double ext = g_tpEntry;
      if(InpShowTp1Level)
         ext = (isBuy ? MathMax(ext, g_tp1) : MathMin(ext, g_tp1));
      if(InpShowTp2Level)
         ext = (isBuy ? MathMax(ext, g_tp2) : MathMin(ext, g_tp2));
      if(InpShowTp3Level)
         ext = (isBuy ? MathMax(ext, g_tp3) : MathMin(ext, g_tp3));

      if((isBuy && ext > g_tpEntry) || (!isBuy && ext < g_tpEntry))
         WSB_Box(tag + "FREW", t1, g_tpEntry, t2, ext, rewardC, rewardC, true, false);
     }

   WSB_Seg(tag + "LNE", t1, t2, g_tpEntry, entryC, STYLE_SOLID, 2);
   WSB_Text(tag + "LBE", t2, g_tpEntry,
            StringFormat("%s %s", (isBuy ? "BUY" : "SELL"),
                         DoubleToString(g_tpEntry, _Digits)),
            entryC, fs, ANCHOR_LEFT_LOWER);

   if(InpShowSlLevel)
     {
      WSB_Seg(tag + "LNS", t1, t2, g_tpSL, slC, STYLE_DASH, 1);
      WSB_Text(tag + "LBS", t2, g_tpSL, "SL " + DoubleToString(g_tpSL, _Digits),
               slC, fs, ANCHOR_LEFT_UPPER);
     }
   if(InpShowTp1Level)
     {
      WSB_Seg(tag + "LN1", t1, t2, g_tp1, tpC, STYLE_SOLID, 1);
      WSB_Text(tag + "LB1", t2, g_tp1, "TP1 " + DoubleToString(g_tp1, _Digits),
               tpC, fs, ANCHOR_LEFT_LOWER);
     }
   if(InpShowTp2Level)
     {
      WSB_Seg(tag + "LN2", t1, t2, g_tp2, tpC, STYLE_SOLID, 1);
      WSB_Text(tag + "LB2", t2, g_tp2, "TP2 " + DoubleToString(g_tp2, _Digits),
               tpC, fs, ANCHOR_LEFT_LOWER);
     }
   if(InpShowTp3Level)
     {
      WSB_Seg(tag + "LN3", t1, t2, g_tp3, tpC, STYLE_DOT, 1);
      WSB_Text(tag + "LB3", t2, g_tp3, "TP3 " + DoubleToString(g_tp3, _Digits),
               tpC, fs, ANCHOR_LEFT_LOWER);
     }
  }

//==================================================================//
//                        DATA REFRESH                              //
//==================================================================//
bool WSB_UpdateData(const int rates_total, const datetime lastBarTime, const bool force,
                    const double &open[], const double &high[], const double &low[],
                    const double &close[], const long &tick_volume[], const long &real_volume[])
  {
   static datetime s_last = 0;
   if(!force && lastBarTime == s_last && g_count > 0)
      return(true);

   int need = MathMin(rates_total, MathMax(400, InpMaxBars) + g_warmup + 50);
   if(need < g_warmup + 10)
     {
      g_count = 0;
      return(false);
     }

   //--- publish the window only once every array behind it is filled
   g_count = 0;
   int off = rates_total - need;

   if(ArrayResize(g_atrF,   need) != need ||
      ArrayResize(g_atrT,   need) != need ||
      ArrayResize(g_avgRng, need) != need ||
      ArrayResize(g_volD,   need) != need ||
      ArrayResize(g_isBull, need) != need ||
      ArrayResize(g_isBear, need) != need)
      return(false);

   int    sizeLen = MathMax(1, InpSizeLen);
   int    lenF    = MathMax(1, InpAtrLen);
   int    lenT    = MathMax(1, InpTpAtrPeriod);
   double run     = 0.0;
   double sumF    = 0.0;
   double sumT    = 0.0;

   for(int k = 0; k < need; k++)
     {
      int i = off + k;

      double rng = high[i] - low[i];

      //--- ATR: Pine's ta.atr() is Wilder's RMA of the true range.
      //--- MT5's built-in iATR() is a SIMPLE moving average of TR, a
      //--- materially different series (roughly 2x the effective
      //--- memory difference at length 14).  Since this ATR gates
      //--- rangeOk - and therefore every wick classification, every
      //--- formation and every signal - it is computed here instead
      //--- of leaning on iATR, so the port tracks the original.
      double tr = (i > 0
                   ? MathMax(high[i], close[i - 1]) - MathMin(low[i], close[i - 1])
                   : rng);

      if(k < lenF)
        {
         sumF += tr;
         g_atrF[k] = sumF / (double)(k + 1);
        }
      else
         g_atrF[k] = (g_atrF[k - 1] * (double)(lenF - 1) + tr) / (double)lenF;

      if(k < lenT)
        {
         sumT += tr;
         g_atrT[k] = sumT / (double)(k + 1);
        }
      else
         g_atrT[k] = (g_atrT[k - 1] * (double)(lenT - 1) + tr) / (double)lenT;

      run += rng;
      if(k >= sizeLen)
         run -= (high[off + k - sizeLen] - low[off + k - sizeLen]);
      g_avgRng[k] = run / (double)MathMin(k + 1, sizeLen);

      g_volD[k] = (InpVolSource == WSB_VOL_REAL ? (double)real_volume[i] : (double)tick_volume[i]);
      if(g_volD[k] <= 0.0)
         g_volD[k] = (double)tick_volume[i];

      //--- candle geometry -> wick classification (Pine: isBearWick / isBullWick)
      double upPct = (rng > 0.0 ? (high[i] - MathMax(open[i], close[i])) / rng * 100.0 : 0.0);
      double loPct = (rng > 0.0 ? (MathMin(open[i], close[i]) - low[i]) / rng * 100.0 : 0.0);

      bool rangeOk = (!InpUseMinRange || rng >= g_atrF[k] * InpMinAtrMult);

      g_isBear[k] = (char)((rangeOk && upPct >= InpMinUpperBear && loPct <= InpMaxLowerBear) ? 1 : 0);
      g_isBull[k] = (char)((rangeOk && loPct >= InpMinLowerBull && upPct <= InpMaxUpperBull) ? 1 : 0);
     }

   g_off   = off;
   g_count = need;
   s_last  = lastBarTime;
   return(true);
  }

//==================================================================//
//                     PATTERN EVALUATION                           //
//==================================================================//
int WSB_CountWindow(const int bar, const bool bullSide)
  {
   int len = MathMax(1, InpWindowSize);
   int c   = 0;
   for(int k = 0; k < len; k++)
     {
      int b = bar - k;
      if(!WSB_HasBar(b))
         break;
      if(bullSide)
        {
         if(WSB_Flag(g_isBull, b))
            c++;
        }
      else
         if(WSB_Flag(g_isBear, b))
            c++;
     }
   return(c);
  }

//--- exclusive one-sided formation, exactly as Pine resolves it ----
void WSB_Pattern(const int bar, bool &bullPat, bool &bearPat)
  {
   int need = MathMax(1, InpMinWickBars);
   bool bullRaw = (WSB_CountWindow(bar, true)  >= need);
   bool bearRaw = (WSB_CountWindow(bar, false) >= need);
   bullPat = (bullRaw && !bearRaw);
   bearPat = (bearRaw && !bullRaw);
  }

//==================================================================//
//                      BUFFER MAINTENANCE                          //
//==================================================================//
void WSB_ClearBar(const int i)
  {
   if(i < 0 || i >= ArraySize(BufWickO))
      return;
   BufWickO[i]   = EMPTY_VALUE;
   BufWickH[i]   = EMPTY_VALUE;
   BufWickL[i]   = EMPTY_VALUE;
   BufWickC[i]   = EMPTY_VALUE;
   BufWickCol[i] = 0.0;
   BufBullArr[i] = EMPTY_VALUE;
   BufBearArr[i] = EMPTY_VALUE;
   BufBuy[i]     = 0.0;
   BufSell[i]    = 0.0;
   BufDir[i]     = 0.0;
   BufEntry[i]   = 0.0;
   BufSL[i]      = 0.0;
   BufTP1[i]     = 0.0;
   BufTP2[i]     = 0.0;
   BufTP3[i]     = 0.0;
   BufBoxTop[i]  = 0.0;
   BufBoxBot[i]  = 0.0;
   BufBuyPct[i]  = 0.0;
   BufBoxState[i]= 0.0;
  }

void WSB_ClearBuffers()
  {
   ArrayInitialize(BufWickO,    EMPTY_VALUE);
   ArrayInitialize(BufWickH,    EMPTY_VALUE);
   ArrayInitialize(BufWickL,    EMPTY_VALUE);
   ArrayInitialize(BufWickC,    EMPTY_VALUE);
   ArrayInitialize(BufWickCol,  0.0);
   ArrayInitialize(BufBullArr,  EMPTY_VALUE);
   ArrayInitialize(BufBearArr,  EMPTY_VALUE);
   ArrayInitialize(BufBuy,      0.0);
   ArrayInitialize(BufSell,     0.0);
   ArrayInitialize(BufDir,      0.0);
   ArrayInitialize(BufEntry,    0.0);
   ArrayInitialize(BufSL,       0.0);
   ArrayInitialize(BufTP1,      0.0);
   ArrayInitialize(BufTP2,      0.0);
   ArrayInitialize(BufTP3,      0.0);
   ArrayInitialize(BufBoxTop,   0.0);
   ArrayInitialize(BufBoxBot,   0.0);
   ArrayInitialize(BufBuyPct,   0.0);
   ArrayInitialize(BufBoxState, 0.0);
  }

void WSB_ResetState()
  {
   g_lastProcTime = 0;
   g_boxActive    = false;
   g_boxId        = 0;
   g_boxLeft      = 0;
   g_boxForm      = 0;
   g_boxTop       = 0.0;
   g_boxBottom    = 0.0;
   g_boxBullVol   = 0.0;
   g_boxBearVol   = 0.0;
   g_boxSeq       = 0;
   g_boxCount     = 0;
   ArrayResize(g_boxIds, 0);

   g_tpDir        = 0;
   g_tpEntryBar   = 0;
   g_tpEntry      = 0.0;
   g_tpSL         = 0.0;
   g_tp1          = 0.0;
   g_tp2          = 0.0;
   g_tp3          = 0.0;
   g_tpExtreme    = 0.0;
   g_tpHasExtreme = false;
   g_tpClosed     = false;

   g_pBullCount   = 0;
   g_pBearCount   = 0;
   g_pBuyPct      = 50.0;
   g_pBoxState    = "IDLE";
   g_pWait        = 0;
  }

//==================================================================//
//                   PER-BAR STATE MACHINE                          //
//==================================================================//
bool WSB_ProcessBar(const int i, const int rates_total,
                    const datetime &time[], const double &open[], const double &high[],
                    const double &low[], const double &close[])
  {
   if(!WSB_HasBar(i) || !WSB_HasBar(i - 1))
      return(false);

   WSB_ClearBar(i);

   double rng   = high[i] - low[i];
   double atrF  = WSB_At(g_atrF, i);
   double atrT  = WSB_At(g_atrT, i);
   double tick  = MathMax(_Point, 1e-10);

   bool bullWick = WSB_Flag(g_isBull, i);
   bool bearWick = WSB_Flag(g_isBear, i);

//--- wick-candle highlight (Pine: barcolor) -------------------------
   if(InpPaintWicks && (bullWick || bearWick))
     {
      BufWickO[i]   = open[i];
      BufWickH[i]   = high[i];
      BufWickL[i]   = low[i];
      BufWickC[i]   = close[i];
      BufWickCol[i] = (bearWick ? 1.0 : 0.0);   // Pine resolves bear first
     }

//--- one-sided formation, and its rising edge ----------------------
   bool bullPat, bearPat, bullPrev, bearPrev;
   WSB_Pattern(i,     bullPat,  bearPat);
   WSB_Pattern(i - 1, bullPrev, bearPrev);

   bool bullFormed = (bullPat && !bullPrev);
   bool bearFormed = (bearPat && !bearPrev);

   g_pBullCount = WSB_CountWindow(i, true);
   g_pBearCount = WSB_CountWindow(i, false);

//================= 1. open a new formation box =====================
   if((bullFormed || bearFormed) && !g_boxActive)
     {
      int len = MathMax(1, InpWindowSize);

      double hh = high[i];
      double ll = low[i];
      for(int k = 1; k < len; k++)
        {
         int b = i - k;
         if(b < 0)
            break;
         if(high[b] > hh)
            hh = high[b];
         if(low[b] < ll)
            ll = low[b];
        }

      g_boxSeq++;
      g_boxId     = g_boxSeq;
      g_boxTop    = hh;
      g_boxBottom = ll;
      g_boxLeft   = MathMax(0, i - len + 1);
      g_boxForm   = i;
      g_boxActive = true;

      //--- backfill the buy/sell volume already inside the box ------
      g_boxBullVol = 0.0;
      g_boxBearVol = 0.0;
      for(int k = 0; k < len; k++)
        {
         int b = i - k;
         if(b < 0 || !WSB_HasBar(b))
            break;
         double h = high[b];
         double l = low[b];
         double c = close[b];
         double v = WSB_At(g_volD, b);
         double r = MathMax(h - l, tick);
         if(h > g_boxBottom && l < g_boxTop)
           {
            g_boxBullVol += v * (c - l) / r;
            g_boxBearVol += v * (h - c) / r;
           }
        }

      WSB_RegisterBox(g_boxId);
     }

//================= 2. breakout / timeout tests =====================
   bool breakoutUp   = false;
   bool breakoutDown = false;

   if(g_boxActive)
     {
      double boHigh = (InpUseCloseBO ? close[i] : high[i]);
      double boLow  = (InpUseCloseBO ? close[i] : low[i]);
      breakoutUp   = (boHigh > g_boxTop);
      breakoutDown = (boLow  < g_boxBottom);

      //--- accumulate volume while the box waits -------------------
      if(i > g_boxForm && !breakoutUp && !breakoutDown)
        {
         double rNow = MathMax(high[i] - low[i], tick);
         if(high[i] > g_boxBottom && low[i] < g_boxTop)
           {
            g_boxBullVol += WSB_At(g_volD, i) * (close[i] - low[i])  / rNow;
            g_boxBearVol += WSB_At(g_volD, i) * (high[i]  - close[i]) / rNow;
           }
        }
     }

   int  barsWaiting = (g_boxActive ? i - g_boxForm : 0);
   bool timeoutHit  = (g_boxActive && InpMaxWaitBars > 0 &&
                       barsWaiting > InpMaxWaitBars && !breakoutUp && !breakoutDown);

//================= 3. resolve the breakout =========================
   bool bullSignal = false;
   bool bearSignal = false;

   if(g_boxActive && (breakoutUp || breakoutDown))
     {
      bool bullDominant = (g_boxBullVol >= g_boxBearVol);
      bool bearDominant = (g_boxBearVol >  g_boxBullVol);

      bool validUp   = (breakoutUp   && bullDominant);
      bool validDown = (breakoutDown && bearDominant);
      bool validDir  = (validUp || validDown);

      //--- Pine compares against avgCandleRange[1]; if that value is
      //--- not in the cache the filter must FAIL (Pine's na >= test),
      //--- never silently pass.
      bool sizeOk = (!InpUseSizeFilter ||
                     (WSB_HasBar(i - 1) && rng >= WSB_At(g_avgRng, i - 1) * InpSizeMult));

      bullSignal = (InpShowBullSig && validUp   && sizeOk);
      bearSignal = (InpShowBearSig && validDown && sizeOk);

      double totalVol = g_boxBullVol + g_boxBearVol;
      double buyPct   = (totalVol > 0.0 ? g_boxBullVol / totalVol * 100.0 : 50.0);

      if(!validDir && InpRemoveBadBox)
        {
         WSB_DeleteBoxObjects(g_boxId);
         BufBoxState[i] = 4.0;
        }
      else
        {
         color fill   = WSB_Fade(validUp ? InpColBull : (validDown ? InpColBear : InpColNeutral),
                                 InpBoxFillTransp);
         color border = WSB_Fade(validUp ? InpColBull : (validDown ? InpColBear : InpColNeutral),
                                 InpBoxBordTransp);
         WSB_RenderBox(i, rates_total, time, atrF, fill, border, i + 1);
         BufBoxState[i] = (validUp ? 2.0 : (validDown ? 3.0 : 4.0));
        }

      BufBoxTop[i] = g_boxTop;
      BufBoxBot[i] = g_boxBottom;
      BufBuyPct[i] = buyPct;
      g_pBuyPct    = buyPct;
      g_pBoxState  = (validUp ? "BULL BO" : (validDown ? "BEAR BO" : "INVALID"));

      g_boxActive = false;
     }
   else
      if(timeoutHit)
        {
         WSB_DeleteBoxObjects(g_boxId);
         g_boxActive    = false;
         BufBoxState[i] = 5.0;
         g_pBoxState    = "TIMEOUT";
        }
      else
         if(g_boxActive)
           {
            color fill   = WSB_Fade(InpColNeutral, InpBoxFillTransp);
            color border = WSB_Fade(InpColNeutral, InpBoxBordTransp);
            WSB_RenderBox(i + 1, rates_total, time, atrF, fill, border, i + 1);

            double totalVol = g_boxBullVol + g_boxBearVol;
            g_pBuyPct = (totalVol > 0.0 ? g_boxBullVol / totalVol * 100.0 : 50.0);

            BufBoxTop[i]   = g_boxTop;
            BufBoxBot[i]   = g_boxBottom;
            BufBuyPct[i]   = g_pBuyPct;
            BufBoxState[i] = 1.0;
            g_pBoxState    = "ACTIVE";
            g_pWait        = barsWaiting;
           }
         else
           {
            g_pBoxState = "IDLE";
            g_pWait     = 0;
           }

//================= 4. signals and TP/SL ============================
   if(bullSignal || bearSignal)
     {
      bool isBuy = bullSignal;

      if(isBuy)
         BufBullArr[i] = low[i] - MathMax(atrF, _Point * 10.0) * 0.35;
      else
         BufBearArr[i] = high[i] + MathMax(atrF, _Point * 10.0) * 0.35;

      BufBuy[i]  = (isBuy ? 1.0 : 0.0);
      BufSell[i] = (isBuy ? 0.0 : 1.0);
      BufDir[i]  = (isBuy ? 1.0 : -1.0);

      //--- risk distance is computed once so that the alert always
      //--- quotes exactly the levels that are drawn on the chart
      double entryP   = close[i];
      double riskDist = (InpUseAtrSL ? atrT * InpSlAtrMult
                         : entryP * (InpSlPercent / 100.0));
      riskDist = MathMax(riskDist, _Point);

      double alertSL  = (isBuy ? entryP - riskDist : entryP + riskDist);
      double alertTP1 = (isBuy ? entryP + riskDist * InpRrTP1
                         : entryP - riskDist * InpRrTP1);

      //--- Level state and the EA-facing buffers are NOT gated by
      //--- "Show TP/SL levels" - that switch is cosmetic.  Only the
      //--- drawing is optional, so an EA reading buffers 10..14 keeps
      //--- working with the visuals turned off.
      if(InpShowTargets)
         WSB_ClearTpsl();

      g_tpDir      = (isBuy ? 1 : -1);
      g_tpEntryBar = i;
      g_tpEntry    = NormalizeDouble(entryP, _Digits);
      g_tpSL       = NormalizeDouble(isBuy ? entryP - riskDist : entryP + riskDist, _Digits);
      g_tp1        = NormalizeDouble(isBuy ? entryP + riskDist * InpRrTP1
                                     : entryP - riskDist * InpRrTP1, _Digits);
      g_tp2        = NormalizeDouble(isBuy ? entryP + riskDist * InpRrTP2
                                     : entryP - riskDist * InpRrTP2, _Digits);
      g_tp3        = NormalizeDouble(isBuy ? entryP + riskDist * InpRrTP3
                                     : entryP - riskDist * InpRrTP3, _Digits);
      g_tpClosed   = false;

      //--- the hit test tracks the furthest level the user can SEE,
      //--- exactly as the original does
      g_tpHasExtreme = true;
      if(InpShowTp3Level)
         g_tpExtreme = g_tp3;
      else
         if(InpShowTp2Level)
            g_tpExtreme = g_tp2;
         else
            if(InpShowTp1Level)
               g_tpExtreme = g_tp1;
            else
               g_tpHasExtreme = false;

      BufEntry[i] = g_tpEntry;
      BufSL[i]    = g_tpSL;
      BufTP1[i]   = g_tp1;
      BufTP2[i]   = g_tp2;
      BufTP3[i]   = g_tp3;

      WSB_Alert(isBuy, time[i], entryP, alertSL, alertTP1);
     }

//================= 5. TP/SL hit detection ==========================
   if(g_tpDir != 0 && !g_tpClosed && i > g_tpEntryBar)
     {
      bool slHit = (g_tpDir > 0 ? low[i] <= g_tpSL : high[i] >= g_tpSL);
      bool tpHit = (g_tpHasExtreme &&
                    (g_tpDir > 0 ? high[i] >= g_tpExtreme : low[i] <= g_tpExtreme));

      if(slHit || tpHit)
        {
         g_tpClosed = true;
         WSB_RenderTpsl(i, rates_total, time);
         g_tpDir = 0;
        }
     }

   return(true);
  }

//+------------------------------------------------------------------+
//| Custom indicator initialisation function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,  BufWickO,    INDICATOR_DATA);
   SetIndexBuffer(1,  BufWickH,    INDICATOR_DATA);
   SetIndexBuffer(2,  BufWickL,    INDICATOR_DATA);
   SetIndexBuffer(3,  BufWickC,    INDICATOR_DATA);
   SetIndexBuffer(4,  BufWickCol,  INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5,  BufBullArr,  INDICATOR_DATA);
   SetIndexBuffer(6,  BufBearArr,  INDICATOR_DATA);
   SetIndexBuffer(7,  BufBuy,      INDICATOR_DATA);
   SetIndexBuffer(8,  BufSell,     INDICATOR_DATA);
   SetIndexBuffer(9,  BufDir,      INDICATOR_DATA);
   SetIndexBuffer(10, BufEntry,    INDICATOR_DATA);
   SetIndexBuffer(11, BufSL,       INDICATOR_DATA);
   SetIndexBuffer(12, BufTP1,      INDICATOR_DATA);
   SetIndexBuffer(13, BufTP2,      INDICATOR_DATA);
   SetIndexBuffer(14, BufTP3,      INDICATOR_DATA);
   SetIndexBuffer(15, BufBoxTop,   INDICATOR_DATA);
   SetIndexBuffer(16, BufBoxBot,   INDICATOR_DATA);
   SetIndexBuffer(17, BufBuyPct,   INDICATOR_DATA);
   SetIndexBuffer(18, BufBoxState, INDICATOR_DATA);

   for(int p = 0; p < 15; p++)
      PlotIndexSetDouble(p, PLOT_EMPTY_VALUE, EMPTY_VALUE);

//--- wick candle colours come from the user's palette ---------------
   PlotIndexSetInteger(0, PLOT_COLOR_INDEXES, 2);
   //--- Pine paints the highlight with color.new(col, 70)
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 0, WSB_Fade(InpColBull, 70));
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 1, WSB_Fade(InpColBear, 70));

   PlotIndexSetInteger(1, PLOT_ARROW, 233);
   PlotIndexSetInteger(2, PLOT_ARROW, 234);
   PlotIndexSetInteger(1, PLOT_ARROW_SHIFT,  12);
   PlotIndexSetInteger(2, PLOT_ARROW_SHIFT, -12);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, InpColBull);
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, InpColBear);

   PlotIndexSetString(3,  PLOT_LABEL, "bt_buy_score");
   PlotIndexSetString(4,  PLOT_LABEL, "bt_sell_score");
   PlotIndexSetString(5,  PLOT_LABEL, "SignalDir");
   PlotIndexSetString(6,  PLOT_LABEL, "Entry");
   PlotIndexSetString(7,  PLOT_LABEL, "SL");
   PlotIndexSetString(8,  PLOT_LABEL, "TP1");
   PlotIndexSetString(9,  PLOT_LABEL, "TP2");
   PlotIndexSetString(10, PLOT_LABEL, "TP3");
   PlotIndexSetString(11, PLOT_LABEL, "BoxTop");
   PlotIndexSetString(12, PLOT_LABEL, "BoxBottom");
   PlotIndexSetString(13, PLOT_LABEL, "BuyVolPct");
   PlotIndexSetString(14, PLOT_LABEL, "BoxState");

   IndicatorSetString(INDICATOR_SHORTNAME, WSB_SHORT);
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

//--- warm-up must cover every lookback the engine uses --------------
   //--- Wilder smoothing needs room for the seed to decay; 5x the ATR
   //--- length puts the residual error below 0.01% before bar `first`.
   g_warmup = MathMax(MathMax(MathMax(InpAtrLen, InpTpAtrPeriod),
                              MathMax(InpSizeLen, InpWindowSize)), 50)
              + 30 + 5 * MathMax(InpAtrLen, InpTpAtrPeriod);

   for(int p = 0; p < 15; p++)
      PlotIndexSetInteger(p, PLOT_DRAW_BEGIN, g_warmup);

//--- settings sanity -------------------------------------------------
   if(InpMinWickBars > InpWindowSize)
      Print(WSB_SHORT, ": WARNING - 'Min. number of wick candles' (", InpMinWickBars,
            ") exceeds 'Window size' (", InpWindowSize,
            "). No formation can ever be detected.");
   if(InpRrTP2 <= InpRrTP1 || InpRrTP3 <= InpRrTP2)
      Print(WSB_SHORT, ": WARNING - TP risk-reward ratios are not in ascending order.");

   WSB_ResetState();
   g_alertBar = 0;     // de-dupe cursor is cleared once, at attach only
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator de-initialisation function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   WSB_DeleteAll();
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
      return(0);

   bool fullPass = (prev_calculated == 0);

//--- refresh cached series first: while data is still loading there
//--- is nothing to reset, and returning 0 asks the terminal for one
//--- more full pass once the ATR history is available.
   if(!WSB_UpdateData(rates_total, time[rates_total - 1], fullPass,
                      open, high, low, close, tick_volume, volume))
      return(0);

   if(fullPass)
     {
      WSB_ResetState();
      WSB_DeleteAll();
      WSB_ClearBuffers();
     }

//--- alerts fire only for this exact bar, and only after the very
//--- first attach has finished loading its history
   g_liveBarTime    = time[rates_total - 2];
   g_suppressAlerts = (fullPass && g_firstPass);

   int lastClosed = rates_total - 2;
   int first      = g_off + g_warmup;
   if(prev_calculated > 1)
      first = MathMax(first, prev_calculated - 2);
   if(first < 1)
      first = 1;

   for(int i = first; i <= lastClosed; i++)
     {
      if(time[i] <= g_lastProcTime)
         continue;
      if(WSB_ProcessBar(i, rates_total, time, open, high, low, close))
         g_lastProcTime = time[i];
     }

   g_suppressAlerts = false;
   g_firstPass      = false;

//--- the forming bar never carries a signal -------------------------
   WSB_ClearBar(rates_total - 1);

//--- ...but it DOES carry the live box state, so an EA polling
//--- shift 0 sees the box that is actually on screen
   if(g_boxActive)
     {
      int    live = rates_total - 1;
      double tv   = g_boxBullVol + g_boxBearVol;
      BufBoxTop[live]   = g_boxTop;
      BufBoxBot[live]   = g_boxBottom;
      BufBuyPct[live]   = (tv > 0.0 ? g_boxBullVol / tv * 100.0 : 50.0);
      BufBoxState[live] = 1.0;
     }

//--- live presentation: extend the waiting box and the TP/SL set ----
   if(g_boxActive)
      WSB_RenderBox(rates_total, rates_total, time,
                    WSB_At(g_atrF, lastClosed),
                    WSB_Fade(InpColNeutral, InpBoxFillTransp),
                    WSB_Fade(InpColNeutral, InpBoxBordTransp), rates_total);

   if(g_tpDir != 0 && !g_tpClosed)
      WSB_RenderTpsl(rates_total, rates_total, time);

   WSB_DrawPanel();

   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Keep the panel anchored when the chart is resized                |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   if(id == CHARTEVENT_CHART_CHANGE)
     {
      WSB_DrawPanel();
      ChartRedraw();
     }
  }
//+------------------------------------------------------------------+
