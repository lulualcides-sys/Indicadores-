# DTC v1.36 — análise técnica do Pine Script

Fonte: `../01_originais/DTC_v1.36_TradingView_original.txt`; cabeçalho `//@version=5`, `indicator(..., overlay=true)`.

## Resumo da lógica
- Seis EMAs dos fechamentos: 30, 35, 40, 45, 50, 60, parâmetros editáveis (fonte, linhas ~34–41, 100–112).
- Tendência compradora quando todas as seis estão ordenadas do período mais curto para o mais longo; vendedora quando ordem inversa (linhas ~110–112).
- Compra quando a tendência compradora surge em candle confirmado; venda simétrica (linhas ~148–157).
- ATR(14) maior que 0,5, se filtro habilitado (linhas ~66–70, 153–157).
- Painel MTF compara EMA20 e EMA50 em 15m, 30m, 1h, 4h e diário, mas **não é condição de entrada** (linhas ~128–143, 317–350).
- Entrada no fechamento do candle de sinal; SL fixo de 0,25% da entrada e TP1/2/3/4 iguais a 1R/2R/3R/4R por padrão (linhas ~193–208).

## Achados verificáveis no código
1. `signal_state` muda apenas em sinais de direção oposta; o código não registra execução, stop atingido ou TP atingido. Isso pode bloquear novos sinais da mesma direção mesmo depois de uma saída hipotética (linhas ~148–157, 192–208).
2. `ta.lowest` e `ta.highest` com janela de 3/5/8/12 barras são calculados, mas seus valores não participam do SL (linhas ~90–97, 162–163, 193–208).
3. Os estados EMA20/50 dos timeframes superiores aparecem no dashboard, mas não filtram BUY/SELL (linhas ~128–157).
4. É `indicator`, não `strategy`: desenha níveis, rótulos e alertas; não há ordens nem P&L verificável no script (linhas ~5–6, 245–315, 352–356).
5. A leitura MTF de períodos ainda abertos pode variar; `lookahead_off` não equivale a confirmação do candle superior. Exigir confirmação se isso virar regra automatizada.
6. `atrMin=0.5` é limiar absoluto e precisa de teste por símbolo/timeframe (linhas ~66–70).
7. Exigir seis EMAs alinhadas pode causar atraso em tendências; hipótese a medir em histórico, não resultado observado.

## Decisão
**Status: PROMISSOR PARA EXTRAÇÃO, NÃO VALIDADO.** Prioridade: definição clara de tendência e geração de evento de primeiro alinhamento. Evitar importar bloqueio de `signal_state` e parâmetros de SL/ATR sem teste.

## Evidências ausentes
- Não há histórico de XAUUSD, custos de corretagem/execução, backtests, métricas ou prova de expectativa líquida positiva no arquivo.
- Nenhuma alteração de robô ou publicação foi feita como parte desta triagem.