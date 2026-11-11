# Quantum Kinetic Engine.txt — auditoria de código Pine v5

**Identidade verificada:** o arquivo se chama `Quantum Kinetic Engine.txt`, mas o código declara `indicator("MR Mt4  (Ultra Fast)", overlay=true)`. Não há definição de um “Quantum Kinetic Engine” no conteúdo. A plataforma do **código** é TradingView Pine Script v5, independentemente do termo "Mt4" no título. **Não inferir originalidade, procedência ou autenticidade.**

## Evidências do código
- Linhas 5–9: EMA50 e SMA20 são calculadas/desenhadas, mas **não filtram entrada**.
- Linhas 15–16: ATR10 e momentum percentual `100*close/close[5]` (avalia maior/menor que 100). É equivalente à direção de `close-close[5]` quando os preços são positivos.
- Linhas 18–30: compra exige candle positivo, close > close[5], amplitude high-low maior que ATR10 e fechamento nos 30% superiores da amplitude; venda exige inverso e fechamento nos 30% inferiores.
- Linhas 32–44: cooldown de cinco candles após sinal. Essa espera diminui sinais, não administra posições.
- Linhas 46–59: `W` (vitória) e `L` (derrota) são **rótulos baseados em cores dos candles subsequentes**, não resultado monetário comparado ao preço real de entrada. O segundo passo segue lógica de martingale **sem dimensionamento de posição, cálculo financeiro ou custos**.
- Linhas 63–73: o desenho dos sinais e supostas vitórias/derrotas é limitado aos últimos 300 candles; esta janela de exibição não é amostragem estatística de desempenho.
- Linhas 69–70: sinais podem variar enquanto o candle atual está aberto, pois não exigem `barstate.isconfirmed`. Não comprova repaint histórico, mas torna o sinal intrabar provisório.
- Script usa `indicator()`, não `strategy()`: sem ordens, stop, TP, preço de execução, custos, PnL ou backtest.

## Riscos operacionais / falsos resultados
- Sinal de candle amplo pode chegar tarde e sofrer reversão, especialmente em XAUUSD M1/M5.
- O código chama de vitória a direção do candle após o sinal; um candle verde pode ainda encerrar abaixo da entrada comprada; não serve de hit rate.
- A marcação de segunda chance pode induzir martingale sem controle de risco. **Não migrar esses rótulos nem abordagem de dobrar posições.**
- As médias não confirmam o sinal, apesar de estarem presentes no visual.

## Classificação
**Promissor apenas como componente de leitura de momentum/força do candle; resultado não validado.** Preservar original e reconstruir regras próprias de execução e avaliação com entradas no próximo candle, spread, slippage, comissão e dados fora da amostra.

## Verificação realizada
Leitura completa das 80 linhas do arquivo e inspeção estática. **Sem backtest**, sem acesso a preço histórico do ouro, sem inferir taxa de acerto.