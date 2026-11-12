# Nexus VWAP Fusion — projeto experimental independente

[**Código MT5 v1.00**](v1.00/Nexus_VWAP_Fusion_Forex_v1.00.mq5)

**O Nexus Session VWAP original NÃO foi modificado.** Este projeto é uma alternativa para testar hipóteses adicionais, não um substituto automaticamente superior.

## Componentes
- VWAP diário ancorado no dia do servidor do broker (primeiro dia parcial do histórico ignorado para gerar sinais).
- Reclaim da VWAP confirmado por 2 candles fechados além de uma distância de 0,12 ATR.
- Entrada alternativa no reteste do VWAP, alinhada às EMA 21/55, selecionável independentemente no parâmetro `InpSignalMode`.
- Pontuação: força do corpo 30%, RVOL 20%, alinhamento EMA 20%, distância da VWAP 20% e rompimento de estrutura prévia 10%. **Score não significa probabilidade**.
- Uma seta por direção confirmada, 8 barras de cooldown por padrão e uma operação virtual por vez.
- **Entrada simulada na abertura da próxima vela.** Stop além do extremo do candle-sinal +0,08 ATR.
- TP1 1R, TP2 1,5R, TP3 2R: **três terços da mesma posição** encerrados em etapas. Painel GREEN/RED baseado no **saldo final da posição inteira**, em pontos do broker (_Point), não na quantidade de TPs.
- Spread histórico aproximado incluído no preço de entrada BUY e no preço de saída SELL. Em mesma vela OHLC tocando TP e SL, SL primeiro. Saídas por timeout fecham o restante ao preço de fechamento.
- Painel com pontos, acerto, PF, drawdown máximo e contagem de encerradas/abertas. TP1/TP2/TP3/SL/Entrada visuais, setas pequenas, avisos sonoros na nova abertura sem retrospectiva.
- Nenhuma ordem real é enviada.

## Instalação

Copiar o arquivo MQ5 em `MQL5/Indicators` do MT5, compilar com **F7** no MetaEditor e anexar a um gráfico **diferente** do VWAP original. Primeiro comparar em M15/M30 usando o mesmo histórico, broker, spread e custos. Não misturar indicadores num gráfico, pois isso sobrepõe linhas, setas e painéis.

## Limites da evidência

Testes sintéticos locais (25 aprovações) verificaram mecânica parcial, spread, SL, TP, gap, timing e contratos estáticos. **NÃO houve compilação real MetaEditor nem backtest MT5/ticks**. Ausência de repintura e melhoria de rentabilidade ainda não estão comprovadas. O terminal reprocessa a janela histórica ao abrir cada candle; histórico reescrito ou mudanças no extremo antigo da janela podem gerar pequenas diferenças de reconstrução. **Não usar capital real sem validação.**

O histórico do VWAP original permanece em [Nexus Session VWAP](../Nexus_Session_VWAP/).
