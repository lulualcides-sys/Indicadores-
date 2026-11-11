# Market Structure Dynamics & Order Blocks — extração experimental

Fonte: Pine Script v6 original, arquivado em `../../01_originais/` no repositório de biblioteca.

`structure_features.py` é uma implementação **independente e deliberadamente limitada** de features: confirmação de pivôs, BOS, Z-score, classificação de volume, candle originador de zona, sobreposição, reteste e invalidação. Não é EA/robô, não conecta ao broker, não abre operações e não possui estratégia de saída.

Código 100% biblioteca padrão Python. Execute testes no diretório:

```bash
python -m unittest -v
```

Os scores são heurísticos, NÃO probabilidades. Testes unitários locais não demonstram precisão contra TradingView, não garantem backtest positivo e não são auditoria de mercado real. Para diferenças conhecidas, consulte `02_analises/MarketStructure_Dynamics_OrderBlocks_auditoria.md`.

Status: **Pesquisa — não integrado / não validado em backtest**.