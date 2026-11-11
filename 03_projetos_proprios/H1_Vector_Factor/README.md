# H1 Vector Factor — indicador MT5 independente

- **Versão atual:** [v1.20 sem repaint — código MQ5](v1.20/H1_Vector_Factor_M1.mq5).
- **Versão anterior preservada:** [v1.10 — código MQ5](v1.10/H1_Vector_Factor_M1.mq5).
- **Plataforma:** MetaTrader 5, gráfico **M1**. M5/M15 ainda não implementados neste indicador.
- **Tipo:** indicador, **não envia ordens**. O sinal é confirmado ao término do candle.
- **Origem:** implementação própria inspirada em elementos visuais públicos, sem equivalência comprovada ao indicador Bull H1M1.

## Componentes
1. Canal inicial de cada hora a partir dos **3 primeiros candles M1 fechados**, em horário do servidor do broker.
2. Confirmação de rompimento + pullback opcional; descarta entradas excessivamente afastadas e candidates vencidos.
3. Pontuação vetorial de **quatro fatores**: intensidade do rompimento (30%), corpo do candle (25%), momentum (30%), tamanho do canal relativo ao ATR (15%). Os pesos são hipótese original **não otimizada**.
4. Duas setas confirmadas BUY/SELL, avisos de espera/cancelamento; TP1 = 1R, TP2 = 1,5R, TP3 = 2R e SL; alertas opcionais.
5. Sem repintura intencional: não usa a vela corrente para sinal; mantém setas confirmadas no processamento incremental, com exceção de revisões de histórico.

## Instalação e teste
1. MetaTrader 5 → Arquivo → Abrir pasta de dados → `MQL5/Indicators`.
2. Copiar [arquivo da versão 1.20](v1.20/H1_Vector_Factor_M1.mq5).
3. Abrir MetaEditor, compilar com F7 e confirmar erros/avisos.
4. Anexar no gráfico XAUUSD **M1** de conta **demo**; acompanhar viradas de hora e sinais.
5. Observar e registrar repaint e eventos de recarga; seguir [critério obrigatório](../../00_politicas/SEM_REPAINT.md).

## Evidência até esta migração
A suíte Python local do pacote v1.20 foi executada em 11/11/2026: **15 testes passaram (0 falhas)**, incluindo invariância de sinais diante de dados futuros e checagens estáticas. **Não houve compilação MetaEditor nem backtest com dados reais nesta sessão**. A aprovação financeira permanece pendente.

Não usar a imagem sintética anterior de prévia como prova de execução real.
