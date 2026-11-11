# Nexus Three-Candle Reversal NR v1.00

**Implementação autoral independente** de padrão de três velas, inspirada exclusivamente em descrições públicas de candidatos do Telegram. Não reproduz código proprietário, não afirma equivalência a produto comercial.

**Lógica:**
1. Primeiro candle fechado de baixa (para BUY) ou alta (para SELL), corpo mínimo em ATR anterior.
2. Segundo candle **já fechado** estende o movimento e fecha na direção anterior.
3. Terceiro candle de confirmação fecha acima (BUY) ou abaixo (SELL) do **ponto médio do corpo do primeiro candle**, com força mínima de corpo direcional.
4. Só então exibe uma seta; segue política de não modificar setas anteriores nos ticks normais.
5. Dois buffers padrão BUY(0)/SELL(1), utilizáveis pelo EA testador **após compilação**.

**Limites:** sinal não ocorre antes do fechamento da terceira vela. O método tem latência deliberada e pode falhar em tendência forte. Parâmetros ainda não otimizados, e isso é intencional para evitar sobreajuste.

**Fonte do conceito:** [3-Candle Mid-Body Price Action Signals](https://www.tradingview.com/script/HvQ4iqDX-3-Candle-Mid-Body-Price-Action-Signals-5-RR-Targets-Risk-Cal/) divulgado em `@simpleforextools`. Licença de reutilização desse script **não confirmada**, portanto nenhuma linha foi copiada.

**Status:** código próprio e testes Python sintéticos; MetaEditor, teste real de não repintura e validação financeira no MT5 pendentes.
