# Dossiê técnico: convergir para UM indicador autoral limpo (11/11/2026)

**Objetivo do usuário:** pesquisa ampla e sistemática, do Telegram/GitHub/TradingView/MQL5 para chegar a um **único indicador MT5 próprio**, utilizável em XAUUSD M1/M5/M30/H1, com **setas BUY/SELL confirmadas sem repintar**, explicação do motivo do sinal, e mínimo de poluição no gráfico. **Não é autorização para criar dezenas de indicadores isolados.**

**Escopo desta entrega:** pesquisa e decisão de engenharia. Não altera os oito indicadores existentes; não afirma backtest novo nem compilação MT5. Referências são conceitos, **não fontes copiadas**. Desempenho e licenças de reutilização precisam de auditoria caso código externo venha a ser incorporado.

## Matriz de candidatos pesquisados

| Conceito / fonte original | Dados/funcionalidade verificáveis | O que extrair para o NOSSO | Grau | Risco de erro/repaint | Decisão |
|---|---|---|---|---|---|
| [Trend Regime Inspector](https://www.mql5.com/en/code/75868) — MT5 MQ5 | Kaufman Efficiency Ratio, ADX e direção por média | Regime TREND/RANGE/MISTO, separado do gatilho | P1 | ER sozinho não é previsão; ADX tem atraso | Implementação própria mínima |
| [Breakout Distance](https://www.mql5.com/en/code/75245) — MT5 MQ5 | Canal Donchian e distância em unidades ATR | Distância normalizada a nível e invalidação do setup | P1 | Faixa não pode incluir máxima futura | Contexto de entrada |
| [Opening Range Breakout Dashboard](https://www.mql5.com/en/code/79125) — MT5 MQ5 | Janela horária de abertura, rompimento por fechamento, estatísticas | Abertura por sessão configurável, reteste opcional | P1 | Fuso do servidor, DST, janelas incompletas | Setup R (retorno ao canal) |
| [Liquidity Sweep Equal Highs Lows](https://www.mql5.com/en/code/79401) — MT5 MQ5 | Extremos iguais confirmados e diferenciação sweep/rompimento | Níveis EQH/EQL e sweep por fechamento de volta | P1 | Swing só é conhecido após candles à direita | Setup S, com relógio da confirmação |
| [Market Structure BOS/CHoCH](https://www.mql5.com/en/code/78551) — MT5 MQ5 | HH/HL/LH/LL, BOS/CHoCH, swings atrasados explicitamente | Confirmação estrutural após sweep, sem seta retroativa | P1 | Pivô histórico não era conhecido em seu topo | Contexto, NÃO 2º filtro obrigatório |
| [Key Levels with Touch Counter](https://www.mql5.com/en/code/79039) — MT5 MQ5 | Máximas/mínimas prévias D/W/M, tolerância ATR e contagem de toques | Níveis do dia/semana anteriores, sem 15 linhas no gráfico | P1 | Níveis do dia atual desenvolvem | Ranking de local do setup, oculto por padrão |
| [Session High Low Alerts](https://www.mql5.com/en/code/79036) — MT5 MQ5 | Asia/Londres/NY e alertas após fechamento de sessão | Datas e ancoragem horária, *somente* sessão fechada | P1 | Nível de sessão incompleta evolui | Definir sessão por horário do corretor |
| [POI Liquidity Detector](https://github.com/kayasolomon/poi-liquidity-detector) — GitHub | Ciclo fresh/mitigated/invalidated, atIndex de disponibilidade, sweep→CHoCH | Modelo de evento imutável + testes de prefixo | P1 | Licença e engine precisam de verificação antes de copiar | Adotar **método**, não código |
| [FVG Zones Tracker](https://www.mql5.com/en/code/79400) — MT5 MQ5 | Gap de três candles com terceira vela confirmada, mitigação | FVG como contexto/estrutura, não sete caixas na tela | P2 | Caixas podem encolher depois de toque, não retroprojetar setup | Primeiro medir impacto isolado |
| [Simple Anchored VWAP](https://www.mql5.com/en/code/78247) — MT5 MQ5 | VWAP a partir de âncora selecionada com bandas | Modo W: recuperação do VWAP de sessão/evento | P2 | Seleção posterior da âncora vaza futuro | Âncoras determinísticas e previamente conhecidas |
| [Anchored VWAP MQL5 Article](https://www.mql5.com/en/articles/22963) — artigo | Buffers, timestamp e ancoragem fixa/sessão | Arquitetura de atualização causal | P2 | Volumes XAUUSD CFD dependem do broker | Usar no contexto, não contar como fluxo institucional |
| [Bollinger Squeeze](https://www.mql5.com/en/code/22615) — MT5 MQ5 | Comprime BB dentro Keltner | Aviso VOLATILIDADE, sem virar sinal sozinho | P2 | Squeeze pode durar muitas velas | Contexto desativado por padrão |
| [TTMS](https://www.mql5.com/en/code/20273) — MT5 MQ5 | BB/Keltner para compressão | Corroboração do conceito | P3 | Muito redundante com squeeze anterior | Não empilhar |
| [TradingView: repaint e MTF](https://www.tradingview.com/pine-script-docs/concepts/other-timeframes-and-data/) — documentação oficial | HTF em formação muda valores; offset + 1 e lookahead_on na expressão HTF confirmada | Regra **obrigatória** para portar Pine/MTF | Obrigatório | Usar lookahead sem offset causa *future leak* | Proibir leaks |
| [MQL5 CopyBuffer](https://www.mql5.com/en/docs/series/copybuffer) — documentação oficial | Shift 0 = barra corrente, shift 1 = candle anterior | Definir contrato de buffers públicos BUY=0 SELL=1, shift 1 | Obrigatório | Leitura de barra zero muda em tempo real | Teste EA lê shift 1 |
| [MQL5 Strategy Tester](https://www.mql5.com/en/docs/runtime/testing) — documentação oficial | Indicadores no teste podem recalcular sob demanda/visual | Repetir teste incremental e reload no próprio MT5 | Obrigatório | Passar Python unit test não prova terminal | Validação final |
| [Tick Volume em MT5](https://www.mql5.com/en/blogs/post/779009) — texto explicativo | Volume tick ≠ contratos negociados | RVOL por sessão/broker apenas como hipótese | Cautela | Volume de XAUUSD spot/CFD não é livro global | Não exibir rótulo enganoso 'Smart Money' |

**Origem**: páginas públicas acessíveis em 11/11/2026, inclusive novas publicações de novembro. MQ5 disponível na CodeBase não significa que tenhamos inspecionado seus arquivos locais ou que a licença para republicar seja ilimitada.

## Diagnóstico do NOSSO código v1.00, sem inventar causas de perdas

Arquivo: `03_projetos_proprios/Nexus_Clean_Signals/v1.00/Nexus_Clean_Signals_NR.mq5`

1. `InpRangingER = 0.25`, `InpTrendingER = 0.43`; no AUTO usa `allowBreak = er>=0.25` e `allowSweep = er<=0.43`. **Entre 0,25 e 0,43 ambos gatilhos são admitidos.** O README já documenta isso, mas o painel mostra somente AUTO e não distingue regime misto da classe de setup. A ordem de verificação do rompimento antecede sweep. Corrigir a clareza/semântica na v2; não afirmar que isso gera prejuízo sem experimento.
2. *Score* de preço/corpo/ER foi definido heurísticamente e **não é calibração probabilística**. Nunca exibir 'chance de ganhar X%'.
3. Implementação de sweep por extremo dos últimos 18 candles não é o mesmo que liquidez de **dois swings equivalentes confirmados**. Separar as hipóteses no estudo, não trocar silenciosamente.
4. Não usar dados de outro timeframe sem o **último candle HTF confirmado**; ao portar Pine, respeitar offset histórico.
5. O preço de sinal é referência de fechamento, não fill executável. Spread/bid/ask/slippage precisam entrar na validação do EA.
6. Os proxies históricos anteriores (179.662 M1, março–setembro/2026) foram **Python**, NÃO MQL5 no Strategy Tester. Houveram resultados negativos significativos, e dois positivos modestos (VWAP M30 e FVG H1). **Não transformar esses números em filtro/ótimo; nem usá-los como prova de que indicador ou usuário está errado.** Ver `research/backtests/xau_20261111/results/RELATORIO.md`.

## Decisão desta rodada

**Não publicar mais 8 indicadores isolados.** Evoluir **um só Nexus Clean Signals v2**, preservando v1, com 3 gatilhos identificáveis e *contexto* separado:

- **R = breakout + reteste** de intervalo já fechado/sessão; aguarda confirmação real do retorno e invalida setup vencido.
- **S = sweep de liquidez confirmada** em nível válido + retorno para dentro; CHoCH só como hipótese opcional, testada separadamente.
- **W = VWAP reclaim** com âncora de sessão definida antes do sinal; volume tick com alerta de limitações.
- **Regime** = ER (obrigatório como contexto apenas; ADX opcional), sem bloquear sinais por padrão até a ablação.
- **FVG, squeeze, OB e volume delta** não entram como quatro condições obrigatórias nem como dezenas de objetos; registrar separadamente para comparação futura.

### Candidatos explicitamente descartados da primeira v2
ZigZag que remarca último extremo, HTF em formação, regressão centralizada com futuro, sinais em candle atual, bundles EX5 sem fonte e filtros em cascata para forçar resultado positivo. **Nenhum destes pode ser chamado de sem repintar.**

[Especificação da versão 2](../03_projetos_proprios/Nexus_Clean_Signals/PROPOSTA_V2_UNIFICADO.md) · [protocolo de comparação](../06_resultados/PROTOCOLO_AVALIACAO_CLEAN_V2.md)
