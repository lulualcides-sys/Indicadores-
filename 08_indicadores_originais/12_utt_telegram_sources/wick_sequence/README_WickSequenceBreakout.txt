====================================================================
 WICK SEQUENCE BREAKOUT - UTT Edition
 UTT_WickSequenceBreakout.mq5  v1.00
 MetaTrader 5 port of "Wick Sequence Breakout" (Pine v6)
 UltimateTrading.tools
====================================================================

--------------------------------------------------------------------
0. LICENCE - READ THIS BEFORE SELLING OR REDISTRIBUTING
--------------------------------------------------------------------
The original Pine Script is (c) Uncle_the_shooter and is published
under the Mozilla Public License 2.0.  This MQL5 file is a
derivative work, so it stays under MPL 2.0.

What MPL 2.0 allows: commercial use, sale, and bundling with your
own closed-source products.

What MPL 2.0 requires: the copyright and licence notice at the top
of the .mq5 must stay intact, and anyone you give the compiled .ex5
to must be able to obtain the source of this MPL-covered file.
Shipping the .mq5 alongside the .ex5 satisfies that.

You cannot relicense it, and you cannot strip the attribution.
If you intend to sell this, keep the header block as it is.


--------------------------------------------------------------------
1. INSTALLATION
--------------------------------------------------------------------
Single self-contained file - no include files, nothing to copy into
MQL5\Include.

  File > Open Data Folder
  MQL5\Indicators\UTT\UTT_WickSequenceBreakout.mq5

Open it in MetaEditor and press F7.  Refresh the Navigator and drag
it onto a chart.


--------------------------------------------------------------------
2. THE IDEA
--------------------------------------------------------------------
A cluster of candles rejecting from one side marks a zone that
somebody is defending:

  long UPPER wicks  = sellers pushing price back down
  long LOWER wicks  = buyers pushing price back up

When enough of those candles print inside a short window, the engine
draws a box across the cluster's high and low, splits the volume
inside that box into buy-side and sell-side, and then waits.

A signal fires only when price breaks the box AND the break
direction agrees with the side that owned the volume.  A downside
break out of a box the buyers owned is ignored - that is the whole
point of the tool.


--------------------------------------------------------------------
3. PIPELINE
--------------------------------------------------------------------
1. Classify each candle
     upper wick share = (high - max(open,close)) / range * 100
     lower wick share = (min(open,close) - low)  / range * 100
   A bearish-formation candle needs a big upper wick and a small
   lower wick; a bullish one is the mirror.  Candles smaller than
   ATR x multiplier are skipped entirely (optional).

2. Count them in a rolling window
     "min N of Y" - default 3 of the last 5 candles.
   The formation is EXCLUSIVE: if both sides qualify at once,
   neither counts.

3. Open a box on the rising edge of a one-sided formation
     top    = highest high of the window
     bottom = lowest low of the window
   The buy/sell volume already inside the box is back-filled with
   the close-position proxy:
     buy  += vol * (close - low)  / range
     sell += vol * (high - close) / range
   and keeps accumulating while the box waits.

4. Wait for a break
   By high/low, or by close (input).  The box is cancelled after
   "Breakout wait limit" bars with no break.

5. Validate
   Break up needs buy volume >= sell volume.
   Break down needs sell volume > buy volume.
   Optional extra filter: the breakout candle must be at least
   N x the recent average candle range.

6. Draw the trade
   Entry at the breakout candle's close, SL from ATR or a fixed %,
   TP1/TP2/TP3 at your risk-reward multiples, with the risk and
   reward zones shaded.  The set is frozen when SL or the furthest
   displayed TP is touched.


--------------------------------------------------------------------
4. WHAT CHANGED IN THE PORT (and why)
--------------------------------------------------------------------
Everything below is a deliberate, documented decision.  Everything
else is a line-for-line reproduction of the Pine.

CLOSED-BAR SIGNALS
  The Pine evaluates the breakout intrabar, so a triangle can appear
  and then vanish before the candle closes.  This port takes every
  decision on closed bars only (rates_total-2).  A printed signal is
  final.  Boxes and TP/SL lines still extend to the live bar - that
  is display, not logic.

ATR IS COMPUTED IN-HOUSE
  Pine's ta.atr() is Wilder's RMA of true range.  MetaTrader's
  built-in iATR() is a SIMPLE moving average of true range - a
  materially different series.  Because that ATR decides whether a
  candle is large enough to count at all, using iATR would shift
  every wick classification and therefore every signal.  The port
  computes Wilder's RMA directly so it tracks the original.

