# Pine Indicators

TradingView Pine v6 indicators for intraday and swing trading — opening ranges,
sessions, overnight range, volume-confirmed setups, and real-futures-volume tools.
All overlays, Pine v6, mostly label-free (signals read from color / geometry).

## Indicators

| File | Indicator | TradingView publication |
|------|-----------|-------------------------|
| `fisher_acd_addon.pine` | Fisher ACD + Pivot-Range Add-on v3 | ACD Opening Range System by Fisher |
| `onr_multi_index_sessions.pine` | ONR Multi-Index + Sessions | Overnight Range (ONR) & Session Boxes |
| `kasse_alerts.pine` | Opening-range setups + volume confirmation | Hougaard Opening Setups (School Run / Brunch / 8-Ball / Teen) |
| `kasse_alerts_swing_v7.2.pine` | Weekly / multi-day swing levels | Weekly Swing Levels — Thu/Fri/Mon Hougaard COT |
| `future_volume_profile.pine` | Futures volume profile on any chart (POC / VA / HVN-LVN) | *new — not yet published* |
| `fixed_range_futures_volume_profile.pine` | Futures volume profile over a click-selected range, intrabar precision (POC / VA / HVN-LVN) | Fixed Range Futures Volume Profile — CFD Charts |
| `vwap_stdev_futurevol.pine` | VWAP + StdDev bands, real futures volume | *new — not yet published* |
| `twap_futurevol.pine` | TWAP + bands, futures-session gated, VWAP-spread readout | *new — not yet published* |
| `futures_volume_delta.pine` | Futures volume pane + buy/sell delta + absorption flags | *new — not yet published* |
| `volume_confirmed_orderblocks.pine` | Order blocks validated by real futures volume | *new — not yet published* |
| `liquidity_sweep_volume.pine` | Sweeps quantified: excursion volume + delta from real futures | *new — not yet published* |
| `dealer_gamma_exposure.pine` | Dealer GEX from a pasted option chain: one field, one market, flip / walls / expected move, built-in example | *new — not yet published* |
| `gamma_exposure_profile.pine` | GEX profile from a manually pasted option chain (flip, walls) | *new — not yet published* |
| `rsi2_dip_signals.pine` | Daily RSI(2) dip monitor on any timeframe up to 1D: RSI(2) pane, daily SMA200/SMA5 on the chart, result table of the full rule (SMA5 exit, 20-close limit, 3 x ATR10 stop, re-entry) with costs | *new — not yet published* |
| `rsi2_dip_strategy.pine` | Strategy Tester twin of the RSI(2) dip signals: same rule core, fills at the close, cost-aware defaults | *new — not yet published* |

## Real futures volume on CFDs / cash indices

`future_volume_profile.pine`, `fixed_range_futures_volume_profile.pine`,
`vwap_stdev_futurevol.pine` and `twap_futurevol.pine` pull the real traded volume of the matching futures contract via `request.security`
and apply it to the price of the chart you are viewing. Broker tick-volume on
CFDs / spot indices is unreliable; the futures-vs-cash basis is handled
automatically because only the volume is borrowed, the price stays your chart's
price. The TWAP tool uses futures volume as a session gate (equal-weight average
over the bars where the future actually traded) plus an optional VWAP comparison
line — the VWAP-minus-TWAP spread shows whether volume traded above or below the
time average.

The fixed-range profile takes its range from two clicks on the chart (start and
end bar, draggable afterwards) instead of a calendar period. It fetches the
futures volume per intrabar (1-min bars by default) via `request.security_lower_tf`
and matches it by timestamp to the chart symbol's intrabar high/low, so the POC
barely moves when you switch the chart timeframe. Where no intrabar history
exists it falls back to chart-bar resolution and says so in the status label.

Auto-detected futures: NAS→NQ, Dow→YM, DAX→FDAX, S&P→ES, FTSE→Z (manual override).

## License

MIT — see [LICENSE](LICENSE). Educational / analysis tools, not financial advice.
