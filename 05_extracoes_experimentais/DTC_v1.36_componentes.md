# Componentes reutilizáveis — DTC v1.36

**Status de todos os componentes:** EXTRAÍDO PARA AVALIAÇÃO; não comprovado lucrativo.

| ID | Componente | Extração fiel ao original | Uso futuro sugerido | Cuidado |
|---|---|---|---|---|
| DTC-01 | Tendência por 6 EMAs | `EMA30 > EMA35 > EMA40 > EMA45 > EMA50 > EMA60` = alta; ordem inversa = baixa | Classificador de regime | Pode atrasar sinais; testar por timeframe |
| DTC-02 | Evento de início de tendência | Compra se `not bullish_trend[1] and bullish_trend and barstate.isconfirmed`; venda simétrica | Sinal candidato de entrada | Testar frequência e resultado; não replicar bloqueio permanente por estado |
| DTC-03 | Estado MTF | EMA20 > EMA50 para M15/M30/H1/H4/D1 | Variável de contexto/filtro experimental | Original não usa estado MTF nas entradas; confirmar candle HTF |
| DTC-04 | Filtro ATR | `ATR(14)>0.5` | Experimento de piso de volatilidade | `0.5` não é parâmetro universal |
| DTC-05 | Alvos por R | SL fixo 0,25%; TPs a 1R/2R/3R/4R | Grade de testes de gestão de saída | Comparar stop fixo com stop por estrutura/ATR; considerar execução intrabar |
| DTC-06 | Alertas | Alertas condicionais long/short | Telemetria/testes e auditoria de sinais | Alerta não equivale a ordem executada |

## Plano de validação no ouro (sem executar backtest fictício)
- Congelar a versão original como linha de base.
- Comparar sinal original e a versão com controle de posição real (entrada, stop, alvos, encerramento e reinício de elegibilidade).
- Rodar o mesmo período/mesmos custos para M1, M5, M15, M30, separados por treino/validação e dados fora da amostra.
- Comparar política de saída: SL 0,25%, swing/microestrutura e ATR, mantendo o restante fixo em cada comparação.
- Medir trades, PF, expectativa líquida por operação, retorno, drawdown, hit rate, distribuição R, spread/slippage e estabilidade em períodos distintos.
- Só mover para `04_validados_em_backtest/` com evidências reproduzíveis.

Fonte: `../01_originais/DTC_v1.36_TradingView_original.txt`.