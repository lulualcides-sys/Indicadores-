# Telegram — garimpo técnico de indicadores (11/11/2026)

## Objetivo
Formar nossa **biblioteca de indicadores externos reais e auditáveis** antes de evoluir o **único Nexus Clean Signals** para MT5. Os links são evidências de posts públicos e de scripts originais; são **metadados de pesquisa**, não downloads executados nem validação de desempenho.

Nesta rodada foram catalogados **17 canais/grupos** (inclusive os cinco indicados pelo usuário) e **28 candidatos/entradas**; um item sobre ZULU é duplicado propositalmente como contexto de pesquisa e **não deve contar como indicador distinto**. Candidatos com nomes sem descrição técnica suficiente ficaram fora da shortlist.

## Prioridade P1 — padrões que complementam o arsenal atual
| Candidato | Origem | Papel no nosso indicador | Risco a revisar |
|---|---|---|---|
| Strong Recovery Zones | [simpleforextools](https://t.me/s/simpleforextools) | Zonas e desfechos HELD/STALLED/BROKEN | Resultados de Monte Carlo anunciados pelo canal não auditados; fonte original não obtida |
| Liquidity Pools Pro | [WillyAlgoTrader](https://t.me/s/WillyAlgoTrader?after=408) | EQH/EQL e sweep com retorno por fechamento | HTF e pivôs confirmados exigem auditoria |
| Smart Money Engine | [WillyAlgoTrader](https://www.tradingview.com/script/9wnWcxkQ-smart-money-engine-willyalgotrader/) | Reteste OB/FVG, sweep, origem dos eventos | Separar confirmação por fechamento da modalidade toque imediato |
| Breakout Lines + TP/SL | [indicadoresgratis](https://www.tradingview.com/script/X6Oq0kuQ-Breakout-Lines-TP-SL/) | Linhas por dois pivôs confirmados e rompimento, stop ATR | Pivot Right gera latência; script aberto não autoriza republicação automática |
| Nadaraya Watson Envelope NR | [mt4indicatorfree](https://t.me/s/mt4indicatorfree?before=89222) | Envelope kernel causal para volatilidade | Regressão simétrica costuma usar futuro: conferir implementação de fato causal |
| Choppy Market Index | [indicatorsforfree](https://t.me/s/indicatorsforfree) | Classificar mercado lateral ou direcional | Somente ideia; usar fórmula causal autoral, não binário |
| Almazov Trade Opening Range | [freeindicatores](https://t.me/s/freeindicatores?before=3601) | ORB NY com janela completa e timezone DST | Interessante para validar janela completa; XAU sessões diferentes de ações NY |
| Order Flow / VWAP / POC / LVN | [akorderflow](https://t.me/s/akorderflow) | Contexto futuros GC e aceitação/rejeição em nível | GC COMEX ≠ volume tick da corretora XAUUSD; dados externos necessários |

**Ranking é prioridade de pesquisa, NÃO ranking financeiro.** Foram priorizados conceito único, disponibilidade de fonte, facilidade de tornar causal e relevância XAUUSD; não alegamos taxa de acerto.

## Fontes com anexos visíveis, mas direitos de reutilização NÃO demonstrados
- [@FreeMT4Indicators](https://t.me/s/FreeMT4Indicators): `Nadaraya_Watson.mq5`, `TDFI.mq4`, `ATR_Bands.mq4`. O próprio canal avisa que os arquivos são gratuitos e não devem ser redistribuídos comercialmente. Não os copiei.
- [@mt4indicatorfree](https://t.me/s/mt4indicatorfree?before=89222): `Nadaraya_Watson_Envelope_NR.mq5`. Versão se diz sem repintura; é necessário verificar se o kernel só usa velas anteriores.
- [@mt4indicatorfree](https://t.me/s/mt4indicatorfree?before=82015): `ZULU_Advanced_SMC V4.mq5`; a presença de fonte não demonstra licença para espelhar/publicar.
- [@scalpingeasy](https://t.me/s/scalpingeasy?before=3023): `stepma_v634.mq5`; autor e licença não confirmados.
- [@indicadoresgratis](https://t.me/s/indicadoresgratis?before=31376): `AIMS AO V2.1.mq4` e outros `.ex4/.ex5`; materiais proprietários e EAs potencialmente de terceiros.
- [TradingView / autor original](https://www.tradingview.com/script/X6Oq0kuQ-Breakout-Lines-TP-SL/): Breakout Lines TP/SL publicado como open-source, com aviso de que republicação está sujeita às regras da plataforma. Armazenado **somente o link**.

## Canais solicitados pelo usuário
- `@simpleforextools`: **acessível**, publicações sobre Strong Recovery Zones e 3-Candle Mid-Body; alguns posts contêm propaganda de corretora/EA e garantias não verificáveis.
- `@indicadoresgratis`: **acessível**, scripts e executáveis MT4/MT5; observar licença e origem.
- `@RocktradersPublic`: **acessível**, muitos bots EX5/EX4 e vídeos de backtests; **baixa prioridade** como fonte para um indicador original.
- `@INFOREXINDICATORS` e `@fxstrategiesresources`: páginas não ficaram acessíveis no navegador público. **Não afirmar inspeção dos posts privados nem fazer download sem acesso**.

## Cuidados com material “pago liberado grátis”
1. **Gratuidade de um grupo não comprova licença**. Material premium que foi republicado sem autorização **não será copiado nem espelhado** no GitHub.
2. `.ex4`/`.ex5` não fornecem fonte aberta auditável. Não executar binários desconhecidos nem tentar descompilar material protegido.
3. `.rar`/`.zip` podem conter executáveis e dependências não confiáveis; não instalar software apenas por aparecer em canal.
4. Para Pine de terceiros, conferir autor, página original e **regras de republicação do TradingView**. Para MQL5 CodeBase, revisar licenças.
5. Sinais anunciados como **NO REPAINT**, **95% acerto** ou **IA institucional** são **alegações**, nunca provas. Nosso padrão exige teste de prefixo temporal + tick/livre de future leak.
6. Em MT5, venda/compra deve ocorrer **após candle fechado** e o testador só deve usar o próximo tick disponível. Volumes de XAUUSD spot/CFD são dependentes da corretora.

## O que melhoraria o NOSSO indicador — e o que NÃO vale empilhar
**Hipóteses novas de maior utilidade técnica:**
- **Rastreio da evolução de zonas:** cada nível inicia com momento de formação; registrar TOUCHED, HELD, BROKEN, STALLED e janela temporal. Não retrocalcular histórico com resultado futuro.
- **Níveis importantes antes do sinal:** S/R via pivôs confirmados, EQH/EQL, ORB NY com sessão completa e DST correto; sem mostrar todas as caixas no gráfico.
- **Qualidade dos rompimentos:** corpo direcional, distância em ATR e fechamento contra resistência/suporte que já existia.
- **Validação de reversão:** sweep → rejeição → entrada com confirmação temporal, sem obrigar CHoCH + 5 indicadores extras.
- **Contexto de futuros (opcional):** POC/VWAP do ouro GC somente com fonte de futuros real. Não inferir fluxo institucional do volume tick XAUUSD.

**Não copiar agora:** softwares pagos vazados, Sema3 com pivôs mutáveis, regressão Nadaraya-Watson com janela simétrica, “IA de sucesso garantido”, dezenas de dashboards e 12 filtros obrigatórios.

## Próximas etapas controladas
1. Para cada candidato P1, tentar localizar a **versão publicada pelo autor** e licença clara.
2. Se licença permite, copiar original integral em `08_indicadores_originais` com hash, autoria e licença.
3. Auditar a temporização do sinal e documentar discrepâncias. Só módulos autorais causais vão para `05_extracoes_experimentais`.
4. Rodar teste sintético e, quando possível, MT5 real; experimentar **um componente por vez** no Nexus Clean Signals.
5. Preservar **os oito indicadores MT5 e a biblioteca MIT anterior**, sem alterá-los para inflar contagem.

[CSV de canais](CANAIS_PUBLICOS_2026-11-11.csv) · [CSV completo de candidatos](INDICADORES_CANDIDATOS_2026-11-11.csv)

**Limitação:** o navegador público não acessa mensagens privadas, pode não carregar arquivos do Telegram e não confirmou as licenças. Esta rodada **não baixou nem executou anexos**, não copiou código pago e não produziu novos resultados financeiros.
