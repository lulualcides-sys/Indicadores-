# TradingView Indicators

Six free Pine Script v6 indicators for intraday futures traders, built and tested on MNQ (Micro E-mini Nasdaq-100). Each one is a single `.pine` file that draws levels, signals or a panel on a TradingView chart. They are indicators, not strategies, so none of them places an order.

![LiqSweep+iFVG on MNQ 1m](assets/liqsweep-ifvg-mnq-1m.png)

LiqSweep+iFVG on a 1-minute MNQ chart: RAID labels mark session highs and lows being taken, and iFVG LONG and SHORT labels mark the inverted-gap entries that follow.

## Download

Each indicator is one file in this repository. Open the `.pine` file, paste it into the TradingView Pine Editor and add it to your chart.

## What it does

| Indicator | File | Idea |
|---|---|---|
| EMA x VWAP Engulfing | `EMA_VWAP_Engulfing.pine` | Fast EMA against session VWAP, five setups, an eleven-point confluence score |
| LiqSweep+iFVG | `LiqSweep_iFVG.pine` | Session-liquidity raid into inverted-FVG reversal |
| Liquidity Map | `Liquidity_Map.pine` | Engineered liquidity, respected levels, live liquidity blocks and the induce-then-trap trade (v1.7.3) |
| Po3 4H | `Po3_4H.pine` | The 10:00 New York 4H candle read on the 1m chart as accumulation, manipulation, distribution |
| Trend Hub | `Trend_Hub.pine` | Qualified-trend and momentum read across three timeframes |
| Session Pulse | `Session_Pulse.pine` | Volume, range and price efficiency against the same clock minute on earlier days, read as a market state (v2) |

## How it works

Each file is a Pine Script v6 `indicator()` that TradingView runs on the chart you add it to: Session Pulse sits in its own pane and the other five draw on the price chart. Between them they build on session highs and lows for New York, London and Asia, session VWAP, fair value gaps, a volume and range baseline for the same clock minute on earlier days, and higher-timeframe reads. Intended chart timeframes, where a file states one: EMA x VWAP Engulfing 5 minutes and up, Liquidity Map and Session Pulse 1 to 15 minutes, Po3 4H 1 to 5 minutes, and LiqSweep+iFVG is sized for 1 minute.

## Status

Six indicators; Liquidity Map is at v1.7.3 and Session Pulse at v2. Not done yet: the EMA x VWAP Engulfing session-volume gate ships off until its floor is measured against a real dead day, and Po3 4H's built-in CPI and FOMC dates run only to December 2026.

## More advanced indicators

The indicators in this repository are free and open source. I also offer more advanced indicators, invite-only on TradingView, for a small monthly fee.

