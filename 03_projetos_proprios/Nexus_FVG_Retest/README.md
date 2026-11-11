# Nexus FVG Retest NR — v1.00

**Segundo indicador novo**, distinto do [Nexus Liquidity Sweep](../Nexus_Liquidity_Sweep/README.md) e [H1 Vector Factor](../H1_Vector_Factor/README.md). Código independente, sem execução de ordens.

### Lógica
- FVG de alta só é formado quando o **terceiro candle fecha** com `low[terceiro] > high[primeiro]`; baixa `high[terceiro] < low[primeiro]`.
- Exige tamanho mínimo relativo ao ATR **disponível no momento da formação**.
- Busca gaps **anteriormente confirmados** nos últimos N candles.
- Antes do sinal, rejeita gaps cujo nível de entrada já foi tocado por candles intermediários fechados. É uma **primeira visita**, não tentativa repetida.
- A seta aparece quando candle de retorno toca a zona e **fecha favoravelmente fora dela**, sem atravessar demasiadamente a borda oposta. SL e TP1/2/3 são só referências de risco (1R/1.5R/2R).
- Sem uso do candle em formação, dados futuros, pivôs não confirmados ou atualização de barras fechadas no processamento incremental.
- M1/M5/M15 possíveis; **ainda sem teste real**.

### Limites
- Não identifica todos os FVG nem todos os retestes: os critérios deliberadamente exigem **primeiro reteste confirmado**.
- O sinal pode ser raro dependendo de ativo/período; não adicionar filtros de fluxo ou tendência antes da medição objetiva.
- O desenho dos níveis de FVG é feito somente depois da confirmação do sinal; não fingir que o plano existia antes.
- O sinal de close não equivale a execução no mesmo preço (spread e gap no próximo candle).
- Atualização de histórico do broker pode provocar reconstrução diferente; isso é distinto de repaint intrabar, mas deve ser monitorado.
- Código-fonte externo usado como **referência conceitual**, não copiado: [Fair Value Gap Zones Tracker](https://www.mql5.com/en/code/79400).

### Testes
`python -m unittest discover -s 03_projetos_proprios/Nexus_FVG_Retest/tests -p 'test_*.py' -v`

Ainda falta compilação real no MetaEditor, ticks em demo, backtest com spread, slippage e testes fora da amostra. Sem promessas de lucro ou indicador idêntico a terceiros.
