# Arsenal aplicado à organização (sem instalações fictícias)

## GitHub (aplicado)
- Repositório versionado, índice README, histórico de v1.10/v1.20 e auditorias separadas de código.
- Originais de terceiros não redistribuídos; experimentos isolados de indicadores aprovados.
- Toda mudança futura deverá ter commit, testes e descrição de risco/repaint.

## Ferramentas recomendadas para evolução
- **Repomix**: inventário de arquivos e mapa compacto do projeto, com exclusão de segredos e fontes sem licença.
- **ast-grep / ripgrep**: localizar referências, cálculos e indicadores nos módulos próprios.
- **Python unittest/pytest**: testes focados de fator, causalidade e séries temporais.
- **MetaEditor/MT5 Strategy Tester**: compilação real e validação no terminal (não disponíveis no ambiente atual).
- **GitHub Actions**: executar testes estáticos e Python em alterações propostas, quando configurar CI.

## Decisões
- Preferir código-fonte auditável; não rodar EX4/EX5 de fontes desconhecidas.
- Separar descoberta, auditoria, extração, integração, validação e publicação.
- Evitar vinte filtros simultâneos; adicionar apenas funções que melhoram resultados fora da amostra sem prejudicar cobertura de sinais.
- Tempo/custo: testar primeiro funções de alto valor, e não fazer varredura repetida sem ganho de evidência.
- Preservar versão aprovada e não tocar nos robôs do Nexus Quant automaticamente.
