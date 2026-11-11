# WyckoffFullSuite v3.1 — triagem estática

**Arquivo:** `WyckoffFullSuite_v3.1.ex5` — compilado MetaTrader 5, 124.348 bytes. **Não executado.**

## Evidências reais
- Cabeçalho `EX5`, compatível com programa MQL5 compilado.
- Texto legível contém `eafree.net` e `https://eafree.net`; não comprova autoria nem integridade.
- Nome do arquivo diz “Wyckoff Full Suite v3.1”, mas **o conteúdo não revela** critérios para fases, volume, spring, upthrust, sinais, filtros ou saídas.
- Encontram-se referências online ao mesmo nome como indicador MT5, porém sem equivalência criptográfica verificável ao arquivo recebido.

## Hipóteses de extração independente — NÃO recursos confirmados do binário
- Mapear zonas de acumulação/distribuição quantitativamente.
- Testar falsa ruptura e retorno ao range (spring/upthrust) como entrada de price action.
- Confrontar volume/tick volume e localização de fechamento (spread do candle) como hipótese de confirmação, considerando diferenças de dados spot XAUUSD entre corretoras.
- Gerar eventos com timing explícito de candles confirmados para impedir lookahead.

## Decisão
Promissor **como família de ideias**, sem alegar que essas regras existam no EX5 recebido. Validar em estudo próprio antes de incorporar qualquer componente a M1/M5/M15/M30.

## Segurança
Origem e segurança não podem ser confirmadas por strings ou hash. Não executar em terminal conectado a conta real e não ativar DLLs/URLs desconhecidas.

SHA-256: `29013d7021dd8538a8dc4d62bcf090ccf805fef73a4b9cac7de0c7ac6e32994c`