# MQL5 Indicators

A collection of clean, dependency-free indicators for **MetaTrader 5**, written in MQL5.

Every indicator here is self-contained — **no DLLs, no external libraries** — compiles with
**0 errors / 0 warnings** in MetaEditor, and works on any symbol and timeframe. The code is
readable and commented, so it is easy to adapt to a specific brief.

> Author: **Miron Konkov** · MQL5 profile: _add your profile link here_
> Open to custom indicator and Expert Advisor work — clear brief in, working tool out.

---

## Indicators

### 1. MTF RSI Dashboard
An on-chart panel that displays the RSI value for four timeframes (M15, H1, H4, D1)
simultaneously, so you can confirm momentum alignment without switching charts.
Overbought values are highlighted in red, oversold in green.

![MTF RSI Dashboard](screenshots/MTF_RSI_Dashboard.png)

**Inputs:** RSI period, overbought / oversold levels, panel position, text color.

---

### 2. Smoothed Heikin Ashi with Alerts
EMA-smoothed Heikin Ashi candles that filter market noise and make the trend direction
easier to read. Fires a popup alert and an optional push notification the moment the last
closed candle changes color, so a trend shift is never missed.

![Smoothed Heikin Ashi](screenshots/SmoothHeikinAshi_Alerts.png)

**Inputs:** smoothing period, popup alert on/off, push notification on/off.

---

### 3. Session Highlighter (Asia / London / New York)
Automatically highlights the Asian, London and New York trading sessions with colored
boxes drawn around each session's high–low range, for the last N days. All session hours
(server time) and colors are configurable. Useful for session-based and breakout strategies.

![Session Highlighter](screenshots/SessionHighlighter.png)

**Inputs:** days back, start/end hour per session, color per session.

---

### 4. ATR Stop Loss / Take Profit Levels
Plots dynamic Stop Loss and Take Profit levels based on the ATR indicator, for both long
and short scenarios, with adjustable multipliers. A quick visual aid for volatility-based
risk management.

![ATR SL/TP Levels](screenshots/ATR_SLTP_Levels.png)

**Inputs:** ATR period, SL multiplier, TP multiplier, colors.

---

### 5. Supply & Demand Zones (auto)
Automatically detects swing highs and lows and draws supply (resistance) and demand
(support) zones as rectangles extending to the right of the chart. Sensitivity, scan depth
and the number of zones are all configurable.

![Supply & Demand Zones](screenshots/SupplyDemandZones.png)

**Inputs:** swing size, bars to scan, max zones per type, colors.

---

### 6. Trade Info Panel
A clean on-chart panel showing account balance, equity, floating profit/loss, used and free
margin, current spread and symbol in real time. Floating P/L is color-coded. Read-only — it
does not place, modify or close any orders.

![Trade Info Panel](screenshots/TradeInfoPanel.png)

**Inputs:** panel position, text color.

---

## Installation

1. Open your MetaTrader 5 data folder: **File → Open Data Folder**.
2. Copy the desired `.mq5` file into `MQL5\Indicators`.
3. In MetaEditor, open the file and press **Compile (F7)** — or just restart MetaTrader 5.
4. In the terminal's **Navigator**, find the indicator and drag it onto a chart.

All indicators are compatible with **MetaTrader 5** (MQL5). They do not use DLLs or
external dependencies.

## License

MIT License — free to use, modify and distribute.
