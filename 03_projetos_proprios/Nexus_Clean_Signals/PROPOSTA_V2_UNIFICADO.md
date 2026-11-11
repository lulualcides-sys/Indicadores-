# Nexus Clean Signals v2 — especificação para UM indicador próprio

**Status: PESQUISADO/PROPOSTO, não implementado.** Preservar em `v1.00` o indicador que já existe. Prototipar v2 em pasta/branch nova, testar, só então disponibilizar ao usuário.

## Produto desejado
- MetaTrader 5 desktop, XAUUSD M1/M5/M30/H1.
- **Dois buffers públicos de setas** BUY(0) e SELL(1), compatíveis com o EA de teste.
- Cada seta é única, tem **bar timestamp** e `confirmed_at` do candle seguinte, e **não se move nem desaparece** em ticks normais.
- Visual CLEAN padrão: só seta discreta e **uma linha de estado** `XAUUSD | M30 | RANGE | S confirmado 2 velas atrás`; níveis/caixas ocultos.
- Opcional PLAN: apenas último ENTRY, SL, TP1/2/3; mostrar instante de disponibilidade (não retroprojetar).
- Alertas opcionais por abertura do próximo candle, únicos por sinal; sem negociação automática no indicador.

## Arquitetura separada para impedir o erro de "20 filtros"

```
OHLCV do broker (somente candles fechados)
 ├── Contexto: ER de barras anteriores, horário e níveis já confirmados
 ├── Detector R: abertura de sessão / faixa + rompimento + reteste confirmado
 ├── Detector S: EQH/EQL ou swing confirmado + sweep de wick + fechamento de volta
 ├── Detector W: VWAP com âncora de início de sessão + cruzamento/reclaim confirmado
 ├── Árbitro: 1 sinal por barra, conflito de BUY/SELL => NÃO sinalizar
 └── Buffers BUY/SELL + log causal + um único painel (sem clutter)
```

Não acoplar FVG/ADX/squeeze/volume/OB como barreiras obrigatórias. Primeiro separar cada detector em teste A/B, avaliando ganhos e perdas de frequência e expectativa líquida.

## Regras operacionais propostas (hipóteses)

| Detector | Momento em que é conhecível | Trigger experimental | Veto causal |
|---|---|---|---|
| R — breakout/retest | Janela de abertura totalmente fechada; reteste confirmado no candle seguinte | Rompe faixa, retorna próximo ao nível, volta a fechar do lado do rompimento | Espera excedida ou fechamento dentro da faixa de invalidação |
| S — liquidity sweep | Segundo pivot dos EQH/EQL **confirmado depois das velas à direita**; sweep fecha | High acima do nível + close abaixo (SELL), ou low abaixo + close acima (BUY) | Nível já rompido por fechamento; não marcar pivô no passado como sinal conhecido |
| W — session VWAP reclaim | Âncora fixa por horário antes da entrada; peso de candles fechados | Fecha atravessando o VWAP já computável e com corpo direcional | VWAP indisponível por histórico truncado, sessão parcial sem warmup |

**Importante:** nenhuma dessas 3 lógicas está comprovada lucrativa. O indicador é ferramenta de leitura, não um sinal institucional.

## Política de regime sem ambiguidade

Em vez de mascarar o intervalo ER, criar `regime = RANGE` (ER <= limiar inferior), `TREND` (ER >= limiar superior), `MIXED` (entre ambos), sempre com valores de candles anteriores. Por padrão **apenas informar** o regime; depois uma variante experimental pode usá-lo para priorizar tipos. Se houver contexto contraditório, sinal continua identificando sua **origem** R/S/W e a frequência não é escondida.

Se dois detectores sinalizam o mesmo lado na mesma vela, exibir **uma seta** e registrar causas múltiplas nos metadados. Se lados opostos, não emitir seta e registrar `CONFLITO`. Não dar peso secreto ao detector para 'forçar' acerto.

## Interface e modos

- `CLEAN` padrão = duas setas e estado compacto; sem retângulos/zonas.
- `ANALISE` opcional = um único canal/zona relevante, apenas o plano mais recente.
- `MODE=R/S/W/ALL` = comparar cada detector isolado e conjunto (não 'otimização' oculta).
- `ER` e `RVOL` continuam números explicativos, **não porcentagens de winrate**.
- `BUY/SELL` não é uma operação; o testador aplica execução na vela seguinte e custos reais da corretora.

## Critérios antes de produzir v2 como aprovada

1. Analisar o código v1; criar branch `feat/nexus-clean-v2` sem sobrescrever `v1.00`.
2. Implementar detector por detector; eventos com `created_at` e `confirmed_at`, filtro de tempo causal.
3. Testes de prefixo: execução nas primeiras N barras não muda resultados confirmados quando N aumenta.
4. Testes de reconstrução incremental vs batch, inclusive gaps, sessões e pivôs.
5. Verificação de nível MTF com último HTF fechado e abertura no broker correto.
6. Inspecionar custo computacional em barras M1 (atualização por nova vela, não recalcular tudo a cada tick).
7. **MetaEditor e MT5 Strategy Tester real**, zero erro de compilação, cada detector 4 timeframes, mesma corretora, bid/ask/custos, testes fora da amostra.
8. Medir `n`, PF, expectativa líquida R, DD, distribuição por sessão e tempo de espera; comparar v1 e cada ablação. Não selecionar só melhor período e declarar superior.
9. Se não houver evidência suficiente, deixar versão como **EXPERIMENTAL** e preservar v1.
