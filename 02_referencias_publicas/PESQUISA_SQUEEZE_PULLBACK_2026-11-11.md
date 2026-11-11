# Duas estratégias adicionais em pesquisa (11/11/2026)

Fontes primárias revisadas:
- [Bollinger Bands Squeeze, mladen](https://www.mql5.com/en/code/22615) — bandas dentro do Keltner como sinal de compressão. Código MQL5 publicamente disponível, licença específica de reprodução a verificar.
- [TTMS, Scriptor](https://www.mql5.com/en/code/20273) — versão histórica de squeeze e faixas; útil para diferenciar **detecção de compressão** de **gatilho de entrada**.
- [Squeeze, mladen](https://www.mql5.com/en/code/24731) — relação desvio-padrão/ATR para regime.
- [ADX Trend Pullback EA, WazaTrader](https://www.mql5.com/en/code/73958) — referência conceitual de EMA/ADX/ATR em velas fechadas; é **EA**, não um indicador para copiar.
- [ATR MetaQuotes](https://www.mql5.com/en/code/12) — definição convencional de True Range/ATR.

## Conclusão
Criar **dois indicadores autorais** que não são duplicatas do H1 ORB, sweep, FVG, VWAP, Structure e Clean:

1. **Volatility Squeeze Break NR**: detecta saída de compressão e exige rompimento da faixa anterior, com seta apenas após o candle fechar.
2. **EMA Trend Pullback NR**: exige contexto EMA 20/50 e reteste da EMA rápida + retomada, sem olhar candles futuros.

Padrão visual: setas discretas, sem labels gigantes, SL/TP no EA de teste separado. Sem prometer resultados. Não copiar arquivos originais, especialmente produtos de licença não confirmada.

**Limites:** nenhum desses indicadores foi compilado no MetaEditor nem submetido ao MT5 Strategy Tester nesta etapa. Os testes Python são sintéticos, não backtests financeiros.
