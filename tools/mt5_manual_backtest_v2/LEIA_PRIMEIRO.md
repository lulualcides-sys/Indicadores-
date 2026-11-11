# COMO TESTAR NO MT5 — PACOTE DE 8 INDICADORES

Este pacote tem os oito codigos MQ5 e um Expert Advisor (EA) que converte as setas BUY/SELL confirmadas em operacoes no Strategy Tester. Ele nao permite negociacao fora do Strategy Tester.

INSTALAR
1. No MetaTrader 5 para Windows, escolha Arquivo > Abrir Pasta de Dados.
2. Copie o conteudo da pasta MQL5 do ZIP para a pasta MQL5 aberta.
3. Pressione F4 para abrir o MetaEditor.
4. Compile um a um os oito arquivos em Indicators/NexusBacktest com F7; verifique erros na parte inferior.
5. Compile o arquivo Experts/Nexus_Indicator_Tester_EA.mq5 com F7.
6. Se algum arquivo nao compilar, nao afirme que ele funciona. Anote o erro e a linha.

TESTE VISUAL DAS SETAS (SEM ROBO)
- No MetaTrader, Ctrl+R para abrir o Strategy Tester.
- Escolha o tipo Indicadores, selecione o indicador, escolha XAUUSD, timeframe e periodo.
- Inicie em modo visual. Inspecione quando aparece cada seta; uma seta confirmada nao deve mudar posteriormente.
- H1 Vector Factor v1.30 so funciona em M1.

TESTE FINANCEIRO COM OPERACOES SIMULADAS
- Ctrl+R > Expert Advisors > Nexus_Indicator_Tester_EA.
- Ativo: XAUUSD de sua corretora. Teste M1, M5, M30 e H1 separadamente.
- Modelo: Cada tick baseado em ticks reais, se disponivel. Ative visualizacao se quiser ver trades.
- Input InpIndicator: 0=H1 Vector (M1), 1=Liquidity Sweep, 2=FVG Retest,
  3=Session VWAP, 4=Structure Break, 5=Clean Signals, 6=Volatility Squeeze Break, 7=EMA Trend Pullback.
- Para Clean Signals, InpCleanMode: 0=AUTO, 1=BREAKOUT, 2=SWEEP.
- InpLots: lote fixo de 0.01 por padrao.
- InpTakeProfitR: 1.0 por padrao; 2.0 permite comparar saida 2R.
- InpTimeExitBars: saida por tempo se nao tocar SL ou alvo, por padrao 12 candles.
- InpMaxSpreadPoints: 0 nao filtra. Os custos sao os do seu broker no tester, nao os do backtest Python anterior.
- Compare taxa de acerto, total de trades, lucro liquido, PF e drawdown do RELATORIO do MT5.

IMPORTANTE
- O EA le buffer 0=BUY e 1=SELL apenas da ultima vela FECHADA.
- Entra no primeiro tick da vela seguinte. Nao opera no fechamento da vela anterior.
- Stop do EA usa maxima/minima da ultima vela e 0.08 ATR. Pode diferir dos niveis SL visuais originais do indicador.
- Parametros individuais dos indicadores permanecem nos valores padrao do MQ5; o EA expoe apenas o modo Clean.
- Nao foi possivel compilar no MetaEditor neste ambiente. Testes de Python ou checks estaticos nao garantem compilacao.
- Indicadores nao instalaveis no MetaTrader 5 Android. Precisa de Windows, desktop remoto ou VPS.

Referencias oficiais:
https://www.metatrader5.com/en/terminal/help/algotrading/visualization
https://www.mql5.com/en/docs/indicators/icustom


ATUALIZACAO v2 (8 INDICADORES)
- Os indicadores 0-5 foram mantidos com IDs originais.
- 6 = Squeeze Break NR: breakout depois de compressao Bollinger/ATR.
- 7 = EMA Trend Pullback NR: retorno confirmado a EMA em tendencia.
- Para comparar sinais sem mexer em logica, mantenha um ativo, timeframe e periodo por vez.
- O ZIP anterior de seis continua disponivel e NAO foi sobrescrito.
- Todos os arquivos sao CODIGO-FONTE; ainda precisam de compilacao MetaEditor e backtest MT5 real.
