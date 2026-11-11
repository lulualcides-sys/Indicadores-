====================================================================
 ADAPTIVE MARKET INTELLIGENCE ENGINE - UTT Edition  (AMIE)
 UTT_AdaptiveMarketIntelligence.mq5  v1.00
 MetaTrader 5 port of
 "Buy-Sell with Adaptive Market Intelligence Engine" (Pine v6)
 UltimateTrading.tools
====================================================================


--------------------------------------------------------------------
0. LICENCE - READ THIS BEFORE SELLING OR REDISTRIBUTING
--------------------------------------------------------------------
The original Pine Script is (c) InvestyourAsset, published under the
Mozilla Public License 2.0.  This MQL5 file is a derivative work and
stays under MPL 2.0.

Allowed: commercial use, sale, bundling with your own closed-source
products.

Required: the copyright and licence notice at the top of the .mq5
stays intact, and anyone you hand the compiled .ex5 to must be able
to obtain the source of this MPL-covered file.  Shipping the .mq5
alongside the .ex5 satisfies that.

You cannot relicense it and you cannot strip the attribution.


--------------------------------------------------------------------
1. INSTALLATION
--------------------------------------------------------------------
Single self-contained file - nothing goes into MQL5\Include.

  File > Open Data Folder
  MQL5\Indicators\UTT\UTT_AdaptiveMarketIntelligence.mq5

Open in MetaEditor, press F7, refresh the Navigator, drag onto a
chart.


--------------------------------------------------------------------
2. THE IDEA - SEVEN ENGINES, ONE VERDICT
--------------------------------------------------------------------
Most indicators answer one question.  This one runs six independent
readings of the market and resolves them into a single number per
side, 0 to 100.

  TREND       21/50 EMA stack, plus higher-timeframe confirmation
  STRUCTURE   internal + major pivots, BOS / CHOCH, retests, and
              gradient strength bands drawn between qualifying
              swing pairs
  REGIME      ADX/DMI, Bollinger compression, ATR expansion ->
              one of six regimes
  MOMENTUM    RSI and MACD histogram
  LOCATION    session VWAP on intraday charts, mean EMA otherwise
  VOLUME      participation measured against its own average
  SCORE       everything above resolved into bull score and bear
              score

A BUY or SELL arrow is NOT "score is high".  It fires only at the
START of a new trend:

  1. the winning score clears the minimum (default 86)
  2. it beats the other side by the required margin (default 25)
  3. every enabled filter passes - HTF alignment, participation,
     major structure alignment, strong ADX/DMI
  4. the engine was not already in that trend

One signal per trend.  The engine then LOCKS until the trend fails
for N bars (default 6) or reverses outright.  This is what stops the
stream of same-direction arrows that most confluence tools produce.

Signals are graded A or A+.  A+ is the higher-score tier.


--------------------------------------------------------------------
3. WHAT YOU SEE
--------------------------------------------------------------------
EMA ribbon        fast/slow EMA pair with a filled band between
                  them, coloured by stack direction
VWAP / mean       session VWAP intraday, mean EMA on higher
                  timeframes
Candle colouring  each candle tinted by its confluence score - the
                  gradient IS the read; deep colour is agreement
Structure bands   shaded gradient zones between qualifying swing
                  pairs, only where the leg is big enough and the
                  strength clears the minimum
BOS / CHOCH       dashed lines plus labels on structure breaks
Retests           labels where price returns to a broken level and
                  respects it
Arrows            BUY / SELL at the start of a new trend
Dashboard         the full read - see section 7


--------------------------------------------------------------------
4. NON-REPAINTING
--------------------------------------------------------------------
The original gates structure, retests and the signal state machine
on barstate.isconfirmed.  This port takes EVERY decision on closed
bars (rates_total-2).  Nothing on the chart moves once a bar has
closed.

Higher-timeframe data reproduces Pine's
request.security(..., close[1], lookahead=barmerge.lookahead_on)
idiom exactly: at each chart bar the port reads the HTF bar that had
ALREADY CLOSED at that moment.  No future leak, and no lag beyond
what the original has.


--------------------------------------------------------------------
5. PORT DECISIONS
--------------------------------------------------------------------
Everything not listed here is a line-for-line reproduction.

EVERY SERIES IS COMPUTED IN-HOUSE
  Not a stylistic choice - three MetaTrader built-ins do not match
  their Pine counterparts, and all three feed the score:

    ta.atr()  is Wilder's RMA of true range.  iATR() is a SIMPLE
              moving average of true range.  ATR drives the
              structure break buffer, the retest tolerance, the band
              leg minimum, the EMA separation test and the
              expansion test.

    ta.macd() signal line is an EMA.  iMACD()'s signal line is an
              SMA.

    ta.dmi(diLen, adxSmooth) takes two separate lengths.  iADX()
              takes one.

  RSI, EMA, Bollinger, the SMA baselines and VWAP are computed
  directly alongside them so the whole chain stays consistent.

TRANSPARENCY
  MT5 objects are opaque; Pine's color.new(col, 87) has no
  equivalent.  Every colour is blended toward the chart background
  by the same percentage, which is what the eye sees on
  TradingView.  Change your chart background and the visuals follow.

STRUCTURE BANDS
  Pine draws these with linefill between two SLOPED lines.  MT5 has
  no such primitive.  Each band is built from four filled
  OBJ_TRIANGLE objects - two triangles sharing a diagonal tile the
  parallelogram, and the outer/inner pair reproduces the gradient.
  It is the only MT5 primitive that will fill a slanted shape.

HTF UNAVAILABLE
  If the higher-timeframe series has not downloaded yet, the port
  waits up to 40 passes for it.  If it still is not there it prints
  one line to the Experts tab and falls back to the chart series -
  which is exactly what the original does when useHTF is off.  When
  the data later arrives it rescores the whole history once, prints
  one line, and carries on.  It does not oscillate, and it does not
  silently give you HTF-gated signals computed without HTF data.