- TradingView profile: [tradingview.com/u/MatsWilliam](https://www.tradingview.com/u/MatsWilliam/)
- Subscriptions: [whop.com/mwm-indicators](https://whop.com/mwm-indicators/)

## EMA x VWAP Engulfing

Watches one fast EMA against a session VWAP, marks the bar where a confirmation candle
turns that relationship into a trade, and scores the context behind every mark so a thin
signal looks thin instead of looking exactly like a strong one.

- **The map.** Above both the EMA and VWAP is buyer control, below both is seller control,
  between the two lines is a chop zone the indicator refuses to trade by default.
- **Five setups, each with a switch.** A: the EMA crosses VWAP. B: a trend pulls back into
  the EMA and holds it. C: price stretches far from VWAP and turns back. D: price pulls back
  into VWAP and rejects it. E: price rejects the 1-sigma VWAP band and fades to VWAP.
  A, B and D ship on; C and E buy under VWAP and sell over it, so both ship off.
- **Four confirmation shapes.** A body engulfing bar, a rejection wick at VWAP or the EMA,
  a momentum bar that pulls back to the EMA and closes beyond the previous bar, and a tag
  of the 1-sigma band. The momentum shape exists because the others are structurally
  impossible inside a one-way expansion: an engulfing bar needs an opposite-coloured candle
  to swallow, and a rejection wick needs price to still be near VWAP.
- **A score, not a chain of gates.** Eleven context checks each pay a point, including
  volume against the same slot of the session on earlier days, VWAP slope, an EMA that is
  still travelling, minutes held on one side of VWAP, the higher timeframe, and the side of
  a slow third EMA. Five checks can be promoted from a point to a hard veto and four are by
  default. A promoted check stops paying its point, so on the defaults six points are
  reachable. Every signal except a setup E fade is graded A+, A, B or C by the share of the
  reachable points it earned.
- **Day quality.** Two session-level gates stand the indicator down on a day trading well
  below its usual pace or travelling well below its usual range by that point of the
  session, which no per-bar threshold catches. The range gate ships on and the volume gate
  ships off, because its floor has not been measured against a real dead day.
- **Levels die when taken.** The previous day's high and low, the pre-market pair and the
  Asia pair leave the chart and stop paying their confluence point once a bar trades
  through them.
- **A dashboard that explains silence.** A plain verdict line, a three-timeframe trend
  block, one row per check with an ok or no beside it, and a named biggest blocker for the
  session, so a quiet chart tells you which number is too tight.

## LiqSweep+iFVG

Session-liquidity raid into inverted-FVG reversal.

- Tracks each session's high and low (New York, London, Asia) as liquidity levels; a level dies on its first touch, and a new session's level replaces the previous one of the same type. An input ("Untouched levels kept live per session type") optionally keeps the last N sessions' untouched levels live simultaneously, so an older untouched pool can still be raided days later.
- A raid beyond a tracked level (by a configurable buffer) arms a reversal in the opposite direction for a limited window.
- Entry signal: a Fair Value Gap gets body-closed through its far edge against the raid direction (iFVG inversion). One inversion clears every live arm of that direction: one signal per reversal. A gap formed before the sweep can invert; only the inversion has to happen after the raid.
- Optional modules: equal highs/lows tracking (EQH/EQL) with optional raid-arming, a higher-timeframe FVG confluence filter (5m / 15m / 1h / 4h / daily) with optional gap overlay, session boxes, raid labels, premium/discount dealing-range zones, and Williams-fractal swing-point marks.
- Signal timing validated on 60 days of real MNQ 1-minute data: the entry triangle prints on the inversion bar (enter next bar).

## Liquidity Map

[`Liquidity_Map.pine`](Liquidity_Map.pine) draws the liquidity taxonomy the way it is taught by
InterEquity (Marco Accettone), Photon Trading, RealTraderTim, Zamco and the Mind Math Money
course, rather than inventing a new one.

- **Respected levels**: a later pivot touches an earlier pivot without exceeding it and moves away.
- **Equal highs and lows** inside a relative-equal band, with the touch count in the label.
- **Engineered levels**: a respected level sitting short of an intact higher-timeframe reference,
  which is where stops get built rather than where price is going.
- **Liquidity blocks** as live, validated, promotable objects. A block is born only from a spike
  that closes back inside the level (a grab); a close beyond that does not come back within a few
  bars is a run and makes no block. It starts pending and arms when the leg after the sweep prints
  an internal swing (traders were induced) and then breaks the structure it came from. A straight
  run to the break marks it invalid, and no break in time marks it low probability.
- **Block targets and life**: an armed block targets the nearest unrun pool beyond the break
  (respected levels, structure highs and lows, the prior day's high and low, finished session
  highs and lows, the higher-timeframe pivot) and shows its reward-to-risk. It is the anchor for
  the entry and the stop, dies only when that pool is taken or price closes through it, and gets
  promoted when a new high respects it and traps early sellers.
- **Induce, then trap** (v1.6): a close beyond the last pivot marks the traders it induced (IND), and price
  later trading through the origin of that leg marks them trapped. The pool on the other side becomes a TRAP
  box; reactions inside it are counted as engineered liquidity until its `$$$` line is taken.
- **The trade on each trapped zone** (v1.7.3): entry at the trapped high or low itself, stop beyond the nearest
  unswept 3-bar swing plus a share of ATR, target at the nearest unswept 3-bar swing beyond the induced leg,
  else the nearest higher-timeframe or previous-day level. These rules were matched to 27 trades InterEquity
  draws in 22 of his videos: the entry rule lands on his entry in 8 of 19 replayable setups, and stops and
  targets match far less often because he picks them by hand. TP and SL outcomes are tallied in the status
  table as a chart replay, not a backtest.
- **Footprint at the swept level** (v1.5, needs TradingView Premium footprint data): each sweep bar is tagged
  FB (failed break) or ABS (absorbed) from the volume traded at and beyond the level. The tags change no
  block state or alert.
- **Status table** with the live counts, the trade tally and a flag on days that are shaping up as an inside day.
- **Focus mode**, on by default, shows engineered liquidity, its draw and respected levels, and
  puts everything else behind a toggle.

## Po3 4H

[`Po3_4H.pine`](Po3_4H.pine) is a mechanical reading of Jacktrades' "10 a.m. PO3" model, built from
his public videos and PO3 Bootcamp series. The model trades one candle, the 4-hour candle that
opens at 10:00 New York (optionally 14:00), and reads it on the 1-minute chart as a Power of Three.

- **Accumulation**: a box around the 4H open, joined by the pre-open bars when they were sideways.
- **Manipulation**: price takes one side of the box and taps the nearest 15m (else 5m) fair value
  gap, which prints the 4H candle's wick. The gap's timeframe grades the setup: 15m or 1H = A,
  5m = B, 1m = C.
- **Entry**: order-flow confirmation, a 1m gap against the trade inverted (or a change in state of
  delivery), then a new 1m gap respected. In the default Auto mode a gap inverted within 2 bars of
  the extreme enters right there without waiting for the respected gap. Stop at the manipulation
  extreme, target at the box's other edge when that is at least 1R away, else 1R with a break-even
  mark.
- **Days and setups it stands aside from**: the trading day before CPI or FOMC, FOMC day, optional
  Mondays and your own dates; a manipulation too deep without a gap, the far side of the box taken
  first, a close through the nearest 15m/1H gap, and 10:00 entries held until 11:00 after a big
  opening hour. Each blocked entry gets a grey x with the reason on hover.
- **Bias filter**: the previous 4H candle's direction, overruled by a swept and reclaimed
  previous-day extreme. Off runs both directions.
- **SMT**: an entry label carries "SMT" when ES held its box edge while this chart broke it.

Use a 1m to 5m chart. The stats table counts touches on chart bars with no fees or slippage: it
shows whether the indicator marks what he marks, not whether the model makes money. No edge claim
is attached.

## Trend Hub

[`Trend_Hub.pine`](Trend_Hub.pine) is a corner panel, not a signal generator. It reads a qualified
trend on three timeframes at once (5m / 15m / 4H by default): a swing point is actualised after
six bars, a close through the last swing flips the direction, and the volume at that break decides
whether the flip is confirmed or merely suspect. Each row shows direction, a strength meter and an
RSI momentum read.

**The 3/3 alignment row is not an entry trigger.** The panel tells you which way the larger
clock is running so you can size and time a trade you already have a reason to take. Trading the
alignment itself is the mistake it is designed to prevent.

## Session Pulse

[`Session_Pulse.pine`](Session_Pulse.pine) (v2) is a lower pane that reads the market you are in against what
the same clock minute normally looks like over the last 20 sessions. Built for 1m to 15m charts on real
exchange volume.

- **Ribbon and amber line**: rolling relative volume and rolling relative bar range against the median of the
  same minutes, on a log2 scale so 2x and 0.5x sit symmetric around 1.0x. Medians keep one CPI or FOMC minute
  from distorting that slot for weeks.
- **Block volume**: volume since the Asia, London or New York block opened, against a usual block by now.
- **Three lanes**: the market state, aggressor delta (needs TradingView footprint data) and how much of a usual
  block's range is already spent.
- **States**: LIVE, ACTIVE, NORMAL, ABSORB (volume without range), THIN (range without volume), CHOP (low
  efficiency ratio), COIL (contracted ranges) and DEAD. A state shows only after it held 3 bars.
- **Live-bar handling**: on the forming bar the expected volume is scaled by the share of the bar already
  elapsed, so a bar 10 seconds old is not read as dead. A block trading under 40% of its usual volume is
  flagged as a likely contract roll or holiday.

Nothing here is backtested and no predictive claim is attached to any state.

## Disclaimer

These are chart tools, not trading advice. Nothing here is a recommendation to buy or sell anything. Test everything yourself before risking money.

## License

[MIT](LICENSE)
