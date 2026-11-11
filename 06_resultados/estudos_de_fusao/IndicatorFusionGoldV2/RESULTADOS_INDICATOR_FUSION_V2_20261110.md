# GOLD V2 — backtest pareado (10/11/2026)

**Arquivo de evidência verificado:** https://github.com/lulualcides-sys/nexus-quant-paper/blob/research/indicator-fusion-gold-20261110/research/results/indicator_fusion_v2_2026-11-10_summary.md

**Execução:** https://github.com/lulualcides-sys/nexus-quant-paper/actions/runs/42876232144 — sucesso, 21 testes unitários aprovados. Artefato do GitHub `indicator-fusion-v2-paper`, ID `13792660912`.

O teste usa GC=F do Yahoo, não XAUUSD bid/ask de corretora. Todas as operações são virtuais, custos 14/28 bps por transação completa; período M1 de aproximadamente cinco dias, M5/M15/M30 ~um mês. 3 janelas cronológicas, reiniciando capital virtual por janela. Histórico já examinado, não é holdout independente.

| Melhorias com resultado líquido nominal positivo | Negociações | 14 bps (USD) | 28 bps (USD) |
|---|---:|---:|---:|
| CHANNEL55_IMPULSE M5 | 15 | +26,54 | -78,37 |
| CHANNEL55_RETEST M5 | 12 | +13,29 | -70,76 |
| RANGE_LEVEL_RETEST M5 | 7 | +48,26 | -0,88 |
| CHANNEL55_IMPULSE M30 | 11 | +12,88 | -63,70 |

**0 robôs aprovados para capital real.** Nenhum candidato atingiu os critérios pré-definidos de pelo menos 30 operações, resultado positivo nos três segmentos e resistência a custos dobrados. Também não se pode somar os resultados como carteira porque as regras se sobrepõem.

**O que mudou:** cinco novos sinais de pesquisa (Channel55 controle, Channel55 impulso, Channel55 reteste, BOS reteste, Range reteste), preservando as quatro versões originais; sem ordens ou mudança nos robôs já existentes. Próximo passo rigoroso é medir custos bid/ask reais e avaliar dados futuros novos sem ajustes oportunistas.