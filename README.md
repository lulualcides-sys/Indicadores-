# Biblioteca de Indicadores — Pesquisa e Desenvolvimento

Repositório para **organizar, auditar e desenvolver indicadores de trading** a partir de materiais próprios, estudos de código Pine/MQL, fontes públicas e projetos de pesquisa. Foco atual: **XAUUSD**, MT5, M1/M5/M15, sem prometer lucro.

> **Estado em 11/11/2026:** este acervo contém materiais de pesquisa e código experimental. Testes unitários não são backtests financeiros. Nenhum indicador é aprovado para operação real apenas por estar neste repositório.

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