TRANSPARENCY
  MT5 graphical objects are opaque; Pine's color.new(col, 85) has no
  equivalent.  The port blends each colour toward the chart
  background by the same percentage, which is what the eye sees on
  TradingView.  Change your chart background and the boxes follow.

BOX BORDERS
  A filled MT5 rectangle paints with one colour only, so the
  formation box is drawn as a filled rectangle plus a second
  unfilled outline rectangle - that is how it keeps an 85% fill and
  a 60% border like the original.

CANDLE HIGHLIGHT
  MT5 cannot recolour the chart's own candles, so wick candles are
  overpainted with a DRAW_COLOR_CANDLES plot at the same 70%
  transparency the Pine uses.

LABELS
  Pine labels have a coloured background with white text; MT5 text
  objects do not.  The port colours the text instead.  The two-line
  "Buy % / Sell %" label becomes two stacked text objects.

VOLUME
  Pine's `volume` is whatever TradingView supplies.  MT5 FX and
  synthetic feeds carry no real volume, so the default is tick
  volume, with a "Volume source" input if you are on an exchange
  feed.  A minority volume bar is clamped to one bar wide so it
  cannot render as a zero-width artifact.

ALERTS
  Pine's alertcondition() only defines an alert template.  This port
  fires real alerts - popup, push, email, sound - and only for the
  bar that has just closed in live trading.  Reattaching the
  indicator never replays history.


--------------------------------------------------------------------
5. EA INTEGRATION (iCustom)
--------------------------------------------------------------------
Buffers 7..18 are DRAW_NONE state buffers.  Note these are BUFFER
indices, not plot indices - plot 0 (the candle highlight) consumes
five buffers on its own.

   0..3  wick-candle O/H/L/C     11  SL price
   4     wick colour index       12  TP1 price
   5     bullish arrow price     13  TP2 price
   6     bearish arrow price     14  TP3 price
   7     bt_buy_score   1/0      15  box top
   8     bt_sell_score  1/0      16  box bottom
   9     signal direction +1/-1  17  buy volume share 0..100
  10     entry price             18  box state

  box state:  0 idle   1 active   2 closed bullish
              3 closed bearish    4 closed invalid   5 timed out

Example:

   int h = iCustom(_Symbol, PERIOD_CURRENT,
                   "UTT\\UTT_WickSequenceBreakout");
   double dir[1], entry[1], sl[1], tp1[1];
   CopyBuffer(h,  9, 1, 1, dir);     // shift 1 = last CLOSED bar
   CopyBuffer(h, 10, 1, 1, entry);
   CopyBuffer(h, 11, 1, 1, sl);
   CopyBuffer(h, 12, 1, 1, tp1);
   if(dir[0] > 0.5) { /* long setup */ }

Read signals at shift 1 - shift 0 is the forming bar and is
deliberately empty.  Buffers 15..18 are the exception: they DO carry
the live box at shift 0, so you can see the box that is currently on
screen.

The TP/SL buffers stay populated even with "Show TP/SL levels"
turned off - that switch only hides the drawing.


--------------------------------------------------------------------
6. TUNING NOTES
--------------------------------------------------------------------
Min. wick candles / Window size
  3 of 5 is the default.  4 of 6 or 4 of 7 gives fewer, cleaner
  formations.  Setting the minimum above the window size makes
  detection impossible - the indicator warns about this in the
  Experts log.

Wick share thresholds
  45% / 25% is a fairly strict rejection candle.  Loosening the
  minimum to 35% roughly doubles the number of formations.  Do not
  loosen both sides far enough that a candle can satisfy bull and
  bear at once - the formation logic will then cancel itself out.

Filter small candles (ATR)
  Leave on.  Without it, doji clusters in dead sessions produce
  formations that mean nothing.

Breakout by close price
  Off = a wick through the box counts.  On = only a close beyond the
  box counts, which is slower but cuts stop-hunt fakeouts.

Breakout wait limit
  100 bars is generous.  On M5/M15 try 30-50 so stale boxes do not
  linger.

Filter by breakout candle size
  Off by default.  Turn it on in choppy conditions - it requires the
  breaking candle to actually be a breakout candle.

Max historical boxes
  60 by default.  Each box is a handful of chart objects; raise it
  only if you need deep visual history.


--------------------------------------------------------------------
7. PANEL
--------------------------------------------------------------------
Top-right, auto-sized by timeframe:

  Wick candles   how many bull / bear wick candles in the window
  Need           the "min N of Y" requirement
  Box            IDLE / ACTIVE / BULL BO / BEAR BO / INVALID /
                 TIMEOUT
  Volume split   buy vs sell share inside the current box
  Bars waiting   how long the box has been open, against the limit
  Active setup   LONG / SHORT while a TP/SL set is live

====================================================================
