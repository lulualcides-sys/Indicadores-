# Biblioteca de Indicadores — Pesquisa e Desenvolvimento

Repositório para **organizar, auditar e desenvolver indicadores de trading** a partir de materiais próprios, estudos de código Pine/MQL, fontes públicas e projetos de pesquisa. Foco atual: **XAUUSD**, MT5, M1/M5/M15, sem prometer lucro.

> **Estado em 11/11/2026:** este acervo contém materiais de pesquisa e código experimental. Testes unitários não são backtests financeiros. Nenhum indicador é aprovado para operação real apenas por estar neste repositório.

## Indicadores ORIGINAIS preservados no GitHub (MIT)

Agora a biblioteca contém **arquivos reais de terceiros**, separados dos oito indicadores próprios: **10 Pine Scripts integrais** e **o pacote Python ta** (tendência, volume, momentum e volatilidade), com licenças e hashes SHA Git idênticos às origens. **Não são lucrativos ou livres de repintura por presunção**. [Abrir arquivos e critérios](08_indicadores_originais/README.md) · [Catálogo](01_catalogos/SELECAO_ORIGINAIS_2026-11-11.csv) · [Plano de extração para nosso indicador](05_extracoes_experimentais/PLANO_EXTRACAO_ORIGINAIS_2026-11-11.md).

## Acesso rápido

| Pasta | Conteúdo |
|---|---|
| [00_politicas](00_politicas/) | Não repintura, licenças, segurança, validação e uso do arsenal |
| [01_catalogos](01_catalogos/) | Inventário geral, fontes, formatos e situação de cada indicador |
| [02_referencias_publicas](02_referencias_publicas/) | Telegram, MQL5, ORB, Bull H1M1: referências e limites de identificação |
| [03_projetos_proprios](03_projetos_proprios/) | H1 Vector Factor MT5 e documentação de versões |
| [04_auditorias](04_auditorias/) | Auditorias dos arquivos enviados (DTC, Wyckoff, SMC, Auto Range, etc.) |
| [05_extracoes_experimentais](05_extracoes_experimentais/) | Recursos Python derivados, testes focados e manifestos |
| [06_resultados](06_resultados/) | Registro verificável de testes, backtests e lacunas |
| [07_arsenal](07_arsenal/) | Ferramentas e fluxo de trabalho |
| [99_historico](99_historico/) | Catálogos históricos e índice da biblioteca preexistente |

## Atualização de pesquisa e desenvolvimento — 11/11/2026

| Indicador | Estado | Arquivo |
|---|---|---|
| **Nexus Liquidity Sweep NR v1.00** | Novo; setas após fechamento em varreduras de liquidez | [fonte e testes](03_projetos_proprios/Nexus_Liquidity_Sweep/README.md) |
| **Nexus FVG Retest NR v1.00** | Novo; primeira visita a gaps de três velas confirmadas | [fonte e testes](03_projetos_proprios/Nexus_FVG_Retest/README.md) |
| **H1 Vector Factor v1.30 NR** | Novo candidato; 2 filtros opcionais desligados por padrão | [notas e fonte](03_projetos_proprios/H1_Vector_Factor/v1.30/NOTAS.md) |
| **H1 Vector Factor v1.20 NR** | Preservado, sem regressão deliberada | [versão anterior](03_projetos_proprios/H1_Vector_Factor/v1.20/H1_Vector_Factor_M1.mq5) |

[Pesquisa de Telegram e fontes MQL5 adicionais](02_referencias_publicas/PESQUISA_INCREMENTAL_2026-11-11.md). **Testes Python/estáticos não substituem compilação no MetaEditor nem backtest com preço real.**

## Novos projetos — expansão 11/11/2026 (segunda rodada)

| Projeto | Código autoral | Testes |
|---|---|---|
| **Nexus Session VWAP Reclaim NR 1.00** | [VWAP de sessão com volume relativo e setas](03_projetos_proprios/Nexus_Session_VWAP/README.md) | [CI](.github/workflows/nexus-vwap-nr.yml) |
| **Nexus Structure Break NR 1.00** | [Pivôs confirmados + BOS/CHoCH simplificado](03_projetos_proprios/Nexus_Structure_Break/README.md) | [CI](.github/workflows/nexus-structure-nr.yml) |

