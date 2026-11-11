# Delta Pulse

Three-layer visualizer of aggressive order flow: bar-color heatmap, extreme-move climax markers, and per-leg absorption arrows — all driven from a per-bar delta approximated via lower-timeframe data.

**Script:** [`DeltaPulse.pine`](DeltaPulse.pine)

---

## What it does

Delta Pulse converts one number — per-bar delta (ask volume minus bid volume) — into three visual layers on your chart, so you can see aggression, exhaustion, and absorption without switching indicators.

## The three layers

1. **Gradient Map** — Colors each bar based on its delta z-score over a rolling window. Bright blue = statistically strong buying aggression, bright red = strong selling aggression, faded = neutral flow. The intensity scales continuously with |z|, so you get a heatmap of pressure rather than a binary up/down color.

2. **Extreme Move** — Marks sustained one-sided aggression with dots on every qualifying bar, then drops a climax bubble at the extreme high/low once the sequence rolls over. Both a bar-level z-score and a rolling trend-sum z-score must exceed thresholds simultaneously — this filters out isolated spikes and only flags real extended pushes.

3. **Delta Print** — Watches each swing leg for the strongest counter-direction delta bar. When the next pivot confirms, if that bar's |z-score| clears the threshold, an arrow prints at the pivot: a down arrow above a swing high where sellers were absorbed into the rally, an up arrow below a swing low where buyers were absorbed into the selloff. This is the classic "biggest seller into the top" tell.

## How delta is calculated

Pine has no true bid/ask tick data, so the script approximates delta via `request.security_lower_tf`:

- **LTF Tick Proxy (default, 1-second):** For each finished bar, sub-bar volume is classified as ask when the sub-bar closes up, bid when it closes down, and split 50/50 on doji sub-bars. Typical fidelity vs a real footprint feed is ~70-85% on liquid futures.
- **Bar-Close Proxy (fallback):** Whole-bar volume signed by close-vs-open. Coarser, but works on any plan without LTF data access. Useful for higher timeframes or as a sanity check.

## Best used on

Liquid futures (ES, NQ, CL, GC), on 1-15 minute charts. Works on any liquid instrument, but tick-heavy futures give the cleanest signal. Not designed for spot forex or thin altcoins.

## Key settings

- **Delta Source** — LTF Tick Proxy is more accurate; switch to Bar-Close Proxy if you're on a plan without LTF data or working on very long history.
- **Gradient Map · |z| at Saturation** — How extreme delta needs to be before the color hits max intensity. Lower = more colorful chart, higher = only the biggest moves stand out.
- **Extreme Move thresholds** — Both the bar |z| and trend |z| must be exceeded. Raising either produces fewer, higher-conviction climax bubbles.
- **Delta Print · Swing Pivot Strength** — How many bars on each side confirm a pivot. Higher = fewer, larger legs.

## What it isn't

- Not a signal service or automated strategy. All three layers are decision-support visuals.
- Not real footprint data. Delta is inferred from LTF bars, not real bid/ask trades.
- Not a lagging oscillator. Pivots and climax bubbles confirm N bars after the extreme, which is inherent to any swing-based method — that's a feature (fewer false signals), not a bug.

## MotiveWave counterpart

For real per-tick bid/ask classification instead of LTF approximation, see the Java version in the [MotiveWave repo](https://github.com/Robwhitlow3/motivewave-orderflow-indicators/tree/main/DeltaPulse).

---

## License

MIT. See the repo [LICENSE](../LICENSE).
