# Nexus Liquidity Sweep Radar — NR v1.00

**Indicador NOVO, independente e complementar** ao [H1 Vector Factor v1.20](../H1_Vector_Factor/README.md). Não usa nem copia código de terceiros.

## O que analisa
- Máxima e mínima dos **N candles anteriores já fechados**.
- Sinal **SELL**: máxima da vela fechada varre a máxima anterior; fecha de volta abaixo da referência, com pavio superior e corpo vendedor.
- Sinal **BUY**: mínima da vela fechada varre a mínima anterior; fecha de volta acima, com pavio inferior e corpo comprador.
- Pontuação **heurística** (não é probabilidade): extensão além do nível (35%), proporção do pavio (35%), força da recuperação para dentro da faixa (30%).
- Duas linhas de referência históricas, setas fixas BUY/SELL e plano visual Entry, SL e TP1/2/3 (1R, 1.5R, 2R).
- Usa ATR dos candles **anteriores** ao candle do sinal; filtros opcionais de spread. Sem negociação automática.
- **Qualquer período MT5** (prioridade de estudo: XAUUSD M1/M5/M15). Os parâmetros precisam ser testados separadamente em cada timeframe.

## Não repintura
- Candle `0` (em formação) sempre vazio.
- Indicação somente quando o próximo candle começa, após o fechamento do candle de sinal.
- Em atualizações normais, barras antigas não são modificadas: `time[i] <= previousClosed` é ignorado.
- Objetos TP/SL começam no **instante em que o candle de sinal passa a estar fechado**.
- Exceção honesta: `prev_calculated=0` ou revisão do histórico pelo broker permite reconstituição; comparar logs, pois os próprios dados mudaram.
- Não usa pivôs com confirmação futura nem regressão centralizada.

## Instalação
Colocar [Nexus_Liquidity_Sweep_NR.mq5](v1.00/Nexus_Liquidity_Sweep_NR.mq5) em `MQL5/Indicators`, compilar no MetaEditor (F7), aplicar em conta demo XAUUSD M1, M5 ou M15. Depois validar disparos em tempo real.

## Estágio de validação
- Pesquisa de fontes primárias: [Liquidity Sweep Equal Highs/Lows](https://www.mql5.com/en/code/79401), [FVG Tracker](https://www.mql5.com/en/code/79400), [Order Blocks SMC](https://www.mql5.com/en/code/79271). A nossa implementação usa **extremos de janela móvel**, não EQH/EQL por pivôs. Não afirmar equivalência.
- Há testes Python independentes de cenários sintéticos e prefixo temporal em `tests/`, além de guardas estáticas para o MQL5.
- **Sem MetaEditor/MT5, feed real XAUUSD ou backtest financeiro neste ambiente**: não aprovado para operar dinheiro real; não publicar win-rate fictício.

## Sem filtros excessivos
Os limiares atuais são **defaults de engenharia**, não uma otimização. Avaliar a frequência e expectativa líquida em amostras reais antes de somar ADX/VWAP/SMC/FVG como filtros.
