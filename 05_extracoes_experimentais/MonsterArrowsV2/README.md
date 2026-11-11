# Arsenal de Indicadores — Monster Arrows v2.0 SMC

**Status:** extração técnica concluída; estratégia **NÃO VALIDADA** em histórico de mercado; **NÃO** conectada ao MetaTrader 5.

Fonte: `original/Monster_Arrows_v2_SMC.pine` (cópia binariamente idêntica ao TXT recebido; NÃO alterada).

## Conteúdo

- `original/`: Pine Script v5 recebido (apenas cópia, sem alterações).
- `auditoria.md`: análise técnica, problemas concretos e planos de correção.
- `extracao_python/smc_core.py`: funções Python reaproveitáveis, **experimentais**, sem envio de ordens.
- `testes/test_smc_core.py`: testes unitários com candles sintéticos.
- `manifest.json`: módulos catalogados, prioridade e estado.

## Não confundir

- Testes unitários de lógica ≠ backtest com dados reais.
- Marcar uma seta em pivô passado ≠ permitir entrada naquele preço passado.
- Manter os módulos da extração separados ≠ alterar os robôs já existentes.
- Converter um indicador ≠ implementar exatamente o robô/EA original MQ4.

## Como executar os testes

```bash
python -m unittest discover -s testes -v
```

## Plano para XAUUSD

1. Confirmar pivôs respeitando a data/hora **do conhecimento** (pivô + barras de confirmação).
2. Exigir quebra e retorno para dentro da liquidez; manter o nível ancorado em pivô já confirmado.
3. Medir FVG por tamanho relativo ao ATR, proximidade e toque/mitigação; não apenas existência.
4. Usar valores HTF **confirmados**, com mapeamento temporal correto e sem vazamento futuro.
5. Entrar somente no candle de confirmação ou depois; precificar spread, slippage, swaps e custos.
6. Rodar XAUUSD M1/M5/M15/M30 em mesmos dados, depois ablação: base, +sweep, +FVG, +HTF, +Fib.
7. Selecionar por retorno líquido fora da amostra, drawdown, nº operações, estabilidade e custos.

Nada aqui justifica prometer lucro. Esta pasta é uma **biblioteca de pesquisa**, não sinal para operação em conta real.