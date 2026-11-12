# H1 Vector Forex — foco principal

**Versão atual:** [H1 Vector Forex MTF v1.50](v1.50/H1_Vector_Forex_MTF_v1.50_TP123_Painel_Som.mq5) (código fonte MT5; ainda não compilado no MetaEditor neste ambiente).

Oito indicadores Nexus rejeitados foram removidos da seleção ativa; todos foram preservados no [backup anterior à limpeza](https://github.com/lulualcides-sys/Indicadores-/tree/backup/indicadores-descartados-pre-forex-20261112). Esta alteração não mexe nos códigos originais de terceiros.

## Timeframes disponíveis

**M1, M5, M15, M30 e H1.** A lógica original continua ancorada nos três primeiros candles **M1 completos** de cada hora. Um sinal detectado em M1 só pode ser usado depois de confirmado e é executado virtualmente na abertura seguinte do timeframe exibido. **H1/M30 entram mais tarde**, podendo alterar bastante a qualidade dos resultados ou invalidar o stop; não são equivalentes a sinais de M1.

## Padrão visual restaurado

- **TP1 = 1R; TP2 = 1,5R; TP3 = 2R**, três níveis visíveis mais Entrada e SL; a última operação encerrada também deixa os níveis visíveis.
- Setas pequenas, somente uma direção por vez, espaço mínimo de 8 candles entre sinais.
- Resultado em **pontos de cotação do broker** e painel GREEN/RED/TOTAL, com três saídas virtuais iguais (1/3 em cada TP).
- Entrada BUY considera spread aproximado e saída SELL considera spread aproximado. Em candle que toca TP e stop, considera **stop primeiro**.
- Som uma vez por nova abertura real de vela (`alert.wav`); **PlaySound não funciona no Strategy Tester**.
- Nenhuma ordem enviada. Não é garantia de não repintura, lucro ou backtest financeiro.

## Instalação

Copiar `v1.50/H1_Vector_Forex_MTF_v1.50_TP123_Painel_Som.mq5` em `MQL5/Indicators`, abrir no MetaEditor e compilar com **F7**. Remover a v1.40 do gráfico antes de anexar a nova. Para períodos M5/H1, carregar previamente histórico **M1** do par. Se faltar M1, o indicador não cria sinais usando dados inventados.

## Validação

18 testes **sintéticos e estáticos** passaram localmente, cobrindo horários de confirmação, cinco períodos, resultados fracionados, gap, TP/SL no mesmo candle e espelhamento de compra/venda. **Ainda falta compilar e executar no MT5**.

Histórico preservado: [v1.30](v1.30/H1_Vector_Factor_M1.mq5), [v1.20](v1.20/H1_Vector_Factor_M1.mq5), [v1.10](v1.10/H1_Vector_Factor_M1.mq5).
