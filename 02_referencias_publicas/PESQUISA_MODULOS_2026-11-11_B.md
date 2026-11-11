# Pesquisa: novos módulos candidatos — 11/11/2026

## Seleção baseada em fontes públicas e gratuitas

| Fonte | Acesso verificado | Potencial técnico | Limitações |
|---|---|---|---|
| [Session Levels (CodeBase)](https://www.mql5.com/en/code/78045) | Código .mq5 visível, gratuito | máxima/mínima de sessão, PDH/PDL, VWAP | atenção a fuso do servidor e pivot confirmado |
| [Market Structure BOS/CHoCH (CodeBase)](https://www.mql5.com/en/code/78551) | Código .mq5 visível, gratuito | pivôs e ruptura por fechamento | swing precisa de N velas à direita; atraso legítimo |
| [Market Structure SMC (CodeBase)](https://www.mql5.com/en/code/74575) | Código .mq5 visível | swings, OB e FVG | sinais históricos precisam de relógio de confirmação |
| [AI Relative Volume](https://www.mql5.com/en/market/product/202646) | Produto gratuito | RVOL em candles fechados | código-fonte não estabelecido |
| [VWAP by Professionals](https://www.mql5.com/en/market/product/180996) | Produto gratuito | VWAP sessão + bandas | código-fonte não estabelecido |
| [MelloVWAP/Volume Profile](https://www.mql5.com/en/market/product/206763) | Produto gratuito | VWAP, POC/VAH/VAL | código-fonte não estabelecido |
| [The Trader Structure](https://www.mql5.com/en/market/product/207308) | Produto gratuito | zonas de oferta/demanda e BOS | licenciamento e comportamento em tempo real não auditados |
| [SessionBands](https://www.mql5.com/en/market/product/206709) | Produto gratuito | faixas por sessão e estado relativo | faixas durante sessão ainda se expandem; não confundir com sinais estáveis |

## Telegram público
- [@freeindicatores](https://t.me/s/freeindicatores?before=3560): **Buyers Sellers Profile** e **Apex Engine** (TXT); precisam de licença/inspeção de código antes de integração.
- [@freeindicatores](https://t.me/s/freeindicatores?before=2557): **Specter Trend**, **DeltaFlow** e estudo **MNQ**; indicador de futuros não deve ter resultados transferidos ao ouro sem validação.
- [@freemt5indicators](https://t.me/s/freemt5indicators): Awesome Oscillator Divergence e T3 em MQ5; o canal declara restrição de venda e redistribuição comercial.
- [@mt4indicatorfree](https://t.me/s/mt4indicatorfree?before=76180): VWAP Periodic Close em EX5, sem fonte verificada; **não executar** arquivos desconhecidos.

## Decisão prática
- Construir `Nexus_Session_VWAP` com preços e pesos dos **candles fechados** e RVOL contextual, sem usar códigos de terceiros.
- Construir módulo independente de **pivôs confirmados e rompimento de estrutura**, sem atribuir retroativamente ao candle do pivô um sinal conhecido apenas N candles depois.
- Não incorporar toda pesquisa ao H1, Sweep ou FVG: medir cada módulo isoladamente antes de experimentar confluência.
- **Sem lucro ou backtest financeiro alegado**.
