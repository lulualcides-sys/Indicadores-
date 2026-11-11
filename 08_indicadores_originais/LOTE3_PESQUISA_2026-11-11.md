# Lote 3 — arquivos originais, pesquisa avançada para Nexus

**Estado:** 21 códigos originais, incluindo **6 fontes MQL5**, **3 indicadores Pine de fluxo de ordens** e **12 métodos matemáticos Pine**, acompanhados de 3 licenças e 6 arquivos de documentação. Total **30 arquivos**. Todos conferidos por SHA Git contra commits imutáveis dos autores.

## Fontes
| Repositório original | Códigos | Licença | Commit fixado |
|---|---:|---|---|
| [mironkonkov30-design/mql5-indicators](https://github.com/mironkonkov30-design/mql5-indicators/tree/c9e7a385ffd6390fffcd0994007879a0382441dc) | 6 | MIT | `c9e7a385ffd6390fffcd0994007879a0382441dc` |
| [Robwhitlow3/tradingview-orderflow-indicators](https://github.com/Robwhitlow3/tradingview-orderflow-indicators/tree/8c71cb328e56adaaadeba0086f22df1a467d1dda) | 3 | MIT | `8c71cb328e56adaaadeba0086f22df1a467d1dda` |
| [mihakralj/pinescript](https://github.com/mihakralj/pinescript/tree/c4e91b962be09733d8fc76caa5191e9e586c5cee) | 12 | MIT | `c4e91b962be09733d8fc76caa5191e9e586c5cee` |

Arquivos guardados sob `08_indicadores_originais/09_miron_mql5`, `10_robwhitlow_orderflow` e `11_mihakralj_matematica`. Nenhum dos dez códigos Nexus ou testes anteriores foi sobrescrito.

## Padrões com maior prioridade técnica (NÃO ranking de lucratividade)
| Arquivo | O que estudar para o nosso indicador | Risco que precisamos controlar |
|---|---|---|
| [SessionHighlighter.mq5](08_indicadores_originais/09_miron_mql5/SessionHighlighter.mq5) | Sessões e extremos | Horário do servidor e DST de Londres/NY; sessões incompletas |
| [SupplyDemandZones.mq5](08_indicadores_originais/09_miron_mql5/SupplyDemandZones.mq5) | Zonas e swings | Pivôs requerem barras posteriores; retrodatar a zona não é sinal |
| [CVD.pine](08_indicadores_originais/10_robwhitlow_orderflow/CVD/CVD.pine) | Delta acumulado por sessão | Delta de corretora/TradingView pode ser proxy, divergência com pivôs atrasados |
| [DeltaPulse.pine](08_indicadores_originais/10_robwhitlow_orderflow/DeltaPulse/DeltaPulse.pine) | Pressão/delta | Proxy LTF não é fita bid/ask verdadeira; absorção pode ser estimada |
| [LegDeltaProfile.pine](08_indicadores_originais/10_robwhitlow_orderflow/LegDeltaProfile/LegDeltaProfile.pine) | Perfil de pressão por perna | Perna em andamento muda; POC não é volume negociado confirmado sem feed |
| [vwapbands.pine](08_indicadores_originais/11_mihakralj_matematica/indicators/channels/vwapbands.pine) | VWAP e volatilidade | Tick volume não é book de contratos reais; âncora deve ser fixa |
| [chop.pine](08_indicadores_originais/11_mihakralj_matematica/indicators/dynamics/chop.pine) | Regime lateral | Já há Efficiency Ratio; medir melhoria marginal sem filtros duplicados |
| [nw.pine](08_indicadores_originais/11_mihakralj_matematica/indicators/filters/nw.pine) | Kernel unilateral | Comparar matematicamente ao Nexus Causal Kernel; não duplicar |
| [entropy.pine](08_indicadores_originais/11_mihakralj_matematica/indicators/statistics/entropy.pine) | Complexidade do mercado | Valor histórico descritivo, não probabilidade de ganho |
| [hurst.pine](08_indicadores_originais/11_mihakralj_matematica/indicators/statistics/hurst.pine) | Persistência vs reversão | Amostra e viés; estimativa instável em curto prazo |
| [wins.pine](08_indicadores_originais/11_mihakralj_matematica/indicators/statistics/wins.pine) | Robustez a outliers | Winsorização de dados passados sem olhar distribuições futuras |

[Catálogo completo das 21 fontes](../01_catalogos/LOTE3_21_FONTES_2026-11-11.csv) · [Manifesto de hashes e procedência](manifesto_lote3.json).

## Diferenças de plataforma
- Os arquivos `.mq5` são código-fonte para **MetaTrader 5**. Alguns painéis usam `indicator_buffers 0` e não produzem BUY/SELL diretamente; não colocá-los no EA que espera buffers 0/1 sem adaptador e auditoria.
- Os `.pine` são fontes de **TradingView**; não funcionam diretamente no MT5.
- **DeltaPulse/CVD/LegDeltaProfile** usam aproximações de agressão por preço/volume, salvo quando uma plataforma tiver dados reais apropriados. Evitar chamar proxy OHLC de agressão verdadeira ou volume consolidado do mercado.
- MT5 de corretora XAUUSD CFD e GC futuros COMEX possuem fontes, contratos e horários distintos.

## Requisitos antes de usar os padrões no Nexus
1. Inspecionar se o indicador depende de pivô conhecido apenas depois de candles à direita, dados MTF ainda abertos, desenho com deslocamento negativo ou regressão centrada.
2. Guardar `confirmed_at`, sem entrada retroativa; em MQL5, buffers de sinais são lidos apenas depois do fechamento do candle.
3. Extrair somente componente autoral necessário e comparar com o que já temos: kernel, EMA, VWAP, regime e estrutura. Não acumular indicadores equivalentes.
4. Teste Pine/MetaEditor, comparação de prefixos/incremental, ticks reais de XAUUSD e avaliação financeira com custos do broker e fora da amostra.

**Verificado:** hashes, proveniência, licenças. **Não verificado:** compilação MQL5, comportamento ao vivo, não-repaint definitivo, ganhos ou qualquer backtest financeiro desta leva. Nenhum anexo novo foi baixado de grupo Telegram nesta importação; as fontes são repositórios dos autores.
