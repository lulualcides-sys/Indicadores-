# Auditoria estática preliminar dos 10 indicadores Pine originais

**Data:** 11/11/2026. **Objeto:** fontes MIT copiadas exatamente de [casoon/pine-scripts](../08_indicadores_originais/01_pine_wavesunchained/), commit `880c228d63f37c3af0bc524346ff453c375d7bae`.

**Método:** busca no código por `request.security`, `barmerge.lookahead_on`, `ta.pivothigh`/`ta.pivotlow`, `barstate.isconfirmed`, `offset` negativo, marcações em `bar_index - N` e estados de confirmação. Esta é **triagem estática**, não execução no TradingView, não compilação MT5 e não prova de que algum código repinta ou não repinta.

| Original importado | Indícios no código | Risco operacional a investigar | Padrão aproveitável | Prioridade |
|---|---|---|---|---|
| Regime Classifier | `request.security` em linha HTF opcional; `barstate.isconfirmed` para avisos | Valor HTF em formação pode oscilar, mesmo sem `lookahead_on`; o painel não deve ser usado como sinal | ER + FDI + CHOP + **histerese de regime**, apenas velas fechadas locais | **P1**, sem HTF provisório |
| Trading Range State Machine | `ta.pivothigh/low`, registro em `bar_index-pivotLen` | Pivô só se torna conhecido após confirmação; não atribuir sinal ao passado | Estados BUILDING/CONFIRMED/MATURE/BREAKING e limites do range | **P1**, com relógio causal |
| Market Structure Advanced | `ta.pivothigh/low`, `label.new(bar_index-pivRight,...)` | **Rótulos retroativos** podem fazer backtest visual parecer antecipado | HH/HL/LH/LL, ruptura conhecida só na vela de confirmação | **P1**, sem etiquetas retroativas na entrada |
| Structure Break Risk | `ta.pivothigh/low`, referência `bar_index-pivLen`, alguns eventos limitados a `barstate.isconfirmed` | Confirmar relógio de BOS e origem dos stops; rótulo de pivô não é entrada | Vencimento/invalidação de estrutura e stop estrutural | **P1**, precisa auditoria funcional |
| Anchored VWAP | Pivôs confirmados determinam âncora; `ta.pivothigh/low` | Âncora escolhida após saber do pivô pode reconstruir linhas no passado | **VWAP de sessão ancorada previamente**, não reancorar retrospectivamente | **P1 apenas para âncora fixa**, código de pivô P3 |
| Candle Pressure Index | Sem `request.security` e sem `ta.pivot*` detectados; `barstate.isconfirmed` nos avisos | Oscilador pode variar na vela atual; volume tick do ouro CFD depende do broker | Pressão de fechamento × corpo × volume relativo | **P1** para fator opcional, só vela fechada |
| Signal Quality Engine | Pivôs confirmados e `plotshape(offset=-pivotLen)` em marcadores de pivô | **Marcadores visualmente retroativos**; distinguir SETUP, WATCH e TRIGGER | Pipeline causal de preparação/observação/entrada | **P1** conceitual, não copiar setas de pivô |
| Compression Fractal Release | `request.security` para EMA/ATR HTF; `barstate.isconfirmed` em logging | Valores do HTF aberto podem mudar durante a vela; caixas podem ter estado evolutivo | Detecção de compressão e gatilho de liberação por fechamento | **P2** sem HTF provisório |
| Chandelier Flip Radar | `request.security(...lookahead_off)`, confirmação opcional `barstate.isconfirmed` | `lookahead_off` não congela HTF atual; trailing pode mudar ao formar candle | Trailing ATR para **saída**, separado de sinal de entrada | **P2** |
| Swing Conviction Radar | Pivôs `ta.pivothigh/low` e `pivBar=bar_index-pivLbR` | Divergência calculada depois e marcada em pivot anterior **não é sinal disponível naquele instante** | Fraqueza entre swings confirmados, apenas contexto | **P3**, vedada entrada retrodatada |

## Priorização concreta para o NOSSO indicador
**Primeira rodada de extração:** (1) Regime Classifier **sem HTF aberto**, (2) Candle Pressure **em barras fechadas**, (3) Structure Break Risk com **timestamp de pivô confirmado**, (4) Trading Range State Machine com evento temporal explícito, (5) VWAP com início de sessão previamente conhecido. Esses cinco conceitos cobrem regime, pressão, estrutura, contexto lateral e valor sem redundância tão alta quanto juntar dezenas de osciladores.

**Não portar diretamente** regras de ancoragem retroativa, pivôs desenhados com deslocamento negativo ou filtros de HTF corrente. Sinais finais BUY/SELL só em **candle fechado**; o EA/testador precisa lê-los via buffer 0/1 no próximo candle.

## O que foi comprovado e o que NÃO foi
- **Comprovado:** 10 arquivos originais Pine e biblioteca Python ta copiados com licença MIT; 25 hashes Git batem com as origens; testes de integridade e smoke test do pacote ta passaram no GitHub.
- **Não comprovado:** desempenho de mercado, ausência de repaint dos 10 scripts em tempo real, equivalência Pine→MT5, ou que qualquer um é 'o melhor' por rentabilidade.
- Próxima etapa correta: extrair módulos próprios dos P1 em branch experimental, com testes de prefixo temporal e regressão; comparar **um módulo de cada vez** antes de incluí-lo no único Nexus Clean Signals.

[Catálogo de seleção](../01_catalogos/SELECAO_ORIGINAIS_2026-11-11.csv) · [Manifesto SHA](../08_indicadores_originais/manifesto_origens.json) · [Plano de extração](../05_extracoes_experimentais/PLANO_EXTRACAO_ORIGINAIS_2026-11-11.md)
