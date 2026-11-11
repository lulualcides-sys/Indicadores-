# CVD — Cumulative Volume Delta with Divergence Detection

Session-resetting Cumulative Volume Delta line with automatic detection of classic price/CVD divergence and absorption divergence. Markers render on both the CVD pane and the price chart.

**Script:** [`CVD.pine`](CVD.pine)

---

## What it does

CVD tracks the running total of buying vs selling pressure through the session and highlights the two divergence patterns that matter most in order-flow trading: **classic divergence** (price makes a new extreme, CVD doesn't) and **absorption divergence** (price moves one way while CVD strongly moves the other — someone is quietly soaking up the aggression).

## Key features

- **Session-resetting cumulative line** — Choose RTH (9:30-16:00 ET), ETH/Globex, Daily, or Continuous. Fresh start each session so overnight noise doesn't skew the read.
- **Split coloring** — Line is blue above zero, red below zero. Zero baseline is drawn for context. Instant visual on whether net flow for the session is buyer- or seller-dominant.
- **Classic divergence** — On each confirmed swing pivot, compares against the prior same-type pivot within a configurable lookback. If price makes a higher high but CVD makes a lower high → bearish divergence. If price makes a lower low but CVD makes a higher low → bullish divergence.
- **Absorption divergence** — On a rolling window (default 5 bars), compares price drift to a z-scored CVD drift. If price moves up while CVD moves strongly negative (or vice versa), and both the price move and the CVD z-score clear thresholds, an absorption signal fires. Cooldown prevents repeat prints during a single move.
- **Dual-pane markers** — Signals appear on the CVD pane (circles) AND on the price chart itself (triangles for classic, diamonds for absorption) via `force_overlay=true`, so you don't have to eyeball two panes at once.
- **Alerts** — Four alertconditions ship built in, one per divergence type.

## How delta is calculated

`request.security_lower_tf` aggregates 1-second (configurable) sub-bars, classifying each as ask (close up), bid (close down), or split (doji). This runs continuously and gets summed session-over-session. Fidelity is ~70-85% on liquid futures vs a real bid/ask tick feed.

## Best used on

Liquid futures — ES, NQ, YM, RTY, CL, GC on 1-15 minute charts, or the equivalent CME micros. Divergence signals are most reliable at prior day's high/low, VWAP, or session extremes. On lower-volume symbols the CVD line still works but divergences are noisier.

## Key settings

- **Session Reset** — Match this to how you trade. RTH-only traders should use RTH; overnight traders should use ETH or Continuous.
- **Swing Pivot Strength** — Higher = fewer but higher-quality pivots. Lower = more frequent divergence checks. Default 5 is a good middle ground for intraday.
- **Absorption · Min Price Move (% of ATR)** — Price must actually move meaningfully for absorption to qualify. Raising this filters chop; lowering it catches more subtle absorption.
- **Absorption · Min Opposite Delta |Z|** — How statistically unusual the counter-CVD move must be. Default 1.5 is the standard "worth noticing" bar.

## What it isn't

- Not a real bid/ask CVD. Pine cannot access true tick data — this is an LTF approximation.
- Not a trading strategy. Divergences are context, not entry signals. Confirm with your own read: price structure, key levels, higher-timeframe direction.

## MotiveWave counterpart

For real per-tick bid/ask classification instead of LTF approximation, see the Java version in the [MotiveWave repo](https://github.com/Robwhitlow3/motivewave-orderflow-indicators/tree/main/CVD).

---

## License

MIT. See the repo [LICENSE](../LICENSE).
