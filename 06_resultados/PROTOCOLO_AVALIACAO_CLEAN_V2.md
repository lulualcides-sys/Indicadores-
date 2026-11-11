# Protocolo para saber se UM indicador unificado ficou realmente melhor

## Não usar estes atalhos
- Não executar backtest em um proxy Python e apresentá-lo como execução MQL5 compilada.
- Não criar 15 filtros apenas para fazer uma curva positiva no treino; custa frequência e sobreajusta.
- Não exibir `98% de chance` com base em score heurístico.
- Não retroposicionar entrada para início da vela cujo fechamento confirmou o sinal.
- Não tratar tick volume XAUUSD spot como fluxo consolidado de bolsas.

## Matriz mínima a testar no próprio MetaTrader 5
```
Baseline: Clean Signals 1.00 AUTO, BREAKOUT, SWEEP (separados)
R:    faixa de abertura + rompimento/reteste
S:    liquidez confirmada + sweep
W:    VWAP por sessão com última vela fechada
ALL:  fusão R/S/W, sem vetos adicionais, sem duplicar setas
ALL+REGIME: variante opcional para verificar se o contexto agrega valor
```
Cada linha em XAUUSD M1, M5, M30 e H1; quando o indicador não suportar um período, marcar `NÃO SUPORTADO` em vez de simular outro código.

## Regras financeiras comparáveis
- Mesma corretora, intervalo temporal e método de ticks/execução, distinção bid/ask real.
- Entrada só na próxima abertura/próximo tick após confirmação do fechamento.
- Comparar TP1 1R e TP2 2R **separadamente**; SL idêntico no mesmo cenário, com spread/slippage/comissão.
- Um trade por vez por configuração, e especificar se a posição cruzar candle de encerramento do teste.
- Dividir treino e teste com corte temporal estrito; testar variação de spread e datas/sessões.
- Além de PF e resultado líquido, reportar sinais por mês, trades por mês, média R, máximo DD R e taxa de acerto.
- Exigir amostra suficiente; < 30 trades por segmento é exploratório, não prova de estabilidade.
- Sinalização do usuário: **visual sem repintar** primeiro; performance financeira depois, sem prometer lucro.

## Relatórios e critérios de evolução
Candidato só vira nova versão recomendada após passar: (a) compilação MetaEditor; (b) causalidade/prefixo e teste live-versus-reload; (c) no mínimo melhora relevante *fora da amostra* em relação ao baseline, considerando custo de oportunidade de frequência perdida.

## Situação presente
- O antigo `research/backtests/xau_20261111/results/RELATORIO.md` é simulação OHLC com **Python** e custos assumidos. Não pode ser rebatizado como teste operacional MT5.
- A estratégia de entrada que vier do indicador v2 ainda não existe; **não há PnL, winrate, PF, screenshot ou .ex5 dela a reportar**.
- Códigos v1 dos oito indicadores permanecem inalterados.
