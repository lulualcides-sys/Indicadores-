UTT BUYERS & SELLERS PROFILE + DYNAMIC S/R - DERIV EDITION (MT5)
================================================================
UltimateTrading.tools  |  https://ultimatetrading.tools
Version 2.10  |  Licence: CC BY-NC-SA 4.0 (see LICENCE section)

WHAT IT IS
----------
A rolling volume profile drawn to the right of price, split into buyer and
seller share on every row, plus support and resistance levels that are only
kept when the profile agrees with them. Every level gets a 0-100 score, and
every retest of a level is recorded as HELD or BROKE so the dashboard can
show how reliable each score band has been on this market and timeframe.

It is an MQL5 port of the Pine Script v6 "Buyers & Sellers Profile + Dynamic
S/R" by Zeiierman, with a Deriv synthetic-index layer added on top.

INSTALLATION
------------
1. MT5: File > Open Data Folder > MQL5 > Indicators.
2. Copy BuyersSellersProfile_DynamicSR_Deriv.mq5 into that folder.
3. Open it in MetaEditor and press Compile (F7).
4. In MT5, refresh the Navigator and drag the indicator onto a chart.
Tip: Tools > Options > Charts > Max bars in chart = 25000 or more gives the
profile and the reliability tracker enough history.

THE PROFILE
-----------
  Rows             72 price rows across the lookback range (24-100)
  Lookback         9000 minutes by default (600 bars on M15), converted
                   to bars for each timeframe, kept between 100 and 1500
  Buy / sell split each slice of activity is split by where the candle
                   closed in its range (close at the high = all buyers)
  POC              the busiest row, outlined in orange, with a POC line
  Value area       70% of the activity around the POC; VAH / VAL lines
  Level rows       profile rows that hold an active level are outlined in
                   green (support) or red (resistance)

DERIV ADAPTATION (all switchable)
---------------------------------
1) Sub-bar profile. The profile is built from lower-timeframe candles so
   the distribution inside each chart candle is real:
     charts up to H4 -> M1    above H4, below D1 -> M5    D1 and above -> M15
2) Activity volume. Deriv synthetics tick at a constant rate, so tick
   volume carries no information. On synthetics the volume weight is
   activity = candle range + body size of every sub-bar. Forex, metals
   and other symbols keep tick volume. Override with "Volume weight".
3) Market auto-profile. Volatility %, tick speed (1s / 2s) and market type
   are read from the MT5 symbol description and used to scale the search,
   merge and break distances:

  Market             Search x  Merge x  Break support x  Break resistance x
  Volatility <=30%    1.00      1.00       1.00              1.00
  Volatility 31-50%   1.05      1.10       1.10              1.10
  Volatility >50%     1.15      1.25       1.30              1.30
  Boom                1.20      1.20       1.00              2.20 (spike side)
  Crash               1.20      1.20       2.20 (spike side) 1.00
  Step                0.90      1.00       0.80              0.80
  Jump                1.20      1.20       1.60              1.60
  Range Break         1.10      1.10       1.50              1.50
  DEX                 1.20      1.20       1.50              1.50
  Other symbols       1.00      1.00       1.00              1.00

4) Time-based lookback. The window is set in minutes, so it covers the same
   stretch of time on every timeframe.

HOW A LEVEL IS MADE
-------------------
1. A swing low (support) or swing high (resistance) is confirmed 5 bars
   after it forms (Swing Length).
2. The profile at that moment is searched within 1.2 ATR of the swing for
   the best node. Evidence = 50% node strength vs the POC + 20% how much
   the row stands out from its neighbours + 20% buyer share (support) or
   seller share (resistance) + 10% proximity.
3. If node strength >= 0.08 and evidence >= 0.22, the level is pulled up to
   85% of the way from the raw pivot toward the node.
4. Score = 50% evidence + 20% absorption (small bodies on above-average
   activity around the swing) + 15% activity vs its 40-bar average
   + 15% rejection wick. Levels below score 30 are dropped.
