# Trend Wave Indicator — triagem estática

**Arquivo:** `Trend Wave Indicator For MT4 (2).ex4` — compilado MetaTrader 4, 17.332 bytes. **Não executado.**

## Evidências reais
- Cabeçalho `EX-` de executável compilado para MT4.
- Só foi possível recuperar uma URL redundante/anômala `https://t.me/https://t.me/FundedMillionAiress` em UTF-16. Isso **não** demonstra autoria, segurança nem características técnicas.
- Não foram encontrados fonte MQ4, fórmula legível, parâmetros do oscilador ou buffers de saída.

## Contexto externo — NÃO comprova identidade do arquivo
Páginas públicas descrevem indicadores com nome semelhante como osciladores de tendência/reversão e sinais coloridos. Não há correspondência de hash ou identidade comprovada com o arquivo recebido. Exemplos: https://jazibtrading.com/public/items/trend-wave-indicator-for-mt4 e https://www.keenbase-trading.com/products/trend-wave-indicator/ (outro produto, KT Trend Wave; não confundir).

## Hipóteses a testar em estratégia própria
1. Confirmar no MT4 se existem ondas osciladoras, cruzamentos e níveis de sobrevenda/sobrecompra.
2. Verificar se sinais surgem/alteram em candles fechados; procurar repaint e sinais deslocados retroativamente.
3. Caso confirmado, comparar gatilho de reversão e confirmação por tendência no ouro M1/M5/M15/M30.
4. Avaliar se aumenta performance **líquida fora da amostra** em relação à estratégia sem filtro.

## Decisão
Guardar como **candidato condicional**, sem regras extraídas diretamente do binário. Não integrar em robôs até obter MQ4 ou comportamento auditável em execução isolada.

SHA-256: `3617d9dfea2f44fdf3d476dbe586a8cf5b1dcf234de99ac29b44d9005af28710`