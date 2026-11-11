# Auditoria estática — Monster Arrows v2.0 SMC (Pine v5)

**Escopo:** leitura integral de 424 linhas do arquivo entregue. Sem compilação no TradingView, sem gráfico real e sem backtest.

## Fórmula efetiva de entrada

- BUY = pivot low válido AND nenhum BUY nos últimos 200 candles AND HTF de compra AND 'Hunt' de compra AND FVG bullish encontrado AND filtro Fibonacci (condicional).
- SELL = pivot high válido AND nenhum SELL nos últimos 200 candles AND HTF de venda AND 'Hunt' de venda AND FVG bearish encontrado AND filtro Fibonacci (condicional).
- `ZigZagDepth = 30`; `ConfirmationDelay = 2`; `FibLevel = 0.618`; HTF exige ambas as confirmações, por padrão.
- No M1, HTFs = M5+M15. No M5, M15+M30. No M15, M30+H1. No M30, H1+H4.
- O painel de SMA200 M1..D1 é **informativo apenas**: sua pontuação não está na condição `buySignal`/`sellSignal`.

## Pontos de risco por prioridade

### P0 — correção antes de backtest

1. **Desenho retroativo das setas:** pivô só é detectado `ConfirmationDelay` candles mais tarde, mas `label.new(pivotBar, ...)` grava a seta na barra do próprio pivô (linhas 159–166 e 236–250). Não registrar ordem em `pivotBar`. O instante válido é `bar_index` de confirmação, preferivelmente após fechamento.
2. **Repaint em HTF:** `request.security(...f_htf_zigzag_dir(), ...lookahead_off)` pode ler HTF em formação (linhas 196–197). Para HTF estritamente superior: calcular expressão com `[1]` e `barmerge.lookahead_on`; validar que é realmente HTF. Ver documentação oficial TradingView: https://www.tradingview.com/pine-script-docs/concepts/other-timeframes-and-data/.
3. **Entrada retroativa em alvos:** `entry = pivotLowPrice` ou `pivotHighPrice` (linhas 291/322). Ao reconhecer o sinal, o preço de pivô histórico pode não estar disponível. TP1/2/3 são linhas ilustrativas, não trades executados e não têm stop.
4. **Somente indicador:** `indicator(...)`, `alertcondition(...)`; nenhum `strategy.entry/exit`, nenhuma regra completa de stop, volume, custo ou backtest (linhas 1–2, 421–424).

### P1 — qualidade de seleção

5. **Sweep = rompimento simples:** `pivotLowPrice < lastBuySweepLow` ou `pivotHighPrice > lastSellSweepHigh` (linhas 205–206). Não obriga fechamento de retorno para dentro do nível, nem rejeição confirmada, nem buffer de spread.
6. **FVG genérico e distante:** funções detectam qualquer gap de 3 candles numa janela de `ZigZagDepth` (linhas 115–145 e 208–212). Sem distância máxima em relação ao sinal, tamanho mínimo em ATR, invalidade ou mitigação; `EnableFVG` não valida 'displacement' apesar do nome da opção.
7. **ZigZag não é algoritmo completo:** usa `ta.pivothigh/low` e distância mínima entre pivôs, sem alternância de direção, sem implementar o parâmetro Backstep (linhas 157–171 e 343–362). Consecutivos da mesma classe podem ocorrer, afetando zz1/zz2 e alvos.
8. **Fib opcional sob condição:** `buyFib`/`sellFib` começa verdadeiro e pode permanecer verdadeiro se a relação zz1/zz2 não atender ao ramo (linhas 217–231). Logo, não é uma exigência universal de retração de 61,8%.
9. **HTF pode bloquear demais:** duas direções de último pivô HTF (não tendência de média móvel); combinação padrão exige ambos, mesmo em tendências persistentes. Confirmar taxa de rejeição com dados reais; não presumir melhora.
10. **Panel de SMA200 não filtra entradas:** `overall` apenas exibido na tabela, não usado na expressão dos sinais (linhas 365–419).

### P2 — manutenção

11. **Parâmetros sem efeito constatável:** `Arrow_Size`, `ZigZagBackstep`, `BarsToAnalyze` são declarados, mas não usados após os inputs (linhas 24, 26 e 46).
12. **Antirrepique fixo de 200 barras:** mesma distância em M1 (3h20) e M30 (100h), com efeitos distintos por sessão; não é uma condição econômica fundamentada (linhas 184–188).
13. **ATR diário possivelmente provisório:** cálculo diário intraday atual pode variar até fechar o candle diário (linhas 150–154).
14. **Tela vs execução:** dashboard inclui consultas a timeframes menores que o gráfico; `request.security()` amostra só um intrabar e não fornece resumo completo de todos os movimentos do timeframe menor.

## Módulos para extração (não são afirmações de edge)

| Módulo | Prioridade | Decisão |
|---|---|---|
| Pivôs confirmados + estrutura | Alta | Extrair com índice de confirmação explícito |
| Liquidity Sweep com fechamento de retorno | Alta | Extrair com semântica corrigida; independente da lógica original |
| FVG 3 candles | Alta | Extrair; adicionar parâmetros de idade, tamanho e mitigação |
| Confirmação HTF | Alta | Reimplementar temporalmente sem repaint |
| ATR Wilder | Média | Extrair cálculo, definir D1 com candles confirmados |
| Fibonacci 61,8% | Média | Contexto opcional, sem forçar entradas |
| SMA200 MTF | Baixa | Somente informação; testar como filtro separado (ablação) |
| Setas e dashboard | Baixa | Visual, não fator de edge |
| TP 50/100/161,8% | Baixa | Não usar como alvos de estratégia até definir stop/execução |

## Próximas validações

- Confirmar sintaxe e compilação no TradingView; o ambiente local não compila Pine.
- Validar a biblioteca Python contra OHLC reais e equivalência semântica à plataforma desejada.
- Executar backtests realistas com dados históricos confiáveis de XAUUSD nos quatro tempos, incluindo spread variável e custos.
- Fazer ablação, walk-forward, teste fora da amostra e Monte Carlo de ordem de operações.
- Classificar por PF, Sharpe, MDD, trades, estabilidade e P&L líquido, com intervalos de confiança.