# Pesquisa transversal — alternativas para um indicador limpo (11/11/2026)

## Fontes comparadas

| Recurso | Código / acesso | Utilidade | Limitação de evidência | Decisão |
|---|---|---|---|---|
| [ASQ Candle Scanner](https://www.mql5.com/en/code/71504) | `.mq5` CodeBase | cinco padrões e visual *arrows only* | avaliações do criador não comprovam lucro | Adotar conceito **visual**, não copiar código |
| [Trend Regime Inspector](https://www.mql5.com/en/code/75868) | `.mq5` CodeBase | Kaufman ER e ADX, mercado tendência x ruído | não prever entradas | Adotar ER como **contexto**, isolado |
| [Efficiency Ratio direcional](https://www.mql5.com/en/code/22700) | `.mq5` CodeBase | eficiência do movimento, níveis dinâmicos | regime não é probabilidade | Fórmula independente |
| [market-structure-engine](https://github.com/kayasolomon/market-structure-engine) | GitHub aberto | pivôs confirmados, atraso explícito, testes prefixo/batch | não é MT5 | Benchmark metodológico |
| [poi-liquidity-detector](https://github.com/kayasolomon/poi-liquidity-detector) | GitHub aberto | FVG, OB, EQH/EQL, sweep, ciclo de vida | zonas podem evoluir; datas de confirmação importam | Pesquisa v2 |
| [MTF Confluence Dashboard](https://github.com/WiseManAlgo/MTF-Confluence-Dashboard) | Pine v5, MPL2 declarada | painel compacto, EMA+RSI em períodos | HTF não confirmado pode repintar | UI opcional, não portar MTF sem teste |
| [TTMS Squeeze](https://www.mql5.com/en/code/20273) | `.mq5` CodeBase | compressão BB x Keltner | squeeze não indica lado com precisão | Candidato para pesquisa separada |
| [Bollinger bands squeeze](https://www.mql5.com/en/code/22615) | `.mq5` CodeBase | regime comprimido | duplicação de TTMS | Não combinar os dois de uma vez |
| [ATR Trailing Stop (Pine port)](https://www.mql5.com/en/code/77655) | `.mq5` + referência Python/Pine | trailing só após fechamento | stop não garante ganho | Candidato para ferramenta de risco |
| [Liquidity Sweep Equal Highs Lows](https://www.mql5.com/en/code/79401) | `.mq5` CodeBase | níveis EQH/EQL confirmados | sinal de sweep ≠ reversão certa | Já temos módulo próprio |
| [Opening Range Breakout + VWAP Stats](https://www.mql5.com/en/code/79038) | `.mq5` CodeBase | ORB, VWAP e métricas de sessões | estatística passada não prevê lucro | Já temos módulos distintos |
| [ASQ Candle Scanner](https://www.mql5.com/en/code/71504) | `.mq5` CodeBase | inside bars / engulfing | possível redundância com candle score | Não adicionar filtro extra |
| [AI Kaufman Efficiency Ratio](https://www.mql5.com/en/market/product/202635) | Grátis no Market, fonte não comprovada | regime | gratuito ≠ open source | Usar conceito, não software |
| [Volatility Squeeze BB/Keltner](https://www.mql5.com/en/market/product/202657) | Grátis no Market, fonte não comprovada | squeeze | mesmo problema de licença | Pesquisa |
| [Breakout Pulse Navigator](https://www.mql5.com/pt/market/product/185531) | Grátis no Market, fonte não comprovada | pressão/squeeze/Donchian/volume | sobreposição de fatores | Pesquisa |

## Princípio de projeto
**Uma seta = um evento confirmado no fechamento.** Separar **regime** (ER) de **gatilho** (rompimento ou varredura) e **risco** (SL, R-múltiplos). Nunca chamar score heurístico de porcentagem de chance.

## Matriz de variações
- **AUTO**: ER anterior seleciona contexto; avaliar distribuição de sinais e custos, não presumir superioridade.
- **BREAKOUT**: comparar com versões anteriores de ORB/Structure; evitar duplicação de sinais próximos.
- **SWEEP**: comparar com Nexus Liquidity Sweep, preservando análise de varreduras em regiões distintas.
- **CLEAN**: duas setas + texto discreto; plano de risco desativado.
- **LAST_PLAN**: um conjunto de níveis no último sinal, ocultando anteriores mas não apagando setas.

## Pesquisa não significa reprodução literal
Nada nesta rodada provou ganhos, ausência de repintura no terminal, nem licença livre para redistribuição de projetos do Market. O novo código é autoral; referências são links.
