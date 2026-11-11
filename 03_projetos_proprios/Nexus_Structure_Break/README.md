# Nexus Structure Break NR v1.00

Indicador autoral de estrutura de mercado para MT5. **Confirma pivôs antes de usar seus preços para emitir sinais**.

## Como funciona
1. Topo/fundo candidato com `InpLeftBars` candles anteriores e `InpRightBars` posteriores.
2. A confirmação do pivô é considerada **apenas após o fechamento do último candle da direita**. Não desenhamos uma seta retroativamente no candle do pivô.
3. BUY: uma vela fechada rompe acima do último topo **já confirmado**, com fechamento anterior abaixo do nível e corpo direcional positivo. SELL: inverso no fundo.
4. **BOS** sinal na direção da estrutura anterior. **CHoCH** é rompimento no sentido oposto à última ruptura registrada; é uma **definição operacional simplificada**, não taxonomia institucional certificada.
5. Setas BUY/SELL no candle que **acaba de fechar**, com TP1/2/3 e SL visualizados somente a partir da abertura do candle seguinte.
6. Pivôs e níveis exibidos no buffer a partir do momento em que ficaram disponíveis. Sem usar o candle 0 para entrada.
7. Funciona em XAUUSD M1/M5/M15, mas necessita configuração e backtest por timeframe.

## Não repintura: propriedades e ressalvas
- Cálculo incremental preserva sinais fechados; não modifica seus buffers em ticks normais.
- `InpRightBars` determina atraso explícito de confirmação de pivôs, inevitável sem informações futuras.
- Ao mudar histórico OHLC por atualização/correção do broker pode haver reconstrução diferente.
- Limite `InpMaxHistoryBars`: em dados truncados, os primeiros pivôs e classificações podem não refletir a sessão inteira. Testar com histórico suficiente.
- **Não foi compilado no MetaEditor**, nem executado em demo ou submetido a backtest com dados reais.

Fonte conceitual pesquisada: [Market Structure BOS/CHoCH .mq5](https://www.mql5.com/en/code/78551), [Market Structure SMC](https://www.mql5.com/en/code/74575), [artigo MQL5](https://www.mql5.com/en/articles/22968). Código **independente**, sem reprodução dos arquivos de terceiros.
