# Nexus EMA Trend Pullback NR v1.00

Indicador MT5 **independente** de continuidade de tendência após retorno à EMA rápida, preservando visual simples: **setas BUY/SELL apenas**.

**Gatilho BUY**: EMA20 acima EMA50 e EMA50 crescente; candle anterior já fechado toca/registra proximidade da EMA rápida; candle de confirmação fecha acima dela, com corpo comprador suficiente. SELL simétrico. ATR dos candles anteriores normaliza tolerâncias.

- Calcula EMAs causalmente em ordem temporal, sem `shift 0` para entrada.
- Cooldown configurável para evitar excesso de setas consecutivas.
- M1/M5/M30/H1 permitidos; sem alegar vantagem, taxa de acerto ou lucro.
- Apenas `input` e leitura de candles fechados; não executa ordens.
- Reconstrução histórica pelo broker pode mudar candles e valores; teste real de não repintura ainda pendente.

Referência conceitual: https://www.mql5.com/en/code/73958 — ADX Trend Pullback EA, que NÃO foi copiado e é um robô distinto. Outra referência: https://www.mql5.com/en/code/12 (ATR MetaQuotes).

Testes sintéticos e teste de prefixo temporal em `tests/`. Ainda falta compilação MetaEditor e Strategy Tester MT5.
