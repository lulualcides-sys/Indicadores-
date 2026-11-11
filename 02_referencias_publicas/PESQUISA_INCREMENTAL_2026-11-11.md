# Pesquisa incremental — 11/11/2026

## Telegram: fontes públicas, sem comprar nada

| Canal | Item observado | Formato | Avaliação |
|---|---|---|---|
| [@FreeMT5Indicators](https://t.me/s/freemt5indicators) | awesome_oscillator_divergence; Stripped T3 Levels; Lot calculator | arquivos .mq5 publicamente anunciados | candidatos úteis; autoria/licença e código não auditados; canal diz não redistribuir comercialmente |
| [@indicadoresgratis](https://t.me/s/indicadoresgratis/31348) | Breakout Lines TP/SL, AIMS AO 2.1 | TXT/.mq4 | referência para alertas de rompimento e momentum; conferir script antes de usar |
| [@fxsignalspot](https://t.me/s/fxsignalspot?before=20002) | indicador ADR BuSe, iClock, insync index & arrows + alerts | .mq4 + .ex4 | comparar qualidade; evitar arquivos compilados |
| [@tradinglabzar](https://t.me/s/tradinglabzar?before=18328) | Day Type Radar | TXT | já consta em catálogo: evitar duplicação |
| [@WillyAlgoTrader](https://t.me/s/WillyAlgoTrader?after=408) | Liquidity Pools Pro | TradingView | publicidade afirma não repintura; declaração pública **não prova ausência de lookahead**. Requer revisão de código. |
| [@RocktradersPublic](https://t.me/s/RocktradersPublic) | vários EAs EX5, arquivos rar, arquivos com credenciais expostas em publicações | compilados / arquivos | prioridade BAIXA. **Não baixar/executar nem utilizar credenciais publicadas**. |

Não foi verificado acesso às mensagens privadas nem autenticidade dos binários.

## Novos indicadores gratuitos com código-fonte MQL5

| Nome | Fonte primária | Função | Prioridade |
|---|---|---|---|
| Liquidity Sweep Equal Highs Lows | https://www.mql5.com/en/code/79401 | topos/fundos iguais confirmados, sweep versus rompimento | Alta |
| Fair Value Gap Zones Tracker | https://www.mql5.com/en/code/79400 | FVG formado por três candles fechados, mitigação | Alta |
| Order Blocks Zones SMC | https://www.mql5.com/en/code/79271 | zonas após rompimento de swing confirmado | Alta |
| Key Levels with Touch Counter | https://www.mql5.com/en/code/79039 | níveis D/W/M e contagem de testes/sweeps | Alta |
| Session High Low Alerts | https://www.mql5.com/en/code/79036 | sessões e rompimentos após fechamento | Média |
| ORB Box + VWAP Stats | https://www.mql5.com/en/code/79038 | ORB + VWAP + estatísticas | Média |
| Opening Range Breakout Dashboard | https://www.mql5.com/en/code/79125 | abertura + estatísticas históricas | Média |

Esses produtos expõem código-fonte na plataforma MQL5; a liberdade de **modificar ou redistribuir** depende das condições reais de cada fonte. **Não copiamos códigos originais neste commit.**

## Resultado da seleção
1. [Nexus Liquidity Sweep Radar](../03_projetos_proprios/Nexus_Liquidity_Sweep/README.md) — primeiro indicador novo (extremos de janela móvel e rejeição confirmada).
2. H1 Vector Factor 1.20 continua preservado sem modificações.
3. Evolução futura: confirmação estrutural opcional por pivôs, FVG com desenho causal, custos e alertas MTF; cada bloco deve ter comparação isolada para não bloquear todas as entradas.

**Sem alegações de ganho, acerto, backtest real ou compilação MT5.**
