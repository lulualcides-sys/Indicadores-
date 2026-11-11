# Candidatos comerciais/sem licença definida — curadoria por conceito

**Objetivo:** analisar inclusive indicadores populares anunciados como "premium" nos grupos, registrar o que podemos estudar e desenvolver implementações **independentes** no nosso projeto. A restrição é sobre **copiar ou republicar a implementação protegida**, não sobre utilizar fórmulas e princípios públicos para pesquisar.

Classificação **técnica**, não financeira. Critérios: (1) informação distinta dos 8 indicadores iniciais, (2) possibilidade de implementação causal sem repaint, (3) clareza das regras, (4) facilidade de testar em XAUUSD M1/M5/M30/H1, (5) simplicidade visual.

| Candidato do catálogo Telegram | Nota técnica / 5 | Resultado da triagem | Ação |
|---|---:|---|---|
| Nadaraya-Watson Envelope NR / kernel | 4,5 | De fato pode ser causal **somente se unilateral**; versões centradas repintam. Suavização é diferenciada, mas atraso é custo real | **Código independente criado:** [Nexus Causal Kernel](../03_projetos_proprios/Nexus_Causal_Kernel/README.md) |
| Strong Recovery Zones | 4,0 | Avaliação da validade das zonas; precisa salvar resultado de cada toque somente após o encerramento | **Pendente implementar** o ciclo HELD/STALLED/BROKEN, sem usar rótulos futuros |
| Liquidity Pools Pro / EQH EQL | 4,0 | É um contexto de regiões de liquidez; não copiar promessas de acerto do vendedor | Comparar contra Nexus Liquidity Sweep existente; evitar duplicação |
| 3-Candle Mid-Body Signals | 4,0 | Gatilho curto e explicável, terceira vela confirma | **Código independente criado:** [Nexus Three-Candle](../03_projetos_proprios/Nexus_Three_Candle/README.md) |
| Breakout Lines TP/SL | 3,8 | Retestes de linhas temporais podem ser úteis; já temos Structure/ORB | Estudar invalidação temporal e não dobrar sinais |
| ZULU Advanced SMC | 3,4 | Muitos recursos BOS/FVG/OB; risco de redundância e painéis poluídos | Exigiria auditoria de código e versão do autor; não integrar pacote inteiro |
| Choppy Market Index | 3,3 | Regime de lateralização já é coberto por Efficiency Ratio | Comparar só como possível substituto, nunca filtro obrigatório extra |
| EMA VWAP Trend Pro | 3,0 | Conceitos já abrangidos pelo VWAP e EMA Trend Pullback próprios | Não priorizar duplicata |
| Compilados EX4/EX5 sem fonte | não pontuado | Não permitem auditar lógica, repintura ou originalidade | Registrar referência sem executar nem redistribuir |

**As notas são julgamentos de engenharia, não avaliações de performance**, e podem mudar após análise do código original/implementação, quando acessível legalmente. O número de seguidores ou o preço comercial do indicador não demonstram vantagem estatística.

## Fontes adicionais verificadas
- [Envelope LuxAlgo](https://www.tradingview.com/script/Iko0E2kL-Nadaraya-Watson-Envelope-LuxAlgo/) — distingue modo **com repintura padrão** e modo sem repintura.
- [Nadaraya-Watson non repainting, Lupown](https://www.tradingview.com/script/YyeIcFNh-Nadaraya-Watson-non-repainting-LPWN/) — conceito de kernel não centrado.
- [Nadaraya-Watson unilateral, Gabremoku](https://www.tradingview.com/script/36PUbfjz-Nadaraya-Watson-Envelope-Gabremoku/) — suavização unilateral e MAD, sem dados posteriores.
- [3-Candle Mid-Body Signals](https://www.tradingview.com/script/HvQ4iqDX-3-Candle-Mid-Body-Price-Action-Signals-5-RR-Targets-Risk-Cal/) — divulgados em @simpleforextools.
- [Lista Telegram completa](INDICADORES_CANDIDATOS_2026-11-11.csv).

## Regra para guardar o que encontramos
- **Licença permitida (MIT etc.)**: guardar arquivos originais integrais, hash, licença e atribuição em `08_indicadores_originais/`.
- **Sem licença clara / pago republicado**: guardar referência, postagem, autor, descrição, detalhes observáveis, riscos e hipótese de uso; não subir o código original protegido ao GitHub público.
- **Quando útil**: implementar versão original com fórmulas públicas e testes do relógio de confirmação, em `03_projetos_proprios/`, sem se passar por clone idêntico do original.
- **Resultado financeiro**: não promover a "melhor" antes de ter evidência, validação no terminal, custos reais e testes fora da amostra.

**Atualização:** os oito indicadores originais nossos continuam preservados; os dois novos são **experimentos independentes**, ainda não fundidos no indicador principal.