CANDLE COLOURING
  Pine's barcolor() has no MT5 equivalent.  Implemented as a
  DRAW_COLOR_CANDLES plot with an 11-step gradient.  Set
  "Confluence candle colouring" to false and your normal chart
  candles show through.

ADDED (not in the original)
  EA state buffers, real MT5 alerts (popup / push / email / sound),
  a measured dashboard, an instance id, and a max-bars cap.  All are
  optional or additive; none change the detection logic.


--------------------------------------------------------------------
6. EA INTEGRATION (iCustom)
--------------------------------------------------------------------
   0  ribbon fill A          16  score difference (bull - bear)
   1  ribbon fill B          17  new trend signal  +1 / -1 / 0
   2  fast EMA               18  signal grade  0 none, 1 = A, 2 = A+
   3  fast EMA colour        19  trend state  +1 / -1 / 0
   4  slow EMA               20  regime code  0..5
   5  slow EMA colour        21  bias  -2..+2
   6  VWAP / mean            22  major structure dir  +1 / -1 / 0
   7  candle open            23  ADX
   8  candle high            24  +DI
   9  candle low             25  -DI
  10  candle close           26  last major swing high
  11  candle colour index    27  last major swing low
  12  BUY arrow price        28  range location  0..3
  13  SELL arrow price       29  break  see below
  14  bull score  0..100     30  retest  +1 bull / -1 bear / 0
  15  bear score  0..100

  regime (20)  0 transition  1 compression  2 range
               3 trend expansion  4 trending  5 volatility expansion
  bias   (21)  +2 strong bull  +1 bull  0 neutral
               -1 bear  -2 strong bear
  range  (28)  0 n/a  1 discount  2 equilibrium  3 premium
  break  (29)  0 none  +1 bull BOS  +2 bull CHOCH
               -1 bear BOS  -2 bear CHOCH

Example:

   int h = iCustom(_Symbol, PERIOD_CURRENT,
                   "UTT\\UTT_AdaptiveMarketIntelligence");
   double sig[1], grade[1], bull[1], bear[1], adx[1];
   CopyBuffer(h, 17, 1, 1, sig);     // shift 1 = last CLOSED bar
   CopyBuffer(h, 18, 1, 1, grade);
   CopyBuffer(h, 14, 1, 1, bull);
   CopyBuffer(h, 15, 1, 1, bear);
   CopyBuffer(h, 23, 1, 1, adx);
   if(sig[0] > 0.5 && grade[0] > 1.5) { /* A+ buy */ }

Read signals at shift 1 - shift 0 is the forming bar and carries no
signal.

Buffer 17 is the event (fires on ONE bar).  Buffer 19 is the state
(stays set for the life of the trend).  Use 17 to enter, 19 to know
whether you should still be in.


--------------------------------------------------------------------
7. DASHBOARD
--------------------------------------------------------------------
Top-right, auto-sized by timeframe:

  Bull / Bear score   the two confluence scores and the gap
  Trend               EMA stack state, and HTF agreement
  Structure           major direction, last break, retest state
  Regime              which of the six regimes is active
  Momentum            RSI and MACD histogram direction
  Location            premium / equilibrium / discount, VWAP side
  Participation       volume against its average
  Signal              the last signal, its grade and its age

The panel measures its own text and sizes itself to fit.  On a
narrow window it steps the font down and then switches to short
labels rather than letting columns overlap.  It re-measures when you
change chart colours, so it stays readable on any scheme.


--------------------------------------------------------------------
8. TUNING NOTES
--------------------------------------------------------------------
New trend minimum score (default 86)
  The single most important dial.  86 is deliberately strict - it is
  what makes the signals rare.  80 roughly doubles the count; 90
  roughly halves it.  Move it before you touch anything else.

Minimum bull/bear advantage (default 25)
  Stops signals where both sides score well, which is what a
  genuinely two-way market looks like.  Lower it and you will get
  signals inside chop.

Higher timeframe (default H4)
  Must be HIGHER than the chart timeframe - the indicator checks
  this on load and tells you if it is not.  H4 on M5/M15 is the
  usual pairing; on H1 charts try D1.

Require HTF alignment (default on)
  Turn this off and the HTF component still scores, it just stops
  being a hard veto.  Roughly doubles the signal count.

Trend reset bars (default 6)
  How long the trend must fail before the engine will arm again.
  Raise it on fast synthetics to stop re-entries into the same move.

Internal / major swing (3 / 8)
  Major drives the structure filter and the bands; internal only
  feeds the labels.  On M1/M5 synthetics 4/10 is calmer.

Minimum structure band strength (58)
  Raise to 65-70 if the chart gets busy - most bands disappear and
  only the decisive legs stay.

Max bars to analyse (5000)
  Drop to 2000 on M1 if the first load feels slow.  Only affects
  history depth, never live behaviour.

Instance id (default 1)
  Only matters if you run two copies on the same chart - give the
  second one a different id so their chart objects cannot collide.


--------------------------------------------------------------------
9. SUGGESTED STARTING POINTS
--------------------------------------------------------------------
Deriv synthetics, M5/M15
  HTF H4, score 86, advantage 25, volume source TICK, trend reset 6.
  Volume on synthetics is tick volume by definition - that is the
  correct source, not a compromise.

XAUUSD, M15/H1
  HTF D1 on H1, H4 on M15.  Score 84.  Require structure ON - gold
  respects major swings well.

Faster / more signals
  Score 80, advantage 18, Require HTF alignment OFF.  Expect roughly
  three to four times the arrows and a lower hit rate.

====================================================================
