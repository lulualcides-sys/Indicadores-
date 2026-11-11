# Biblioteca de indicadores — triagem e extrações

Objetivo: preservar cada arquivo recebido, registrar o que cada indicador **realmente faz** e separar ideias reutilizáveis para pesquisas em XAUUSD sem alterar os robôs existentes.

## Estrutura
- `01_originais/`: fonte exatamente como recebida; não editar.
- `02_analises/`: funcionamento, falhas, pontos fortes e limitações.
- `03_extracoes_promissoras/`: regras e componentes reaproveitáveis, ainda **não aprovados** como estratégias lucrativas.
- `04_validados_em_backtest/`: somente componentes comprovados por testes reproduzíveis com custos e validação fora da amostra.
- `05_descartados/`: propostas rejeitadas após análise, com justificativa registrada.
- `catalogo.csv`: rastreamento de arquivos, classificação e status de evidência.

## Processo para cada novo arquivo
1. Salvar cópia original sem alterações e identificar nome/versão.
2. Ler código por completo e descrever lógica de entradas, saídas, filtros, risco, alertas e possíveis repaint/lookahead.
3. Registrar erros verificáveis e limitações com referências ao código.
4. Extrair somente funções/regras úteis, sem confundir utilidade potencial com lucratividade.
5. Catalogar hipóteses de teste para XAUUSD M1, M5, M15 e M30.
6. Só promover a `04_validados_em_backtest/` após dados, custos, métricas e teste fora da amostra auditáveis.

**Regra:** indicadores NÃO entram automaticamente nos robôs. Preservar versões originais e resultados já aprovados.

Criado em 2026-11-10. Primeiro item: DTC v1.36.

## Arquivos compilados EX4 / EX5
- Manter originais e checksums SHA-256; não executar arquivos de terceiros nesta etapa.
- Um EX4/EX5 não equivale ao código-fonte MQ4/MQ5. Sem fonte ou observação direta de comportamento, regras de entrada, repaint e rentabilidade são desconhecidos.
- Ideias extraídas apenas do **nome** ou de **fontes externas** são rotuladas como hipóteses independentes, não como funcionalidades comprovadas do arquivo.
- Promover somente após backtest demonstrável e teste fora da amostra, com spread, comissões e slippage.

## Lote 2026-11-10: QKE + BC Zones
- `Quantum Kinetic Engine.txt`: título interno **MR Mt4 (Ultra Fast)**, código Pine v5; avaliação completa em `02_analises/QKE_MR_UltraFast_analise.md`. Marcadores de suposta vitória não equivalem a PnL.
- `Support & Resistance BC Zones.ex5`: compilado MT5, não executado; fórmula interna desconhecida. Análise limitada à triagem do arquivo.
- Biblioteca possui **7 arquivos originais** no total, **0 aprovados em backtest**.

## Novo indicador 2026-11-10: Auto Range Detector
- Original: `01_originais/AutoRangeDetector_TradingView_original.txt` (Pine Script v6).
- Análise: `02_analises/AutoRangeDetector_analise.md`.
- Extração testada: `03_extracoes_promissoras/AutoRangeDetector/range_features.py`; testes em `test_range_features.py`.
- Cinco testes unitários aprovados; **nenhum backtest de rentabilidade realizado**. O código Python não implementa a máquina de estados de rompimentos e não tem equivalência bit a bit verificada com TradingView.

## Novo indicador 2026-11-10: Market Structure Dynamics & Order Blocks
- Original preservado em `01_originais/MarketStructure_Dynamics_OrderBlocks_original.txt` (Pine v6, MPL 2.0).
- Auditoria em `02_analises/MarketStructure_Dynamics_OrderBlocks_auditoria.md`.
- Extração experimental Python + **10 testes unitários aprovados** em `03_extracoes_promissoras/MarketStructureOB/`.
- Correções conceituais: score heurístico sem alegar probabilidade; não inventar Order Block sem vela contrária; sobreposição completa; toque separado de invalidação; somente close confirmado.
- **0 backtests executados neste indicador, 0 aprovação para robô**. Sem alteração dos robôs existentes.