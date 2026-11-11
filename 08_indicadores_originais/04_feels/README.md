# FEELS Indicators — Pine Script™ v6 for TradingView

Open-source trading indicators by [FeelsStrategy](https://www.tradingview.com/u/FeelsStrategy/), focused on market structure, liquidity, and volume analysis. All scripts are written in **Pine Script v6** and published on TradingView, where they are used by thousands of traders.

> 📈 Published versions, charts, and usage stats: [tradingview.com/u/FeelsStrategy](https://www.tradingview.com/u/FeelsStrategy/#published-scripts)
> 💬 Free channel: [t.me/FeelsStrategy](https://t.me/FeelsStrategy)

## Indicators

| Indicator | File | What it does |
|---|---|---|
| **Power of Three [FEELS]** | [`indicators/power-of-three.pine`](indicators/power-of-three.pine) | Detects the three-phase cycle (Accumulation → Manipulation → Distribution): a range builds around the cycle open, one side gets swept, and price moves the other way. Tracks per-symbol statistics over past cycles and projects the expected path with historical frequencies. |
| **Air Pocket Profile [FEELS]** | [`indicators/air-pocket-profile.pine`](indicators/air-pocket-profile.pine) | A volume profile that highlights where price has *not* traded. Thin "air pocket" zones tend to be crossed quickly with little resistance, while high-volume nodes act as reference shelves. Includes a volume anchor (PoC), freshness weighting, transit confirmation marks, and anchor-shift detection. |
| **Liquidity Magnet [FEELS]** | [`indicators/liquidity-magnet.pine`](indicators/liquidity-magnet.pine) | A scoring engine for liquidity pools. Every active pool (swing high, swing low, or equal-level cluster) is ranked by probability of being reached; the highest-probability pool is marked as the current magnet. Tracks hit/expire outcomes for self-validation. |
| **Support and Resistance Zones [FEELS]** | [`indicators/support-resistance-zones.pine`](indicators/support-resistance-zones.pine) | Volume-weighted, actionable S&R zones. Instead of drawing lines at every recent high and low, it clusters pivots by ATR distance and only promotes zones with multiple confirmed touches. Presets for local, swing, and major structure. |
| **Confluence Pivot Zones [FEELS]** | [`indicators/confluence-pivot-zones.pine`](indicators/confluence-pivot-zones.pine) | Clusters recent pivots into confluence zones, scores them by strength, and fires entry signals with a per-zone cooldown and strictness filter. |

## Installation

1. Open [TradingView](https://www.tradingview.com/) and go to any chart.
2. Open the **Pine Editor** (bottom panel).
3. Copy the contents of any `.pine` file from [`indicators/`](indicators/) into the editor.
4. Click **Add to chart**.

Alternatively, add the published versions directly from the [FeelsStrategy scripts page](https://www.tradingview.com/u/FeelsStrategy/#published-scripts) — no copy-paste needed, and you get updates automatically.

## Design principles

- **Pine Script v6** — all scripts use the latest Pine version with typed user-defined types (UDTs), arrays, and drawing-object pooling.
- **No repainting tricks** — pivots confirm after `right bars`; signals and statistics are computed on confirmed data.
- **Performance-aware** — bounded buffers (`max_boxes_count`/`max_lines_count` pooling, pivot memory limits) so scripts stay fast on long histories.
- **Self-validating** — where possible, indicators track their own historical hit rates (Liquidity Magnet outcomes, PO3 cycle statistics) so users can judge edge per symbol/timeframe.

## Contributing

Issues and pull requests are welcome — bug reports from different symbols/timeframes are especially useful, since Pine behavior can vary with chart context. For feature ideas, please open an issue first to discuss scope.

## License

[MIT](LICENSE) © Volodymyr Filias (FeelsStrategy)

Pine Script™ is a trademark of TradingView. These scripts are educational tools, not financial advice.