[Pesquisa incremental com oito referências e canais do Telegram](02_referencias_publicas/PESQUISA_MODULOS_2026-11-11_B.md) · [catálogo CSV](01_catalogos/novos_indicadores_2026-11-11_B.csv).

**Regra de aprovação:** código e testes unitários não significam compilação no MT5, lucro ou ausência de repaint em corretora real. Os indicadores anteriores permanecem inalterados.

## Nexus Clean Signals NR — versão minimalista (pesquisa transversal)

**[Novo indicador com código próprio e 3 variações](03_projetos_proprios/Nexus_Clean_Signals/README.md)** para MT5: **AUTO**, **BREAKOUT** e **SWEEP**. O padrão visual é **somente duas setas (BUY/SELL) e uma linha discreta no canto**. TP/SL só aparecem se o usuário ativar a visualização do último plano.

- **Regime:** Kaufman Efficiency Ratio (ER) de candles anteriores; não é previsão ou probabilidade.
- **Sinais:** exclusivamente após fechamento, sem mover as setas em atualizações normais.
- **Validação:** casos sintéticos, testes de prefixo temporal e regressão estática automatizados; compilação MetaEditor e backtests reais **ainda pendentes**.
- **Pesquisa de 15 abordagens:** [MQL5 CodeBase, GitHub, TradingView e Market](02_referencias_publicas/PESQUISA_TRANSVERSAL_INDICADORES_2026-11-11.md).
- **Integração:** não substitui H1 Vector Factor, Liquidity Sweep, FVG, VWAP ou Structure Break; versões anteriores permanecem disponíveis.

## Novos indicadores — compressão e tendência (11/11/2026)

O acervo próprio passa de **6 para 8 indicadores**. Dois novos componentes **independentes e sem repintura intencional**:

| Novo indicador | Gatilho | Código |
|---|---|---|
| **Nexus Volatility Squeeze Break NR v1.00** | Liberação de compressão BB/Keltner e rompimento confirmado | [Fonte e testes](03_projetos_proprios/Nexus_Volatility_Squeeze/README.md) |
| **Nexus EMA Trend Pullback NR v1.00** | Reteste e continuação após EMA20/EMA50 | [Fonte e testes](03_projetos_proprios/Nexus_EMA_Trend_Pullback/README.md) |

[Pesquisa técnica MQL5](02_referencias_publicas/PESQUISA_SQUEEZE_PULLBACK_2026-11-11.md) · [Kit MT5 v2 para testar oito indicadores](tools/mt5_manual_backtest_v2/LEIA_PRIMEIRO.md).

**Atenção:** aprovação dos testes estáticos/temporais não é compilação no MetaEditor nem comprovação de lucro. Os seis indicadores e o kit de teste anteriores foram preservados.

### Regra permanente: SEM REPAINT
Sinais BUY/SELL **apenas após fechamento** do candle; sem leitura de dados futuros, sem mover/excluir seta já confirmada em ticks normais. Uma recarga ou correção de OHLC pelo broker exige auditoria especial. Ver [política](00_politicas/SEM_REPAINT.md).

### Regra de uso de terceiros
Este repositório é **público**: não publique arquivos .ex4/.ex5 desconhecidos, fontes de licença não verificada, credenciais nem cópias de indicadores pagos. Para esse material, manter **inventário, links e auditoria própria**, não espelhar binários ou código de terceiros sem verificar permissões.

### Sobre o Bull H1M1
O nome, plataforma e comportamento visível no vídeo foram pesquisados; **não temos o código interno nem prova de equivalência dos sinais**. O projeto H1 Vector Factor é uma implementação independente, não cópia comprovada.

### Projetos relacionados
- [Nexus Quant Paper](https://github.com/lulualcides-sys/nexus-quant-paper): pesquisa de estratégias e robôs (separados deste acervo).
- Biblioteca original de trabalho: `Biblioteca_Indicadores_Trading` na Library do ChatGPT; parte do conteúdo foi consolidada aqui como documentação, análises e código próprio.

**Preservar originais, separar hipóteses de evidências, exigir avaliação fora da amostra e custos reais antes de qualquer recomendação de uso.**
