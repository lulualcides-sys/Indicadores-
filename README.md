# Biblioteca de Indicadores — Pesquisa e Desenvolvimento

Repositório para **organizar, auditar e desenvolver indicadores de trading** a partir de materiais próprios, estudos de código Pine/MQL, fontes públicas e projetos de pesquisa. Foco atual: **XAUUSD**, MT5, M1/M5/M15, sem prometer lucro.

> **Estado em 11/11/2026:** este acervo contém materiais de pesquisa e código experimental. Testes unitários não são backtests financeiros. Nenhum indicador é aprovado para operação real apenas por estar neste repositório.

## Indicadores ORIGINAIS preservados no GitHub (MIT)

Agora a biblioteca contém **arquivos reais de terceiros**, separados dos oito indicadores próprios: **10 Pine Scripts integrais** e **o pacote Python ta** (tendência, volume, momentum e volatilidade), com licenças e hashes SHA Git idênticos às origens. **Não são lucrativos ou livres de repintura por presunção**. [Abrir arquivos e critérios](08_indicadores_originais/README.md) · [Auditoria causal dos 10 originais](04_auditorias/ORIGINAIS_PINE_TRIAGEM_REPAINT_20261111.md) · [Catálogo](01_catalogos/SELECAO_ORIGINAIS_2026-11-11.csv) · [Plano de extração para nosso indicador](05_extracoes_experimentais/PLANO_EXTRACAO_ORIGINAIS_2026-11-11.md).

## Originais do usuario arquivados no GitHub publico

Cinco arquivos Pine/TXT já fornecidos pelo usuário foram **copiados como texto** para [a biblioteca de fontes](08_indicadores_originais/03_autorizados_usuario/README.md), com licenças presentes e registro de origem. Não foi feito download desses anexos diretamente do Telegram nesta execução. A autorização de publicação foi **informada pelo usuário**; não foi confirmada independentemente. Arquivos de origem foram mantidos na Biblioteca. [Manifesto com hashes da cópia](08_indicadores_originais/03_autorizados_usuario/manifesto_lote1.json).

## Segunda leva: 27 códigos originais adicionais

Cinco autores com licença explícita (MIT ou MPL-2.0), total de 27 scripts e 37 arquivos originais conferidos por SHA Git. [Fontes e objetivos](08_indicadores_originais/SEGUNDA_LEVA_2026-11-11.md) · [catálogo](01_catalogos/SEGUNDA_LEVA_27_ORIGINAIS_2026-11-11.csv). Nenhum dos dez indicadores Nexus anteriores foi modificado.

## Terceiro lote de originais — fontes MQL5, orderflow e matemática

**21 códigos adicionais** arquivados com hash idêntico aos autores: seis indicadores **MT5/MQL5**, três fontes de **orderflow Pine** publicadas sob MIT pelo próprio autor e doze filtros/estatísticas matemáticos. [Lote 3 completo](08_indicadores_originais/LOTE3_PESQUISA_2026-11-11.md) · [Catálogo das 21 fontes](01_catalogos/LOTE3_21_FONTES_2026-11-11.csv) · [Triagem técnica](04_auditorias/LOTE3_TRIAGEM_2026-11-11.md).

## Telegram — segunda pesquisa de arquivos-fonte

23 novos candidatos encontrados em publicações públicas do Telegram, com priorização de H1 MTF, Turtle Soup, VSA e sessões. [Relatório](09_pesquisa_telegram/SEGUNDA_VARREDURA_2026-11-11.md) | [Catálogo](09_pesquisa_telegram/NOVOS_CANDIDATOS_2026-11-11.csv). São links para anexos anunciados; arquivos não foram baixados.

## Telegram: quatro códigos-fonte MQ5 realmente recuperados

A pesquisa de [@ShepherdFxTradingTools](https://t.me/s/ShepherdFxTradingTools) levou ao site público do publicador, que oferece ZIPs com código-fonte. Um GitHub Actions **baixou, extraiu e verificou 4 arquivos `.mq5` reais**; foram copiados sem executá-los, separados dos nossos dez Nexus.

[Abrir os 4 originais](08_indicadores_originais/12_utt_telegram_sources/README.md) · [Manifesto de downloads e SHA-256](08_indicadores_originais/12_utt_telegram_sources/manifesto_downloads.json) · [Auditoria técnica preliminar](04_auditorias/TELEGRAM_FONTE_REAL_MQ5_2026-11-11.md).

Licenças informadas pelos distribuidores: **MPL-2.0** (2 códigos) e **CC BY-NC-SA 4.0** (2 códigos, uso não comercial). Autoria e cabeçalhos originais preservados. Compilação MetaEditor e testes financeiros pendentes.

## Padrão visual e resultados em pontos

Padrão obrigatório para novos indicadores Nexus: setas pequenas e não repetidas na mesma direção, resultado em **pontos reais do preço** (não `+1/+2/+3` TPs) e etiqueta discreta verde `+N pts` / vermelha `x -N pts` / neutra para sinal não resolvido. [Especificação detalhada](PADRAO_SINAIS_E_PONTOS.md). A nova fonte `v1.21` foi entregue diretamente ao usuário, mas ainda não foi incorporada ao GitHub.

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

## Garimpo de indicadores do Telegram — pesquisa pública auditável

**17 canais/grupos** e **28 candidatos/entradas** catalogados (uma repetição temática identificada). Inclui `@simpleforextools`, `@indicadoresgratis`, `@RocktradersPublic` e outros. Dois canais informados pelo usuário não tiveram conteúdo público acessível e foram marcados como não verificados.

[Relatório com prioridade e riscos](09_pesquisa_telegram/RELATORIO_CURADORIA_2026-11-11.md) · [Canais](09_pesquisa_telegram/CANAIS_PUBLICOS_2026-11-11.csv) · [Candidatos](09_pesquisa_telegram/INDICADORES_CANDIDATOS_2026-11-11.csv) · [Hipóteses para o Nexus](09_pesquisa_telegram/HIPOTESES_EXTRACAO_2026-11-11.md).

**Política:** não copiar arquivos comerciais/pagos sem licença; não instalar EX4/EX5 desconhecidos; não afirmar no-repaint ou lucro. Nesta etapa entraram **links e descrições com fontes**, e nenhum código de terceiros foi redistribuído.

## Candidatos premium e sem licença — pesquisa + implementação independente

Os candidatos de canais públicos do Telegram também entram na pesquisa, mesmo com licença não esclarecida. **Não espelhamos código proprietário**, mas extraímos padrões observáveis para criar código autoral audível.

Dois novos **experimentos** com setas confirmadas e buffers para MT5:
- [Nexus Causal Kernel NR](03_projetos_proprios/Nexus_Causal_Kernel/README.md) — envelope gaussiano unilateral e retorno confirmado após extremo.
- [Nexus Three-Candle NR](03_projetos_proprios/Nexus_Three_Candle/README.md) — exaustão e recuperação do meio do primeiro candle em sequência de três.

[Ranking dos candidatos sem licença definida](09_pesquisa_telegram/CANDIDATOS_PREMIUM_ANALISE_TECNICA_2026-11-11.md). Nenhum é "melhor" por lucro ainda; esses dois são códigos novos a validar, e não cópias dos produtos comerciais.

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
