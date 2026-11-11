# Nexus Volatility Squeeze Break NR v1.00

Indicador **independente** de compressão de volatilidade (Bollinger vs canal Keltner aproximado por ATR) para MetaTrader 5.

**Gatilho**: uma vela **FECHADA** rompe além da máxima/mínima dos 12 candles anteriores, com corpo direcional; a relação `BB meia largura <= Keltner × ATR` valia no candle anterior e **deixa de valer** no candle do sinal. ATR e bandas são calculados com preços conhecidos naquele instante. Duas setas BUY/SELL são exibidas após o fechamento, sem linhas/caixas que poluam o gráfico. Não envia ordens.

- Aplicável aos períodos M1/M5/M30/H1; limiares são hipóteses de engenharia, **não otimizados**.
- Não confundir saída de compressão com probabilidade de tendência; cenários de falsa expansão exigem backtest.
- `InpAlerts=false` por padrão.
- Regras e testes Python próprios em `research/reference.py` e `tests/`.
- **Sem MetaEditor nem ticks MT5 verificados**; backtest financeiro e compilação pendentes.

Referências técnicas, sem copiar código:
- https://www.mql5.com/en/code/22615 — Bollinger bands squeeze, mladen
- https://www.mql5.com/en/code/20273 — TTMS, Scriptor
- https://www.mql5.com/en/code/24731 — Squeeze, mladen

Regras permanentes: candle 0 ignorado, setas históricas imutáveis durante novos ticks normais, avaliação do sinal apenas depois do fechamento da vela.
