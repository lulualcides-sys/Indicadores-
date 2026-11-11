# Nexus Causal Kernel Reclaim NR — versão experimental 1.00

**Implementação independente** das ideias matemáticas de envelopes Nadaraya–Watson **causais**. Não foi copiado nenhum código pago, sem licença ou de terceiros. Respeita a prioridade do projeto: original separado, fonte auditável e possibilidade de extração para o único indicador final.

## Entrada sem repintar
- Estimativa do preço por **kernel gaussiano unilateral**: cada candle utiliza seus próprios preços fechados e **somente candles mais antigos**.
- Banda superior/inferior baseada em desvio médio absoluto (MAD) ponderado e piso por ATR anterior.
- BUY após um fechamento anterior **abaixo** da banda inferior anterior seguido de **fechamento confirmado acima** da banda inferior atual, com corpo comprador.
- SELL simétrico na banda superior.
- Setas discretas em **buffers 0 e 1**; não desenha dezenas de linhas no modo padrão. Sem execução de ordens.
- Parâmetros originais (40 candles, largura 9, multiplicador 2) são **hipóteses**; não são ótimos validados.

## Distinção crítica
Os envelopes Nadaraya–Watson **centrados** podem usar informações posteriores para recalcular marcadores históricos. Esta versão é unilateral e não acessa dados futuros; por isso pode diferir muito de versões premium ou screenshots de anúncios. Não chamar de cópia fiel.

## Referências conceituais
- [Nadaraya–Watson Envelope, LuxAlgo](https://www.tradingview.com/script/Iko0E2kL-Nadaraya-Watson-Envelope-LuxAlgo/) — o autor alerta que **o modo padrão pode repintar**; há modo alternativo não repintante.
- [Nadaraya-Watson non repainting, Lupown](https://www.tradingview.com/script/YyeIcFNh-Nadaraya-Watson-non-repainting-LPWN/)
- [Nadaraya-Watson Envelope unilateral, Gabremoku](https://www.tradingview.com/script/36PUbfjz-Nadaraya-Watson-Envelope-Gabremoku/)
- Anúncio de `.mq5` em canal Telegram sem licença verificada (apenas referência): `@mt4indicatorfree` (ver catálogo).

**Pendências:** MetaEditor/compilação MQL5, dados do broker XAUUSD, testes em ticks, comparação de prefixos real, backtests MT5 com custos. Os testes Python comprovam apenas propriedades de código/modelo.
