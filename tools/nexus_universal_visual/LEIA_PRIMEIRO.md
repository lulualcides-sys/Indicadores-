# Nexus — visual padronizado para 10 indicadores MT5

## O que foi feito

Uma única camada gráfica (`Nexus_Visual_Unificado_TP_Painel_Som.mq5`) disponibiliza o mesmo visual e contagem de resultados para cada um dos 10 indicadores de base do projeto. **Não altera fórmulas, sinais e arquivos originais.** Selecione o indicador em `InpModel` nas propriedades.

**Padrão:** seta pequena na abertura da vela seguinte ao sinal fechado, uma direção por vez e no mínimo 8 candles entre entradas, TP 1,5R, stop abaixo/acima da vela-sinal, texto discreto de pontos no resultado, GREEN/RED/TOTAL em pontos e som `alert.wav` quando uma nova entrada é detectada ao abrir a vela. Linhas de ENTRADA/TP/SL apenas para a operação virtual aberta; indicação TP/SL na vela em que ocorreu. O painel mostra apenas operações virtuais encerradas.

## Instalação

1. No MT5, acesse **Arquivo → Abrir Pasta de Dados → MQL5/Indicators**.
2. Crie a subpasta `NexusBase`. Copie para ela os **10 arquivos-fonte originais** `.mq5` listados abaixo, disponíveis no repositório GitHub `lulualcides-sys/Indicadores-`. Abra os dez no MetaEditor e compile com **F7** (precisa gerar `.ex5` na mesma pasta).
3. Copie `Nexus_Visual_Unificado_TP_Painel_Som.mq5` para `MQL5/Indicators`, compile com F7, atualize o Navegador e arraste-o para o gráfico.
4. Em `InpModel`, selecione qual dos 10 indicadores será lido. **Não mantenha o indicador original desenhando as próprias setas no mesmo gráfico**; a camada já lê os sinais via `iCustom` e desenha os resultados.
5. `Vector Factor M1` só aceita gráfico M1; os demais usam o período do gráfico. O indicador de VWAP é o único que pode exibir a linha azul e bandas da versão base.

## Fontes base: colocar na pasta NexusBase com estes nomes

| # | Modelo selecionável | Arquivo `.mq5` original |
|---|---|---|
| 1 | Clean Signals | Nexus_Clean_Signals_NR.mq5 |
| 2 | Liquidity Sweep | Nexus_Liquidity_Sweep_NR.mq5 |
| 3 | FVG Retest | Nexus_FVG_Retest_NR.mq5 |
| 4 | Structure Break | Nexus_Structure_Break_NR.mq5 |
| 5 | Session VWAP | Nexus_Session_VWAP_NR_v1.10.mq5 |
| 6 | Volatility Squeeze | Nexus_Volatility_Squeeze_NR.mq5 |
| 7 | EMA Trend Pullback | Nexus_EMA_Trend_Pullback_NR.mq5 |
| 8 | Causal Kernel | Nexus_Causal_Kernel_NR.mq5 |
| 9 | Three Candle | Nexus_Three_Candle_NR.mq5 |
| 10 | Vector Factor M1 | H1_Vector_Factor_M1.mq5 |

O uso universal é viável porque os dez indicadores guardam seus sinais BUY e SELL nos buffers 0 e 1. Os valores da seta original são apenas indicadores de evento; a camada NÃO copia os marcadores antigos.

## Regras dos resultados

- Entrada simulada: abertura do candle imediatamente seguinte ao candle de confirmação do indicador base.
- Stop: extremo da vela-sinal, acrescido de `InpStopBufferATR * ATR` de proteção.
- TP: `InpTP_R` vezes o risco calculado a partir da **entrada simulada** (padrão 1,5R).
- Se TP e stop forem tocados na mesma vela e não houver dados intrabar: **stop primeiro**.
- Se houver gap além do stop, usa-se a abertura pior como aproximação conservadora.
- Se nenhum nível for atingido até `InpMaxHoldingBars`, encerra virtualmente no fechamento e conta pontos ganhos ou perdidos.
- GREEN/RED e TOTAL são resultados **simulados brutos em pontos do símbolo** (`_Point` da corretora), sem spread/slippage/comissões e não representam resultado financeiro de ordens reais.
- No primeiro carregamento, não dispara alerta retroativo. O som ocorre em nova entrada ao abrir a vela, uma vez para aquele horário, se `InpSoundAlert=true` e o arquivo `alert.wav` existir em `Sounds`.
- Por usar buffers das versões originais, a ausência definitiva de repintura depende também do indicador base. É necessário conferir em MetaEditor e em tempo real.

## Estado técnico

12 testes Python de estrutura e simulação básica aprovados neste ambiente. **Não compilado no MetaEditor e não testado em MT5**, portanto compatibilidade real e estatísticas financeiras ainda não certificadas. O pacote **completo gerado pelo GitHub Actions** inclui esta camada visual, os dez arquivos originais `.mq5`, instruções e manifesto SHA-256. Compile os dez originais na subpasta `NexusBase` antes de compilar a camada visual. Um ZIP parcial fornecido anteriormente continha apenas a camada visual e os testes; prefira agora o pacote completo.