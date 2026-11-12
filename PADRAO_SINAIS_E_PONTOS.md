# Padrão permanente de sinais e resultados — Nexus MT5

Este é o padrão visual e de resultados aprovado para **novos indicadores próprios Nexus**. Não alterar bibliotecas originais de terceiros nem indicadores já aprovados sem regressões e histórico preservado.

## Aparência e frequência
- Setas pequenas, discretas e legíveis: BUY verde, SELL vermelho; `DRAW_ARROW` com `indicator_width=1` por padrão.
- **Uma seta por mudança de direção confirmada**, nunca um conjunto de BUY/SELL no mesmo candle. Confirmar somente após fechamento, limitar repetição na mesma tendência e aplicar cooldown (VWAP v1.21: 8 candles).
- Resultado em fonte pequena e legível (Tahoma 7, por padrão), em texto próximo/abaixo da seta, sem quadros ou linhas desnecessários.
- **Não mostrar `+1`, `+2` nem `+3` para a quantidade de TPs.** Mostrar **pontos do preço efetivamente alcançado até o último alvo confirmado**, por exemplo `+150 pts` em verde. Se SL ocorreu antes de TP, mostrar `x -80 pts` em vermelho. Se não houve resolução por TP/SL dentro do prazo, usar `0 pts` neutro, nunca falso RED.
- Unidade de exibição em MetaTrader: `abs(preço_referência - preço_entrada) / _Point` do próprio símbolo/corretora, com arredondamento para ponto inteiro. Não confundir pontos do broker, pips, dólares ou retorno financeiro.

## Regras de atribuição do resultado (críticas)
- A seta ocorre no candle **fechado**; a entrada simulada utiliza a **abertura do próximo candle** para evitar operar retroativamente no fechamento do candle-sinal.
- Os objetivos são calculados com o risco definido pelo stop e pelo preço de entrada após a abertura.
- Usar os extremos `high/low` somente de candles já fechados para determinar TP ou SL. Se um mesmo OHLC encostar TP e SL sem histórico intrabar, assumir **SL primeiro** para não inventar um GREEN.
- O verde representa **pontos até o último alvo atingido**, não lucro líquido realizado (a menos que haja regras de saída e execução reais documentadas). Ganho bruto de preço não prova lucro de trading.
- Se um alvo for tocado e posteriormente o SL atingir, `+N pts` marca o **melhor alvo previamente alcançado**, e não o P&L realizado de uma posição. A legenda do indicador deve documentar essa distinção.
- Sinal ainda em acompanhamento **não recebe marca de resultado**; não usar candles futuros para antecipar a etiqueta. Somente atualizar a etiqueta após o desfecho conhecido.

## Engenharia e regressão
- Manter código original por versão, preservando `.mq5`, fórmulas e buffers. Documentar migração e como retirar versões anteriores do gráfico.
- Regressão focada: BUY/SELL, spread, confirmação em candles fechados, prefix invariance, cooldown, vários TPs, SL, TP+SL no mesmo candle, timeout e tamanhos de pontos.
- Para declarar pronto para uso: compilar no MetaEditor e validar no Strategy Tester do MT5, além de testes Python. Testes sintéticos **não** atestam comportamento real nem lucratividade.

### Referência atual
- Nexus Session VWAP Reclaim NR **v1.21 Pontos**, fornecido como arquivo `.mq5` para download direto na conversa do usuário. **O arquivo ainda não está neste repositório**, e o documento não deve sugerir que tenha sido publicado na main.
- Versão v1.10 arquivada em `03_projetos_proprios/Nexus_Session_VWAP/v1.10/` para regressão.
