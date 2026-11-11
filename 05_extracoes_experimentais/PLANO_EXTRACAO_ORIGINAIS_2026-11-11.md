# Extração de padrões dos originais para UM Nexus Clean Signals

Originais importados em [08_indicadores_originais](../08_indicadores_originais/README.md). **Não copiar nomes, lógica proprietária nem conclusões financeiras sem licença/testes.** MIT permite reutilização com atribuição e licença preservadas.

| Etapa | Candidato original | Conceito que pode melhorar o NOSSO | Validação necessária |
|---|---|---|---|
| Contexto | Regime Classifier + Trading Range State Machine | regime com histerese (tendência/lateral/caos) | dados somente fechados; ganho de precisão sem bloquear 99% dos sinais |
| Estrutura | Market Structure Advanced + Structure Break Risk | confirmação de swing e BOS por fechamento | timestamp de confirmação, nunca backdating de setas |
| Valor | Anchored VWAP + ta.volume | posição relativa ao valor da sessão | âncora conhecida antes do sinal, volume tick identificado |
| Pressão | Candle Pressure Index | localização do fechamento, corpo, tick volume | contribuição incremental e normalização por corretora |
| Entrada | Signal Quality Engine | etapas SETUP → WATCH → TRIGGER | não mascarar setas perdedoras após fechamento |
| Compressão | Compression Fractal Release | contexto de squeeze antes do breakout | HTF confirmado, não depender de dados futuros |
| Saídas | Chandelier Flip Radar + ta.volatility | stop por ATR e trailing somente depois da entrada | comparação com SL estrutural, sem mudar histórico |
| Reversão | Swing Conviction Radar | enfraquecimento de movimento entre swings | pivot só depois de confirmação; marcador não retroativo |

**Primeira hipótese de integração:** estrutura causal + regime contextual + gatilhos independentes R/S/W. Validar um sensor por vez contra a versão base e reportar frequência de sinais, trade count, PF, expectativa líquida e drawdown fora da amostra.

**Critério de parada:** se indicadores duplicam informação ou exigem lookahead, não integrar. Não há evidência de que qualquer um dos scripts importados é superior ao nosso código atual; são pontos de partida auditáveis.
