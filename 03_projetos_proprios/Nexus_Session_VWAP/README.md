# Nexus Session VWAP Reclaim NR v1.00

Novo indicador autoral MT5, separado do H1 Vector Factor, Liquidity Sweep e FVG Retest.

**Funções**
- VWAP acumulado a cada dia pelo relógio do servidor MT5, com preços típicos HLC3 ponderados por volume de ticks (alternativamente volume real quando disponível).
- Bandas ± desvio padrão ponderado; apenas **candles fechados** entram nos buffers.
- Sinais **BUY/SELL** de recuperação/cruzamento do VWAP: o fechamento anterior está do lado oposto do VWAP anterior, e a vela atual fecha e confirma no novo lado.
- Pontuação **heurística**: corpo direcional (40%), distância do fechamento ao VWAP (35%), volume relativo (25%). Não representa probabilidade.
- Volume relativo usa a média das barras anteriores, nunca volume futuro. Filtro de RVOL desativado por padrão para manter frequência.
- Setas de compra/venda fixas após confirmação, referência de preço, SL e TP1/TP2/TP3 desenhados só no próximo candle; não executa ordens.
- Funciona nos timeframes intradiários M1/M5/M15, sujeito a validação.

**Limitações**
- No XAUUSD spot o volume de ticks é do *feed da corretora*, e não volume consolidado de todo o mercado.
- Âncora em meia-noite do servidor, e primeira sessão parcial em histórico truncado pode ter VWAP incompleto. Usar dados completos para testes.
- Ao reimportar/corrigir histórico (`prev_calculated=0`), a reconstrução pode alterar marcas; isso não é a alteração intrabar ordinária que proibimos.
- As setas são confirmações retrospectivas **disponíveis apenas quando a vela acabou**, não eram negociáveis na abertura dessa mesma vela.
- Não usar lucro real ou taxa de acerto sem dados tick, custos, corretora e estratégia de execução.

Referências conceituais: [Session Levels MQ5](https://www.mql5.com/en/code/78045), [AI Relative Volume gratuito](https://www.mql5.com/en/market/product/202646) e [VWAP by Professionals gratuito](https://www.mql5.com/en/market/product/180996). **Nenhum código de terceiros foi copiado**.

Testes estáticos e de prefixo temporal no diretório `tests/`; falta compilação MetaEditor e teste em conta demo.
