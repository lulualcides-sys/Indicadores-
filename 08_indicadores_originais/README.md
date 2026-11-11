# Biblioteca real de originais — licenças MIT e MPL-2.0 — 11/11/2026

**Agora são códigos originais, e não apenas links.** Arquivos preservados em caminhos reconhecíveis de suas fontes, com licença MIT intacta e commits fixos. Cada hash Git foi comparado **byte a byte** com o blob correspondente no repositório de origem.

## Pacotes preservados
1. **WavesUnchained / casoon/pine-scripts** — [origem](https://github.com/casoon/pine-scripts/tree/880c228d63f37c3af0bc524346ff453c375d7bae) · commit `880c228d63f37c3af0bc524346ff453c375d7bae` · **10 scripts Pine v6 selecionados**, 4 READMEs originais e [LICENSE](01_pine_wavesunchained/LICENSE). São códigos para **TradingView**, não arquivos instaláveis no MetaTrader.
2. **Bukosabino / ta** — [origem](https://github.com/bukosabino/ta/tree/a890410710a6e483c9ba08da7f3dd5089e4b9dff) · commit `a890410710a6e483c9ba08da7f3dd5089e4b9dff` · pacote Python de análise técnica, incluindo módulos `momentum`, `trend`, `volatility`, `volume`, `others`, `wrapper`, `utils`, `__init__` e [LICENSE](02_python_ta/LICENSE). Dependências: pandas e numpy. O README original descreve dezenas de indicadores; **não são 43 backtests aprovados**.

### O que significa «melhores»
Aqui significa **candidatos tecnicamente promissores com fonte legalmente acessível**, selecionados por clareza da fórmula, função distinta, existência de documentação e facilidade de auditar/portar. Não significa «maior lucro verificado». O conjunto Pine de origem tem scripts em estágios diferentes de maturidade, inclusive rascunhos. Isso será considerado na auditoria.

[Catálogo de 10 seleções com alertas](../01_catalogos/SELECAO_ORIGINAIS_2026-11-11.csv).

## Método obrigatório daqui em diante
1. Pesquisa em GitHub / Pine / MQL5 CodeBase / Telegram públicos.
2. Seleção do **código-fonte original**, verificando licença, commit, funcionamento e relevância; copiar só com autorização legal, preservando crédito e termos.
3. Registrar arquivos reais em `08_indicadores_originais` e hash em [manifesto](manifesto_origens.json). Arquivos `.ex4/.ex5` e códigos pagos/sem licença não entram na pasta pública.
4. Auditar repintura no código: `barstate.isconfirmed`, `request.security`, `lookahead`, pivôs com barras à direita, desenhos históricos, anchors recalculadas. **Flag estática é indício, não prova**.
5. Extrair um padrão causal próprio para `05_extracoes_experimentais`, com teste de prefixo de dados e documentação da origem; não alterar o original.
6. Integrar componentes **apenas se agregarem valor** ao Nexus Clean Signals v2, sem 20 filtros sequenciais. Usar um gráfico limpo com seta BUY/SELL após fechamento.
7. Comparar sinais, frequência, custos e teste fora da amostra no MT5 antes de considerar aprovado.

Os **10 indicadores MT5 próprios existentes** permanecem em `03_projetos_proprios` e não foram alterados nesta importação. A implementação final unificada é uma etapa posterior, não declarada como pronta.

**Status**: integridade/origem verificadas; compilação Pine/MetaEditor, auditoria detalhada de cada script e lucros reais **não verificados**.

## Segunda leva de originais

Foram adicionados **27 Pine Scripts integrais** de **5 autores** com licenças e hashes de arquivo conferidos. [Relatório de proveniência](SEGUNDA_LEVA_2026-11-11.md).

## Lote 3 — fontes MQL5, orderflow e matemática

Mais **21 códigos integrais** de três autores, com 30 arquivos exatos (licenças/documentação preservadas). São fontes de pesquisa, **não** provas de lucratividade ou ausência de repaint. [Relatório](LOTE3_PESQUISA_2026-11-11.md) · [Manifesto SHA](manifesto_lote3.json).
