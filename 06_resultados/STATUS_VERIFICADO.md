# Status verificado e pendências (11/11/2026)

| Trabalho | Verificação | Pendência |
|---|---|---|
| Nexus Session VWAP Reclaim NR v1.00 | Código próprio e testes sintéticos/estáticos adicionados; validação CI em branch | MetaEditor, ticks reais, comparação prefixos incremental e backtest líquido |
| Nexus Structure Break NR v1.00 | Código próprio e testes de pivô causal adicionados; validação CI em branch | Verificar atrasos de confirmação no MT5, custos e backtest |
| Nexus Clean Signals NR v1.00 | Implementação própria com AUTO/BREAKOUT/SWEEP, pesquisa e teste causal Python; CI a confirmar na PR | Compilação MetaEditor, execução demo e backtest real por modo, custos e fora da amostra |
| H1 Vector Factor v1.20 | Código-fonte presente; suíte original Python executada localmente nesta migração: **15/15 aprovados** | MetaEditor, instalação, observação MT5 com ticks, backtest real |
| H1 Vector Factor v1.10 | Fonte preservada como versão antiga | Não presumir sem repaint nem resultado financeiro |
| Market Structure/OB | Código Python e testes próprios arquivados; auditoria anterior registrou 10 testes unitários | Backtest líquido e equivalência ao Pine original não demonstrados |
| Monster Arrows SMC | Núcleo próprio Python e testes arquivados | Sem aprovação financeira demonstrada |
| Auto Range Detector | Extração Python e testes arquivados | Falta máquina de estados completa e backtest real |
| DTC, QKE, Wyckoff, BC Zones, Trend Wave e Drawing Toolbox | Auditorias catalogadas | Alguns arquivos são compilados: lógica/repaint desconhecidos |
| 20 indicadores Telegram + 2 bases MQL5 | Links e descrições catalogados | Inspecionar licenças, hashes e códigos reais antes de integrar |
| Robôs IndicatorFusionGold V1–V8 | Estudos mantidos na biblioteca original, com documentação separada | Nunca transferir automaticamente estratégias para produção |

**Não registrar win rate, PF, lucro ou número de operações sem logs e dados auditáveis.**

## Protocolo de novos resultados
`data`, `commit`, `ativo`, `broker/fuso`, `timeframe`, `dataset`, `período`, `n_sinais`, `n_operacoes`, `custos`, `PnL`, `PF`, `MDD`, `OOS`, `estado_repaint`, `logs`.

Pasta `04_validados_em_backtest` da biblioteca original estava vazia na inspeção, portanto nenhum indicador importado foi declarado aprovado.
