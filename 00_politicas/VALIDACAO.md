# Critérios de validação — auditoria antes de uso real

**Não confundir:** revisão estática ≠ compilação MT5 ≠ teste unitário ≠ backtest ≠ robustez fora da amostra ≠ resultado ao vivo.

1. Verificar origem e licença do arquivo. Não executar compilados desconhecidos.
2. Revisão estática: fluxo de dados, gestão de arrays, uso de índices, repaint, condicionamento a dados futuros, conflitos MQL/Pine.
3. Testes focados de indicadores e invariância temporal. Preservar logs, parâmetros, commit e dataset.
4. Compilar no MetaEditor com log de avisos/erros e identificar versão real do MT5.
5. Executar em conta demo no mesmo broker/datafeed do alvo; medir sinais históricos e em tempo real.
6. Backtest determinístico com ticks ou candles coerentes, spread variável, comissão, slippage e horário do broker; registrar premissas.
7. Separar treino, validação e teste fora da amostra; walk-forward; medir sensibilidade a parâmetros e custos.
8. Relatar quantidade de sinais e trades, expectativa líquida, PF, payoff, drawdown, distribuições, intervalo de confiança e estabilidade por janela.
9. Não tratar dados simulados, rótulos "W/L" em Pine, sinais marcados no passado ou operações sem feed como lucro real.
10. Aprovação requer resultados reproduzíveis e revisão independente; após aprovação, alterações passam por testes de regressão.

### Status
- Indicadores importados: pesquisa/auditoria, não aprovados automaticamente.
- H1 Vector Factor v1.20: 15 testes locais de lógica/estática passaram; **backtest real não realizado**.
- Indicador Bull H1M1: sem acesso à fórmula interna, logo equivalência exata **não demonstrada**.
