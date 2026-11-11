# Segunda leva: triagem causal estática de sete originais

**Escopo:** inspeção estática de sete scripts exemplares. NÃO é execução TradingView nem teste de não repintura; os outros vinte scripts precisam de auditoria posterior.

| Script | request.security | lookahead_on | pivôs | barstate.isconfirmed | Principais riscos |
|---|---:|---:|---:|---:|---|
| FEELS Liquidity Magnet | 0 | 0 | 2 | 2 | Bar_index - N: o pivô pode ser desenhado no passado, embora só confirmado depois |
| FEELS Air Pocket | 0 | 0 | 0 | 1 | Zonas podem mudar ao longo do candle em formação |
| MWM Session Pulse | 0 | 0 | 0 | 0 | Confirmar que a comparação de sessão usa apenas candles completos |
| MWM LiqSweep iFVG | 1 | 0 | 2 | 0 | HTF em formação, pivôs e `offset` negativos para marcações históricas |
| TaughtToTrade Backtest Integrity Scanner | 0 | 0 | 0 | 0 | Ferramenta de auditoria, não operação; interpretação estatística ainda depende de amostra |
| Timonkru Futures Volume Delta | 1 | 0 | 0 | 1 | Feed externo, atraso e sincronização de horários/contratos; XAUUSD CFD não é GC |
| Capital41 Regime Matrix | 0 | 0 | 0 | 4 | Presença de `barstate.isconfirmed` não garante comportamento geral sem repaint |

A contagem acima corresponde às chamadas textuais encontradas nos arquivos, incluindo casos em que o uso não gera sinal; **0 ocorrências não significa garantia de segurança**. Exigir inspeção de `request.security`, shifts, pivôs, repaint em live vs reload e validação do valor conhecido na hora do sinal.

## Melhor escolha para pesquisa antes do indicador Nexus unificado

1. **Session Pulse:** contexto de volume, amplitude e eficiência no mesmo horário de sessões anteriores. Testar com volume tick de cada corretora.
2. **Liquidity Magnet e Confluence Pivot Zones:** distinguir nível confirmado, evento de toque, validade e expiração, sem retrodatação da entrada.
3. **Cost Hurdle e Backtest Integrity Scanner:** evitar vender como bom um padrão que não supera custos ou tem poucos trades.
4. **Futures Volume Delta:** só com dados de volume realmente negociado em contrato identificado; não inferir delta institucional do volume tick CFD.
5. **Capital41 Regime Matrix:** usar regime para explicar o contexto, não como 10 filtros eliminando entradas.

**Próxima etapa de desenvolvimento:** codificar módulos próprios um de cada vez, medir prefix invariance e latência, sem alterar a biblioteca original nem as 10 versões Nexus já existentes.
