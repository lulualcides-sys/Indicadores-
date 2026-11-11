# Nexus Clean Signals NR 1.00 — indicador unificado, visual mínimo

**Estado:** implementação própria MT5 de pesquisa, não robô. Nenhum código de terceiros foi copiado. A compilação no MetaEditor, o desempenho financeiro e a estabilidade em terminal demo estão **pendentes**.

## O que aparece no gráfico

**Padrão:** duas setas discretas (BUY verde / SELL vermelha) e **uma única linha curta** no canto indicando ativo, modo, estado de mercado (ER) e último sinal. Nenhuma caixa FVG, vinte médias coloridas ou níveis de TP/SL sobrepostos.

Quando quiser estudar risco, escolher `InpView=NCS_LAST_PLAN`: aparecem apenas o **último** preço de referência, SL e 3 TPs. O plano começa no **próximo candle** (quando o sinal foi conhecido), sem inserir linhas antes do fechamento. Ao chegar novo sinal, o plano anterior some **apenas na interface**, as setas confirmadas continuam no buffer.

## Três variações comparáveis

| Modo | Condição de entrada | Uso sugerido |
|---|---|---|
| **AUTO** (padrão) | Kaufman Efficiency Ratio (ER) das barras anteriores determina quais gatilhos são elegíveis: ER ≥ 0,43 favorece rompimento, ≤ 0,25 favorece sweep, entre os limiares testa ambos | Alternância de regime **experimental**, não garantia de melhoria |
| **BREAKOUT** | Fechamento além da máxima/mínima dos 18 candles **anteriores**, corpo direcional e distância normalizada pelo ATR | Tendência / expansão |
| **SWEEP** | Pavio ultrapassa extrema anterior e candle fecha de volta dentro da faixa; rejeição direcional | Reversão / liquidez |

O **ER** é `abs(C[t-1]-C[t-1-N])/sum(abs(delta))` sobre candles anteriores ao sinal; varia entre 0 e 1 (não é probabilidade de trade). O score próprio combina qualidade da vela, distância ao nível e adequação de regime, **sem pretender estimar win-rate**.

O resultado em AUTO **não deve ser comparado** a BREAKOUT/SWEEP com parâmetros distintos. Cada modo precisa de amostra, log e custo de execução próprios.

## Política sem repintar
1. Nunca usa OHLC de `bar 0` para emitir sinal.
2. ATR, ER e faixa de preço são calculados com candles **anteriores** ao sinal; candle do gatilho também precisa estar fechado.
3. Processamento incremental não reescreve seta de candle já confirmado. Em recarga com `prev_calculated=0`, o histórico pode ser recalculado, inclusive se broker alterar os candles.
4. Candle histórico que contém seta não prova que a seta estava visível antes de seu fechamento. O momento real de conhecimento é o **início do candle seguinte**.
5. No modo compacto, linhas de SL/TP são ocultas **de propósito**; não significa que stops ou alvos sejam dispensáveis.

## Instalação em conta demo
Copiar [Nexus_Clean_Signals_NR.mq5](v1.00/Nexus_Clean_Signals_NR.mq5) para `MQL5/Indicators/`, compilar no MetaEditor (F7), aplicar em XAUUSD M1/M5/M15, acompanhar sinais e logs de mudança de candle.

## Checklist de aprovação
- [ ] Compilação MetaEditor 0 erros / 0 avisos
- [ ] Prefixo temporal + teste incremental em MT5 com ticks reais e recarga
- [ ] Quantidade de sinais por período e sessão sem filtro excessivo
- [ ] Backtest com execuções no próximo candle, spread, slippage e comissões
- [ ] Comparação isolada AUTO x BREAKOUT x SWEEP, inclusive fora da amostra

**Não foi provado que seja o melhor indicador, lucrativo ou sem repintura em todos os brokers.**