5. Levels within 0.16 ATR of each other merge (the stronger one stays).
   At most 20 levels are kept; the weakest goes first.
6. A level is broken when a candle CLOSES more than 0.10 ATR beyond it
   (scaled by the market table above).

On the chart: a dot at the raw pivot, rings and the score at the final
level (more rings = higher score), the level line, and the score plus its
held/tested count at the right edge. Hover a level for its full breakdown.

LEVEL RELIABILITY
-----------------
When price comes within 0.15 ATR of an active level a retest starts. It is
HELD if price then moves 0.50 ATR away from the level in the expected
direction before closing through it, and BROKE if a close breaks it first.
Retests that do neither within 20 bars are dropped. Results are counted by
side and by score band (80+, 60-79, below 60).

DASHBOARD
---------
  Title       symbol and timeframe
  Market      detected market, tick speed, ATR and its ratio to the 200-bar
              average (LOW / normal / HIGH), volume mode, sub-bar timeframe
  Bias        BUYERS in control (price above value area)
              SELLERS in control (price below value area)
              BALANCED inside value (above / below POC), with what to expect
  Support     nearest support below price: distance in ATR, score, held count
  Resistance  nearest resistance above price: same
  Reliability held % per score band, split support / resistance, and total
  READ        a plain-English line: testing a level (with that band's held %
              and the close that would invalidate it), or wait for price to
              reach a level

INPUTS
------
Deriv Adaptation   Auto-adapt, Volume weight, Sub-bar source, Lookback mode,
                   Lookback (minutes), Lookback (bars)
Rolling Profile    Rows, Width, Offset, Show profile, POC, Level rows,
                   Value area %
Pivot Engine       Swing length, Search ATR, Min node, Min evidence, Profile
                   pull, Min score, Max levels, Merge ATR, Break ATR
Level Reliability  Retest band (ATR), Reaction to count as held (ATR),
                   Retest timeout (bars)
Visual Style       colours, line style, pivot dots, raw pivot, dot score,
                   right score, value area lines
UTT Dashboard      show, corner, X / Y offset, font size, colours
MT5 Engine         bars of history (5000), min ms between live redraws
                   (1000), background blending
Alerts             new level, level broken, retest (off by default);
                   popup, push, sound

ALERTS
------
New profile-confirmed support / resistance, and support / resistance broken
on a confirmed close, fire on live bars only - never for history when the
indicator loads. The retest alert (price entering a level's band) is off by
default.

BUFFERS (for EAs via iCustom / CopyBuffer)
------------------------------------------
  0  Nearest support below price
  1  Nearest resistance above price
  2  Profile POC
  3  Value Area High
  4  Value Area Low
  5  Activity (effective volume) per bar
Buffers 0-4 are written on the current bar each time the indicator redraws;
read shift 0. 0.0 means no level on that side.

NOTES
-----
- Levels are evaluated on closed candles. A swing needs 5 more closed
  candles before it can become a level, so new levels appear with that lag.
- Built to stay stable on 1-second indices: it waits for the ATR and the
  lower-timeframe history instead of wiping the chart, and it re-indexes
  itself when MT5 trims old bars ("Max bars in chart").

LICENCE
-------
Original work: "Buyers & Sellers Profile + Dynamic S/R" (Pine Script v6)
(c) Zeiierman, licensed under Creative Commons Attribution-NonCommercial-
ShareAlike 4.0 International (CC BY-NC-SA 4.0):
https://creativecommons.org/licenses/by-nc-sa/4.0/
This MQL5 port and its Deriv additions are shared under the same licence.
Free for non-commercial use. If you share a modified version, credit the
original author, keep it non-commercial and use the same licence.

DISCLAIMER
----------
Educational tool, not financial advice. Trading synthetic indices, forex
and metals carries a high risk of loss. Test on a demo account first.
