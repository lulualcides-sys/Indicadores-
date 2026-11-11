# Auto Range Detector — análise e extração

Fonte: `original_tradingview.txt`, 457 linhas, Pine Script v6. Analisado em 10/11/2026.

## Avaliação

**Valor técnico: alto como módulo de contexto/estrutura. Evidência de rentabilidade: nenhuma.** Não contém execução de ordens, gestão de posições, resultados financeiros ou backtest. É um `indicator(...)`, não `strategy(...)`. Seu melhor uso inicial é reconhecer se o mercado está em lateralização, fixar limites, caracterizar rompimento e eventual falha. Não adicionar imediatamente como filtro obrigatório aos robôs: pode bloquear operações lucrativas.

## Componentes que vale reaproveitar

| Prioridade | Módulo | Origem Pine | Aplicação | Condição |
|---|---|---|---|---|
| P1 | Compressão relativa ao ATR e percentil histórico | `scanWindow`: `band_height / (atr * sqrt(len))`, `ta.percentrank` | Comparar consolidações entre regimes de volatilidade | Calibrar em cada ativo e timeframe |
| P1 | Faixas adaptativas por percentil de máximas/mínimas | `scanWindow`, `boundary_basis`, `band_percentile` | Criar suporte/resistência resistente a spikes | Validar tipos de faixa em ouro, WIN etc. |
| P1 | Filtro de lateralização com rotação/toques/contensão | `scanWindow`, `crossings`, `hits_top/bottom`, `contained`, `drift` | Diferenciar congestão de tendência ou reversão em V | Avaliar ablação por filtro |
| P1 | Rompimento por fechamento + buffer ATR | bloco `RANGE ENGINE`, `break_up/down` | Entrada candidata após confirmação e reteste | Separar detecção de execução; custos reais |
| P2 | Falso rompimento, desvio e reentrada | `range_dormant`, `reentered`, `deviation_window` | Detectar bull/bear traps para estratégia reversiva | Ajustar reentrada entre *ambas* as bordas |
| P2 | Múltiplas janelas 1x, 2x e 3x | `scanWindow` / seleção da maior janela aprovada | Capturar lateralizações curtas e longas | Medir latência e custo de CPU |
| P2 | Linha média e quartis do range | `midpoint`, `quartile_low/high` | Alvos/saídas contextuais e zonas de reação | Validar se agrega informação |
| P3 | Âncora histórica, visualizações e gradientes | `anchorSpan`, `box`, `paintShade` | Interface e auditoria visual | Nunca tomar início retroativo como sinal antigo |

## Configuração-padrão observada

- Janelas de 20, 40 e 60 barras (base 20; escalas 1x, 2x, 3x).
- Bordas: percentil 90 para topo e percentil 10 para fundo; ATR Wilder 200.
- Percentil de compressão <= 40 em histórico calibrado até 500.
- Rotação mínima 0,18 cruzamento/barra (com piso de 3); pelo menos 2 toques por limite; tolerância 0,10 ATR.
- Drift máximo 0,45 da altura da faixa; ao menos 70% dos fechamentos contidos.
- Sinal por fechamento da barra; rompimento confirmado por fechamento além da borda + 0,15 ATR.
- Absorção de wick até 0,25 ATR, quando o fechamento permanece dentro; merge de desvios ON por 10 barras; cooldown de 3 barras.

## Falhas e armadilhas identificadas no código

1. **Retirada retrospectiva de marcador.** Se `Merge Deviations` está ligado, o rompimento emite sinal no candle original e, em eventual reentrada, `label.delete(break_marker)` retira a marca visualmente. Um alerta já disparado não é desfeito. Para uma auditoria honesta, manter os eventos originais em log imutável e classificar resultado futuro separadamente.
2. **Backdating visual do range.** `anchorSpan` pode estender a borda esquerda até 300 barras para trás após confirmar a faixa hoje. O gráfico parece mostrar uma faixa detectada antes de quando realmente foi. Um backtest deve registrar `detected_at` (momento de disponibilidade) distinto de `left_anchor` (início da estrutura).
3. **Reentrada assimétrica/incompleta.** Para rompimento de alta, `reentered = close <= range_top` não exige `close >= range_bottom`; para rompimento de baixa, a verificação inversa também é incompleta. Um fechamento que atravesse toda a faixa pode ser confundido com reentrada.
4. **Sinais antecipados oscilam.** Em `Live bar`, condições mudam no candle em formação. Modo `Bar close` é mais apropriado à automação.
5. **Confirmar rompimento não prova lucro.** Não existe spread, slippage, comissões, stops, gestão de risco, fill de ordens ou teste fora da amostra no arquivo.
6. **Custo computacional.** Três varreduras com percentis, regressões e loops de barra podem ficar pesadas em execuções multiativo/M1; otimização vetorizada ou incremental é importante na produção.
7. **Toque e rotação não são eventos independentes.** `hits_top`/`hits_bottom` contam candles, não excursões independentes, o que pode superestimar 'defesas' com velas consecutivas no mesmo limite.
8. **Licença não informada neste arquivo.** Preservar a fonte original separada. Validar direitos antes de redistribuir trechos de terceiros em repositório público.

## Pasta de extração

- `original_tradingview.txt`: cópia intacta para rastreabilidade.
- `range_features.py`: reimplementação independente dos critérios de **candidato a range**, ATR e níveis; entrada OHLC, saída features por barra. Sem execução de ordens, sem merge, sem trades. Base para pesquisa.
- `test_range_features.py`: verificações deterministas de causalidade, ATR, dados inválidos e geometria.
- `ANALISE_E_EXTRACAO.md`: inventário técnico, riscos e orientação de aproveitamento.

A versão Python é uma **adaptação para pesquisa**, não uma reprodução verificada tick a tick do Pine. Em particular, a aproximação da classificação percentil e do histórico inicial precisa ser comparada numericamente com TradingView antes de afirmar paridade.

## Próximos passos (sem alterar robôs existentes)

1. Selecionar conjunto histórico de OHLC do XAUUSD e fixar corretora, timezone, spread e timezone das barras para M1/M5/M15/M30.
2. Exportar do TradingView os sinais e bordas no fechamento, comparar com Python para validar a portabilidade; corrigir divergências.
3. Construir máquinas de estado com eventos imutáveis (`range_detected`, `break_up/down`, `retest`, `failed_break`) e `detected_at` real. Desativar `Merge Deviations` para sinais mecânicos de rompimento ou preservar eventos em log mesmo após merge.
4. Testar (A) ruptura + reteste, (B) reversão nas bordas, (C) falso rompimento/reentrada, sempre contra baseline sem módulo.
5. Avaliar separadamente M1/M5/M15/M30 com spread variável, slippage e split temporal treino/teste + walk-forward. Salvar positivos apenas após validação fora da amostra; não inferir rentabilidade por quantidade de sinais.