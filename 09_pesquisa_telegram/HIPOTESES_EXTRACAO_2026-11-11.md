# Plano de auditoria focado — conceitos novos detectados no Telegram

## 1) Zonas com resultados observáveis (Strong Recovery Zones)
Padrão para módulo **experimental** de leitura de mercado: 
- Definir uma zona apenas depois de swing confirmado; armazenar `created_at` e `confirmed_at`.
- Cada toque abre episódio com data/índice de entrada e alvo de recuperação **definido naquele momento**.
- Resolver o episódio como HELD/BROKEN/STALLED apenas depois do resultado futuro, **sem colocar indicador de sucesso no candle original**.
- Expor score histórico calculado apenas dos episódios encerrados antes do candle atual. Monitorar viés de sobrevivência e mudança de regime.
- Valor para nosso indicador: qualidade/validade de níveis S/R e sweep, não “probabilidade de chegar 90%”.

## 2) Kernel Nadaraya–Watson causal
- **Não usar** regressão centrada/simétrica que usa candles futuros para redesenhar linha passada.
- Alternativa experimental: kernel gaussiano **unilateral** sobre `close[i], close[i+1] ...` (série MQL5); largura fixa, custos O(window) por candle.
- Dividir indicador em **banda de contexto** e **gatilho por fechamento** para evitar sinais só por tocar banda durante tick.
- Medir custo computacional e atraso versus EMA sem declarar kernel superior.

## 3) Sinal 3 candles
- Primeiro/segundo candle são contexto; o terceiro é **gatilho só em fechamento**.
- Normalizar proporções por corpo/ATR; não exigir regra de midpoint muito específica sem observar amostra robusta.
- Ablação com preço fechado versus apenas rompimento básico; estatística de trades e custo por timeframe.

## 4) Liquidez com níveis por confirmação
- EQH/EQL formados em pivôs com `rightBars`; usar nível só após esse atraso explícito.
- Varredura detectada por pavio e fechamento de volta; sinal no fechamento seguinte, nunca no pivô original.
- Evitar usar dados HTF ainda em formação; se combinar HTF, pedir último candle totalmente confirmado.

## 5) Qualidade de fonte de dados ouro
- XAUUSD CFD/spot pode ter tick_volume do broker, mas não tem **volume consolidado do mercado de ouro**.
- POC/LVN de futuros GC só ficam disponíveis se tivermos cotações e volume COMEX válidos, com horário, contrato e rollover.
- Sem fluxo de futuros, deixar módulo desabilitado; não fingir “institucional”.

**Critério central:** comparar cada hipótese separadamente com o Nexus Clean Signals v1, preservar setas sem repintura, identificar a hora de confirmação, contar frequência, PF, R médio e drawdown com dados reais no MT5. Não integrar filtros que só reduzem sinais sem melhorar estabilidade fora da amostra.
