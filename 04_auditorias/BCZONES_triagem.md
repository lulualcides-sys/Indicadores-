# Support & Resistance BC Zones.ex5 — triagem estática

**Tipo:** arquivo compilado MT5 EX5 (50.838 bytes). Cabeçalho inicia por `EX5`. **Não executado.**

## Evidências recuperáveis
- Nome do arquivo sugere indicador de zonas de suporte/resistência, mas a forma de detectar, atualizar e remover essas zonas **não pode ser recuperada de maneira confiável** do binário.
- Encontradas strings UTF-16 legíveis `Copyright 2019 SVD (sergvd@yandex.ru), -mod by Stash` e `https://t.me/shista2010`. São metadados presentes no arquivo, **não comprovação de autoria, licença ou integridade**.
- Não foi encontrado código-fonte MQ5, fórmulas dos níveis, buffers de sinal, critérios de desenho, confirmações de candle, lógica anti-repaint ou execução de trades.

## Ideias para estudo independente — NÃO confirmadas como funções do EX5
- Identificar zonas a partir de pivôs confirmados, clusters de toques e deslocamento de preço em múltiplos de ATR.
- Testar reação no reteste ou rompimento seguido de reteste para XAUUSD, com registro do instante exato em que cada zona ficou conhecida, para evitar viés de antecipação.
- Medir taxa de ruptura e invalidação da zona, tempo de vida, largura normalizada pelo ATR e densidade de retestes.
- Confrontar o valor adicional das zonas com estratégia base sem zonas (ablação), nos quatro períodos M1, M5, M15 e M30.

## Status
**Candidato conceitual — precisa de evidência de funcionamento no MT5 ou do fonte MQ5.** Não é possível afirmar que o binário de fato implementa qualquer uma das hipóteses. Nenhuma estratégia aprovada, nenhuma execução/backtest.

## Segurança
Não executar EX5 desconhecido em conta real ou terminal com permissões sensíveis. Se necessário testar, usar MT5 isolado, sem credenciais reais e sem DLLs ou WebRequest liberados; obter origem confiável e preservar hash SHA-256.