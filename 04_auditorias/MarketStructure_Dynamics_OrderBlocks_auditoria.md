# Auditoria — Market Structure Dynamics & Order Blocks (Pine v6)

**Origem:** `Indicator_Market_Structure_Dynamics_&_Order_Blocks_for_TradingView.txt` (354 linhas, 18.367 bytes). **Data da triagem:** 2026-11-10.
**Classificação:** recursos úteis para pesquisa; **sem backtest**; sem lucratividade demonstrada; não integrar automaticamente a robôs.

## 1. Funcionalidades verificadas no código original

| Função | Como opera | Linhas Pine | Consideração |
|---|---|---|---|
| Pivôs | `ta.pivothigh/ta.pivotlow` com 7 barras à esquerda e 7 à direita (padrão) | 170–185 | Confirma com atraso de 7 candles; não assumir detecção instantânea no pivô |
| BOS bullish/bearish | Fechamento cruza pivô, e Z-score de variação do close supera limiar ±0,5 | 163–168; 194–206 | Usa zscore 50 candles e desvio padrão sem proteção para zero |
| Order Block | Busca em até 10 candles anteriores a última vela contrária à direção do BOS; zona high/low completa | 208–218 | Sem candle contrário, `candleOffset=0` usa equivocadamente candle do rompimento |
| Pontuação heurística | `min(100, abs(Z)*20 + percentrank(volume,100)*0.5)` | 220–222 | O valor não é probabilidade de vitória nem de toque. `>80` só é uma classificação ad hoc |
| Overlap | Rejeita se topo ou fundo da nova zona cai dentro da zona existente | 231–238 | Falha quando nova zona engloba inteiramente a existente. Ignora a direção |
| Mitigação | Bull: mínima abaixo do fundo da zona; Bear: máxima acima do topo | 264–320 | O código chama isto “mitigation”, mas é ultrapassagem completa. Não mede toque ou reteste separadamente |
| Histórico | Extende zonas e cria caixas/linhas/rótulos; limita por quantidade | 224–249; 264–320 | Pode apagar zonas ativas mais antigas; a contagem não preserva sempre histórico completo |
| Alertas | Aciona alerta a cada evento BOS | 256–262 | Sem `barstate.isconfirmed`; candle corrente pode gerar sinal temporário antes de fechar |
| Faixas semanais | High/low da **semana anterior**, via `request.security("W", high[1]/low[1], lookahead_on)` | 139–161 | Referência semanal confirmada, não confundir com lookahead espúrio |
| Sessões | Desenha amplitude diária de Londres/Nova York/Tóquio/Sydney | 51–67; 112–134; 187–192 | Horário da sessão é interpretado na zona do símbolo quando não especificada; todos os toggles de sessão vêm desativados |
| Painel | % mitigados dividido por nº de BOS e nº de blocos “high probability” | 264–269; 325–346 | Denominador contabiliza rompimentos mesmo com zona rejeitada; não é taxa de acerto nem taxa real de mitigação entre zonas criadas |

## 2. Erros e riscos identificados

**Críticos para uso em robô:**
1. **Pseudoprobabilidade**: rótulos de porcentagem e “high probability” não foram calibrados a resultados observados. **Não usar como chance de acerto, EV ou parâmetro de risco.**
2. **BOS em candle ainda aberto**: no TradingView a condição pode oscilar intrabar; colocar a validação após o fechamento antes de gerar ordens. Configuração de alertas também deve ser em fechamento.
3. **Fallback para barra atual**: se não houver candle contrário nos 10 anteriores, a origem da zona passa a ser o candle do rompimento, sem indicação de erro.
4. **Overlap parcial**: o teste ignora englobamento integral; intervalos devem ser testados com `max(lower_a,lower_b) <= min(upper_a,upper_b)`.
5. **Mitigation vs. invalidate**: o original só finaliza zonas quando o preço ultrapassa o lado distante. Touch/reteste e invalidação precisam ser eventos distintos.

**Limitações adicionais:** ausência de estratégia (stop, alvo, posição, execução e custos); Z-score indefinido com desvio padrão zero; volume pode ser inadequado/inexistente ou não comparável em certos feeds XAUUSD; limite de desenhos gráficos; classificação de BOS não separa mudança de caráter (CHoCH) de continuação; pivôs com atraso; em sobreposição pode rejeitar zonas de sentidos opostos; `totalCreatedCount` pode divergir dos blocos efetivamente criados.

## 3. Extrações implementadas, NÃO acopladas aos robôs

Caminho: `03_extracoes_promissoras/MarketStructureOB/structure_features.py`.

- BOS confirmado no close com filtro de Z-score; pivô só disponível após `lookback` barras à direita.
- Candidate zone pelo candle anterior oposto; **não** cria zona artificial na ausência dele.
- Detector correto de englobamento parcial ou total, independente da biblioteca de desenhos.
- Score matemático extraído, porém chamado `quality_heuristic`, sem alegar probabilidade.
- Eventos distintos de primeiro toque e invalidação por fechamento além da borda distante.
- Tolerância a desvio padrão zero / volume ausente; funções puras sem acesso ao futuro, API externa ou conta.

### Divergências conscientes em relação ao Pine

- Pivôs empatados são descartados para evitar ambiguidade; Pine pode tratar empates de modo diferente.
- Touch ocorre na primeira interseção e invalidação por *fechamento* além do extremo oposto. Original só chama mitigado quando **pavio** ultrapassa o extremo.
- Blocos criados não são invalidados na própria barra; original pode avaliá-los no mesmo candle de criação.
- Missing-volume retorna score nulo; não tenta imputar volume.
- Não reproduz linhas/rótulos/tabelas, janelas de negociação nem high/low semanal: são referências visuais ou componentes genéricos para acoplar somente após estudo.

## 4. Validação efetuada

`python -m unittest -v` em `MarketStructureOB`: **10 testes unitários aprovados** em 2026-11-10. Cobertura: pivô só após confirmação, empate, intervalo englobante, ausência de vela contrária, matemática de janela, prefixo sem dados futuros, rompimento sintético, volatilidade zero, OHLC inválido, estabilidade dos eventos com histórico estendido.

**Não executado:** compilação Pine no TradingView, teste de equivalência candle-a-candle, dados reais XAUUSD, tick/slippage/spread, M1/M5/M15/M30, walk-forward e operações. Classificação permanece **hipótese/extração testada localmente, não validada em backtest**.

## 5. Próximo protocolo de pesquisa (sem modificar robôs)

1. Validar datas e feeds de XAUUSD M1/M5/M15/M30; construir série OHLCV com spread/horários reais.
2. Comparar BOS/OBs com saída Pine em candles fechados e registrar divergências (em especial empate e volume).
3. Testar primeiro toque vs. invalidação, reteste pós-BOS, confirmação M15/M30 e custo de execução; não usar percentual heurístico como probabilidade.
4. Comparar fora da amostra e walk-forward com PF, expectativa líquida, MDD, quantidade de trades e sensibilidade a custos, sem otimização oportunista em testes.
5. Só então avaliar uso como filtro/entrada em branch experimental, sem alterar robôs atuais ou operações reais.

**Integridade original:** SHA-256 documentado no manifesto do componente; código Pine guardado sem modificações e com aviso MPL-2.0 preservado.