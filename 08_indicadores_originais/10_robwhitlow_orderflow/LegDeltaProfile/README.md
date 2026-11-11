# Leg Delta Profile

Horizontal net-delta profile of the current active swing leg, pinned to the right edge of the chart. Row length scales with |delta|, neutral rows are hidden, and POC + delta-POC are marked.

**Script:** [`LegDeltaProfile.pine`](LegDeltaProfile.pine)

---

## What it does

Between the last confirmed swing pivot and the current bar, Leg Delta Profile builds a horizontal histogram of net delta per price row and anchors it to the right side of the chart. Rows extend leftward, with length scaling to |delta| — so you can see, at a glance, exactly where in the leg buyers or sellers pressed hardest.

Unlike a standard volume profile that shows total activity, this profile shows **net directional pressure only** — the price levels where one side won, and by how much. Neutral rows (where ask and bid volume roughly cancel) are dropped entirely, so the visualization stays clean and only real imbalances stand out.

## Key features

- **Right-anchored, always visible** — Profile is pinned N bars past the last bar, extending left. Never gets covered by price action. Update setting to match your normal right-side margin.
- **Net-delta rendering** — Row color = which side won at that price (blue = ask dominant, red = bid dominant). Row length = magnitude. Neutral rows are hidden.
- **Configurable row height** — Set in ticks. Smaller ticks = finer resolution, larger = broader zones. Default 2 ticks works well on ES/NQ.
- **POC marker** — Solid horizontal line at the price row with highest total volume in the leg. This is your leg's "fair" price.
- **dPOC (delta POC) marker** — Dashed line at the row with highest |net delta|. This is where the biggest one-sided battle happened — often not the same as the volume POC, which is exactly what makes it interesting.
- **Auto-resets on new leg** — Every confirmed pivot clears the profile and starts fresh. No manual reset needed.
- **Live-updating on the current bar** — The forming bar's intrabar delta contribution is layered in on every tick without double-counting on close.

## How delta is calculated

`request.security_lower_tf` samples 1-second (configurable) sub-bars. Each sub-bar's volume is classified as ask (close up), bid (close down), or split (doji), and distributed uniformly across the price buckets it touched (using its high-low range). This produces a per-price ask/bid split, which the profile subtracts to get net delta per row.

Because delta is inferred from LTF sub-bars, fidelity is ~70-85% of a real bid/ask footprint on liquid futures.

## Best used on

Liquid futures on 1-5 minute charts, ideally intraday. Great for reading intraday reversals: when the leg's dPOC sits well below the swing high (in a rally leg), that's classic absorption — sellers were doing damage the entire way up.

## Key settings

- **Swing Pivot Strength** — Controls how long each leg needs to be before the profile resets. Higher = fewer, wider legs. Default 5 is intraday-appropriate.
- **Row Height (ticks per bin)** — Trades resolution for cleanliness. Default 2 works on ES/NQ; use 1 for finer detail, 4-5 for higher timeframes.
- **Right Anchor Offset** — How far past the last bar the profile's right edge sits. Match to your usual right-side padding.
- **Max Histogram Width** — The widest row extends this many bars left of the anchor. Larger = more visual weight for the profile.
- **Neutral Band** — Drops rows where |delta| / total is below this fraction. Raise to declutter, lower to show more.

## What it isn't

- Not a full volume profile. This deliberately shows net delta only — for a total-volume profile, use TradingView's built-in Volume Profile.
- Not a real footprint. Delta is inferred from LTF close-vs-open, not real bid/ask trades.
- Not historical. Only the currently active leg is drawn. Once a pivot confirms, the profile clears and rebuilds from the pivot forward.

## MotiveWave counterpart

For real per-tick bid/ask classification instead of LTF approximation, see the Java version in the [MotiveWave repo](https://github.com/Robwhitlow3/motivewave-orderflow-indicators/tree/main/LegDeltaProfile).

---

## License

MIT. See the repo [LICENSE](../LICENSE).
