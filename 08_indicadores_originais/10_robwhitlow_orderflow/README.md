# TradingView Orderflow Indicators

A collection of open-source orderflow indicators for [TradingView](https://www.tradingview.com/), written in Pine Script v6. Sister repo to my [MotiveWave orderflow suite](https://github.com/Robwhitlow3/motivewave-orderflow-indicators) — same core ideas, adapted to Pine's constraints.

Originally built as a paid indicator suite; released here under MIT for anyone who wants to learn, use, or build on top of them.

**Author:** Rob Whitlow
**Published on TradingView:** [@Robwhitlow3](https://www.tradingview.com/u/Robwhitlow3/)

---

## Indicators

| Study | Type | What it does |
|---|---|---|
| [Delta Pulse](DeltaPulse/) | Chart overlay | Three-layer delta visualization: z-score gradient bars, extreme-move climax markers, and per-leg absorption arrows |
| [CVD](CVD/) | Sub-pane + overlay markers | Session-anchored cumulative volume delta with classic and absorption divergence detection |
| [Leg Delta Profile](LegDeltaProfile/) | Chart overlay | Active-leg net-delta histogram pinned to the right of price, with POC and dPOC markers |

---

## Installation

There's no build step — Pine Script runs inside TradingView. Two ways to use these:

### Option A: Paste into the Pine Editor

1. Open any chart on TradingView.
2. Click **Pine Editor** at the bottom of the screen.
3. Delete the boilerplate, paste in the contents of the `.pine` file you want.
4. Click **Save**, name it, then click **Add to chart**.

### Option B: Add from the public script library

Each of these is also published on my [TradingView profile](https://www.tradingview.com/u/Robwhitlow3/). Open the script's page, click **Add to favorites**, then apply it to any chart from the **Indicators → Favorites** menu.

---

## How these work (in general)

All three studies share a common architecture worth understanding before diving into any single one:

**Delta is approximated from lower-timeframe bars.** Pine Script does *not* have access to true bid/ask tick data. To estimate per-bar delta, each study calls `request.security_lower_tf(syminfo.tickerid, "1S", ...)` to pull 1-second sub-bars, then classifies each sub-bar's volume as ask (close > open), bid (close < open), or split (doji). Summed over the bar, this gives an approximated `ask − bid` delta. Fidelity vs a real footprint feed is typically **70-85% on liquid futures** — good enough for the patterns these indicators detect, but not a substitute for a real orderflow platform if you need exact tick attribution.

**LTF resolution is configurable.** Every script exposes an `LTF Resolution` input (1S / 5S / 10S / 15S / 30S / 1m). 1S is most accurate but has historical-reach limits on most TradingView plans; raise it if you need to look back further or hit data errors.

**Z-scores over rolling windows.** Rather than absolute delta thresholds (which don't generalize across instruments and timeframes), these use z-scores of delta against a rolling lookback (default 200 bars). This makes the same threshold work on ES, NQ, CL, and MNQ without retuning.

**Pivot-based leg detection.** Delta Pulse's per-leg arrows and Leg Delta Profile's leg boundaries use `ta.pivothigh` / `ta.pivotlow`, which confirm N bars after the actual pivot. This introduces a lag inherent to any swing-based method — the tradeoff for fewer false pivots.

**Force-overlay on pane studies.** CVD is a sub-pane study but drops markers directly on the price chart via `force_overlay=true`, so you don't have to watch two panes.

**Reading the code.** If you want to learn how Pine handles lower-timeframe delta approximation, start with **CVD** — it's the most self-contained example (LTF pull → per-bar delta → session-anchored cumulative sum → divergence detection). Then read **Delta Pulse** for the z-score gradient and multi-layer rendering pattern, and **Leg Delta Profile** for the persistent-map profile accumulation with live-bar handling.

---

## Compared to the MotiveWave versions

If you're comparing these to the [MotiveWave equivalents](https://github.com/Robwhitlow3/motivewave-orderflow-indicators):

| Aspect | MotiveWave (Java) | TradingView (Pine) |
|---|---|---|
| Delta source | Real per-tick `isAskTick()` / `isBidTick()` classification | Approximated from LTF sub-bar close direction |
| Fidelity | ~100% (real footprint) | ~70-85% on liquid futures |
| History depth | Limited by data feed | Limited by TradingView plan (LTF requests are capped) |
| Rendering | Custom `Figure` draw hooks | Native Pine `plotshape` / `box` / `label` / `line` |
| Alerts | Manual notification setup | Built-in `alertcondition` |

Neither is strictly better — the MotiveWave versions are what I run on my primary charts, but the Pine versions are free, immediately shareable, and cover 80%+ of the signal.

---

## Building on these

MIT license — do whatever you want with them. Fork, modify, extract components, publish variants under your own TradingView account. Attribution to the original author is appreciated but not required.

Some ideas for extensions:

- Custom alert conditions on absorption / divergence events
- Multi-symbol dashboards using `request.security` (e.g. NQ delta shown on the ES chart)
- Session-VWAP overlays anchored to CVD zero-crossings
- Higher-timeframe delta shown as background color on a lower-timeframe chart

---

## Contributing

Bug reports, PRs, and forks all welcome. Open an issue with:

- Chart's symbol and timeframe
- Any error message from the Pine Editor
- What you expected vs what you saw

---

## Related work

- [MotiveWave Orderflow Indicators](https://github.com/Robwhitlow3/motivewave-orderflow-indicators) — the same suite for MotiveWave, written in Java, with real tick-level bid/ask classification.
- [ATAS Orderflow Indicators](https://github.com/Robwhitlow3/atas-orderflow-indicators) — a subset ported to ATAS in C#.

---

## License

MIT. See [LICENSE](LICENSE).
