# Componentes extraíveis — QKE (conteúdo MR Mt4 Ultra Fast)

Status: **candidatos, ainda não validados**.

1. **Momentum de cinco candles:** `close > close[5]` para compra, `<` para venda. Usar apenas com confirmação de fechamento e comparação com baseline sem momentum.
2. **Candle de impulso normalizado pela volatilidade:** `high-low > ATR(10)`. Testar outros limites para evitar comprar candle excessivamente esticado; normalizar em múltiplos do ATR.
3. **Localização do fechamento na amplitude:** `(close-low)/(high-low) >= 0.70` (compra); `(high-close)/(high-low) >= 0.70` (venda), protegendo caso amplitude seja zero.
4. **Cooldown paramétrico:** testar 0, 2, 5 candles, contra bloqueio por posição real, sem presumir que menos operações são melhores.

**Não extrair como estratégia lucrativa:** os símbolos `W/L`, suposto martingale, ou EMA/SMA como filtros — estas não participam dos gatilhos originais. Evitar qualquer martingale por padrão.

Plano auditável XAUUSD M1, M5, M15, M30: baseline fiel do sinal; baseline com candle fechado; execução na abertura seguinte com custos; teste de força do candle isolada e combinada com estrutura; walk-forward; medir entradas, payoff, retorno líquido, drawdown, sensibilidade a slippage. Nunca promover sem comprovação fora da amostra.