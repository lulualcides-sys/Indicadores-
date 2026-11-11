# Backtest exploratório XAUUSD — seis indicadores

**Não é o MetaTrader 5 Strategy Tester**. Executados modelos Python de referência e um proxy H1 M1 sobre OHLC histórico. Nenhum código MQL5 compilado foi executado.

Dados públicos: https://raw.githubusercontent.com/getdata-finance/xauusd-1m-ohlcv-metals-historical-data/adcd99e7e0abee51e9a5eef123935e68a8d8aa30/XAUUSD_1m.csv

SHA256: a587597bbf88c2d868a00a4e0019cd705cee6ca4f20b0485d6b745f19fcc8225; M1: 179662 barras; intervalo UTC 2026-03-26 02:28:00+00:00 a 2026-09-25 20:44:00+00:00.

Regras: entrada na ABERTURA da vela seguinte, TP1 1R, stop do indicador (quando publicado na referência Python) ou stop além de extremo da vela do sinal com 0,08 ATR; limite 12 candles, uma posição por indicador, colisão intrabar SL primeiro. CUSTOS HIPOTÉTICOS: US$0,40/oz de spread total + US$0,10/oz de slippage por lado (US$0,60/oz por rodada), comissão não incluída. Resultados em R não composto, NÃO representam % da banca. Últimos 30% cronológicos tratados como teste sem otimização.

## Resultado fora da amostra

| Indicador | TF | Sinais | Trades totais | N teste | Acerto % teste | PF teste | R líquido teste | Média R teste | DD teste R |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| H1 Vector Factor | M1 | 1355 | 1355 | 379 | 42.22 | 0.604 | -57.64 | -0.1521 | 57.9 |
| Liquidity Sweep | M1 | 5807 | 5786 | 1804 | 47.73 | 0.432 | -706.6 | -0.3917 | 710.9 |
| FVG Retest | M1 | 6572 | 6313 | 2017 | 45.02 | 0.32 | -1116.39 | -0.5535 | 1116.75 |
| Session VWAP | M1 | 3865 | 2591 | 689 | 50.8 | 0.607 | -155.59 | -0.2258 | 158.15 |
| Structure Break | M1 | 11985 | 11317 | 3437 | 47.83 | 0.489 | -1119.42 | -0.3257 | 1120.13 |
| Clean Signals AUTO | M1 | 13109 | 11665 | 3798 | 46.92 | 0.438 | -1475.64 | -0.3885 | 1478.89 |
| H1 Vector Factor | M5 | — | 0 | 0 | — | — | — | — | — |
| Liquidity Sweep | M5 | 1300 | 1289 | 396 | 50.76 | 0.761 | -51.43 | -0.1299 | 61.61 |
| FVG Retest | M5 | 1267 | 1213 | 387 | 49.61 | 0.663 | -76.66 | -0.1981 | 78.01 |
| Session VWAP | M5 | 1575 | 1051 | 291 | 53.95 | 0.911 | -12.72 | -0.0437 | 25.35 |
| Structure Break | M5 | 2370 | 2259 | 680 | 48.09 | 0.74 | -97.08 | -0.1428 | 102.34 |
| Clean Signals AUTO | M5 | 2545 | 2256 | 715 | 47.13 | 0.677 | -132.19 | -0.1849 | 135.9 |
| H1 Vector Factor | M30 | — | 0 | 0 | — | — | — | — | — |
| Liquidity Sweep | M30 | 191 | 190 | 56 | 46.43 | 0.793 | -6.32 | -0.1128 | 8.41 |
| FVG Retest | M30 | 205 | 198 | 71 | 46.48 | 0.776 | -8.91 | -0.1255 | 12.02 |
| Session VWAP | M30 | 501 | 327 | 94 | 53.19 | 1.097 | 4.19 | 0.0445 | 6.47 |
| Structure Break | M30 | 371 | 355 | 114 | 45.61 | 0.803 | -11.44 | -0.1003 | 12.15 |
| Clean Signals AUTO | M30 | 412 | 369 | 108 | 45.37 | 0.757 | -14.45 | -0.1338 | 17.07 |
| H1 Vector Factor | H1 | — | 0 | 0 | — | — | — | — | — |
| Liquidity Sweep | H1 | 99 | 99 | 37 | 40.54 | 0.694 | -6.37 | -0.1723 | 8.58 |
| FVG Retest | H1 | 88 | 85 | 30 | 53.33 | 1.114 | 1.57 | 0.0522 | 4.77 |
| Session VWAP | H1 | 301 | 219 | 66 | 43.94 | 0.762 | -8.54 | -0.1295 | 11.75 |
| Structure Break | H1 | 187 | 175 | 59 | 40.68 | 0.676 | -10.38 | -0.1759 | 13.26 |
| Clean Signals AUTO | H1 | 203 | 177 | 48 | 45.83 | 0.882 | -2.68 | -0.0558 | 7.89 |

Limitações: bid/ask e ticks ausentes, spreads variáveis não observados, fuso UTC em vez do broker, proxy do MQL5, sem execução no MetaEditor. H1 Vector Factor é exclusivamente M1. Dados não comprovam lucro futuro.
