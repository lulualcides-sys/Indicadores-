# Testes de regressão e instalação — H1 Vector Factor

- O arquivo `v1.20/H1_Vector_Factor_M1.mq5` é a referência principal.
- O diretório `testes/` reúne 9 **guardas estáticas** versionadas que podem rodar no GitHub Actions.
- Comando: `python -m unittest discover -s 03_projetos_proprios/H1_Vector_Factor/testes -p 'test_*.py' -v`.
- A suíte **original de pesquisa**, executada em 11/11/2026 fora do GitHub, apresentou **15/15 testes** Python e estáticos; ela inclui casos de invariância temporal com barras sintéticas. Os 9 testes versionados aqui são uma camada menor e **não equivalem à suíte completa de 15**.
- Não dizer que passou em MT5/MetaEditor apenas porque passou em Python. Falta compilar e registrar logs.
- Não dizer que existe backtest rentável sem dataset, custos e curva de trades auditáveis.
