# Segunda leva de originais — 27 indicadores Pine

Objetivo: pesquisar mais indicadores REAIS, guardar código-fonte com autoria e licença, depois testar componentes para o Nexus central. A prioridade não indica lucro comprovado.

**Concluído na branch:** 27 arquivos `.pine` de cinco autores, mais cinco licenças e cinco READMEs originais. Todos os 37 arquivos têm SHA Git idêntico às respectivas fontes e commits fixados.

## Proveniência

| Repositório | Licença | Scripts | Commit |
|---|---|---:|---|
| [Fonte](https://github.com/VolodymyrFilias/feels-indicators/tree/a7c92ab602ec1f9eb5b344a1629e2ad055a55f4b) | MIT | 5 | `a7c92ab602ec1f9eb5b344a1629e2ad055a55f4b` |
| [Fonte](https://github.com/Matswm86/tradingview-indicators/tree/8d20d4799f1facf5843fbee5ac756495a341ce1f) | MIT | 4 | `8d20d4799f1facf5843fbee5ac756495a341ce1f` |
| [Fonte](https://github.com/obekheet/pine-script-indicators/tree/fb68ab4a81028e9bcbde74bf8b342c38ad32bf4d) | MPL-2.0 | 8 | `fb68ab4a81028e9bcbde74bf8b342c38ad32bf4d` |
| [Fonte](https://github.com/Timonkru/pine-indicators/tree/c0534c74114466332dfa9959b53db306145caee2) | MIT | 5 | `c0534c74114466332dfa9959b53db306145caee2` |
| [Fonte](https://github.com/damianpitt/capital41-indicators/tree/ce64522f7f747abb00b37503c00e2955a6d687d2) | MIT | 5 | `ce64522f7f747abb00b37503c00e2955a6d687d2` |

## Padrões relevantes

- FEELS: zonas de suporte/resistência com toques, eficiência de zonas, Liquidity Magnet e Power of Three.
- Matswm86: sessão, LiqSweep+iFVG e Session Pulse comparando o volume/variação ao mesmo minuto dos dias anteriores.
- Taught to Trade: verificação de tamanho de amostra, custos, reversões e falsos sinais, além de sessões e toques.
- Timonkru: VWAP, delta, order blocks e varreduras ligados ao volume de contratos futuros. NÃO confundir com tick volume de XAUUSD CFD.
- Capital41: Opening Drive, regime, blocos, desequilíbrios e Session Flow.

## Limitações

- Arquivos íntegros não são automaticamente seguros contra repintura. Pivôs podem marcar retroativamente; HTF em formação pode alterar valores.
- Licença MPL-2.0 da fonte Taught to Trade permanece associada aos arquivos originais. As outras quatro fontes indicam MIT.
- Nenhum script desta leva foi compilado/testado no TradingView nem portado para MT5; sem backtest financeiro novo.
- Não foram obtidos anexos novos do Telegram diretamente nesta rodada. Os canais e indicações já catalogados continuam disponíveis na pasta `09_pesquisa_telegram`.

## Próxima etapa

Fazer triagem estática por `request.security`, `lookahead_on`, `barstate.isconfirmed`, `ta.pivot*` e offsets históricos; auditar desempenho apenas depois de versões causais para MT5.

[Catálogo CSV](../01_catalogos/SEGUNDA_LEVA_27_ORIGINAIS_2026-11-11.csv) | [Manifesto JSON](manifesto_lote2.json)