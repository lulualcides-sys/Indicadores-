# Segunda pesquisa do Telegram — 11 de novembro de 2026

Objetivo: continuar o garimpo de originais para construir o melhor indicador Nexus possível sem duplicar fontes já arquivadas.

RESULTADO: 23 novos candidatos com páginas públicas verificadas, 8 P1. Esta etapa reuniu LINKS E NOMES, e não os bytes dos anexos.

## Melhores hipóteses técnicas

| Candidato | Canal | Potencial para o Nexus | Cautela |
|---|---|---|---|
| Sensible Guide Confluence | [mt4indicatorfree](https://t.me/s/mt4indicatorfree?before=97149) | Dados MTF H4/D1/W1 apenas de candles fechados | Checar código e pivôs confirmados; não compilado |
| Breakout Retest Pro v2 | [mt4indicatorfree](https://t.me/s/mt4indicatorfree?before=97149) | Rompimento → reteste → expiração e reversão | É EA, não indicador; não executar ordens |
| Modern VSA GBB | [mt4indicatorfree](https://t.me/s/mt4indicatorfree?before=97149) | Spring/upthrust em extremos com volume relativo | Sem fonte; estatística ES/NQ anunciada não foi auditada |
| i-Sessions | [mt4indicatorsfree2024](https://t.me/s/mt4indicatorsfree2024) | Faixas Ásia Londres NY e níveis | Ajustar fuso de servidor e DST |
| Turtle Body Soup | [mt4indicatorfree](https://t.me/s/mt4indicatorfree?before=87267) | Falso rompimento Turtle Soup e reentrada confirmada | Não usar máxima/mínima futura; fechar vela antes da seta |
| Liquidity Sweep Sequence | [mt4indicatorfree](https://t.me/s/mt4indicatorfree?before=87267) | Sequência sweep → estrutura → reteste | Pivôs e rótulos podem ser retrodatados |
| Volatility FBA NR | [zlfxs](https://t.me/s/zlfxs?before=98) | Regime de volatilidade e falso rompimento | NR no nome não comprova ausência de repaint |
| Sessões e Killzones MQL5dev | [mql5dev](https://t.me/s/mql5dev/4428) | Sessão Ásia/Londres/NY, sweeps, média de range | Sem fonte anexada e requer histórico M1 para precisão |

## Canais e fontes efetivamente visitados

- MT4 Indicator Free: https://t.me/s/mt4indicatorfree?before=97149 (Sensible Guide H1, Breakout Retest Pro, Modern VSA)
- MT4 Indicator Free: https://t.me/s/mt4indicatorfree/9723 (Laguerre RSI e ADXm)
- MT4 Indicator Free: https://t.me/s/mt4indicatorfree?before=87267 (Turtle Body Soup, Liquidity Sweep Sequence)
- MT4 Indicator Free: https://t.me/s/mt4indicatorfree?before=82015 (Triple Supertrend, heatmap de liquidez, outros)
- ZlfxSha: https://t.me/s/zlfxs?before=98 (volatility fba nr.mq5, Volatility2, Consecutive Candles)
- SmartMQL Telegram: https://t.me/s/mt4indicatorsfree2024 (i-Sessions.mq4 e outros originais MQ4)
- Simple Forex Tools: https://t.me/s/simpleforextools?before=19480 (CodePro .mq5 e conteúdo promocional)
- MQL5 Algo Trading: https://t.me/s/mql5dev/4428 (pesquisa de sessões, killzones e estatísticas)
- Indicadoresgratis: https://t.me/s/indicadoresgratis/31348 (revisto; Breakout Lines e AIMS AO já catalogados, sem duplicar)

## Recomendação para extração

1. Sensible Guide: confirmar HTF com o último H4, D1 e W1 fechados no instante do candle analisado, sem future leak.
2. Turtle Body Soup: range existente, varredura e fechamento de volta. Uma seta só após confirmação.
3. Modern VSA: testar Spring/Upthrust por pavio, corpo e volume relativo sem afirmar volume agressor de ouro spot.
4. i-Sessions e MQL5dev: reconstruir sessões fechadas com fuso correto, incluindo DST e overnight.
5. Laguerre RSI, ADXm e Volatility FBA: comparar contra filtros que já existem para evitar reduzir operações inutilmente.

## Integridade e limitações

- A página pública do Telegram apresenta o nome dos anexos, mas o navegador disponível não forneceu os arquivos brutos para armazenamento.
- Uma tentativa de usar automação de navegador TinyFish foi BLOQUEADA por falta de saldo. Não foi cobrado novo valor, nem feito download.
- Arquivos EX5 são binários compilados; não executá-los nem afirmar que podemos inspecionar seu funcionamento interno.
- O título Premium/Non-Repaint/IA é publicidade ou alegação, não evidência. Parte do conteúdo é EA, não indicador.
- Não modificar qualquer fonte existente em 08_indicadores_originais, nem os dez Nexus MT5.
- A autorização informada pelo usuário para manter materiais não substitui a verificação de direitos quando houver código de terceiros para republicação.

## Entrega

- CSV com nomes, formatos, páginas do Telegram, hipóteses técnicas, prioridade, riscos e status do download.
- Esta curadoria está disponível no repositório público; **nenhum .mq4/.mq5 novo do Telegram foi incorporado nesta rodada**.
- Próxima etapa requer acesso real aos bytes para calcular hash, auditar código e avaliar o mérito técnico no MT5.

[Catálogo do lote](NOVOS_CANDIDATOS_2026-11-11.csv) | [Catálogo anterior](INDICADORES_CANDIDATOS_2026-11-11.csv)
