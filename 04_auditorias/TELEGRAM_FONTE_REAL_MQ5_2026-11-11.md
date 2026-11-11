# Auditoria estática inicial — quatro fontes MQL5 reais, descobertas pelo Telegram

Fonte de pesquisa: https://t.me/s/ShepherdFxTradingTools, que divulgou https://ultimatetrading.tools/ como site de download de códigos.

**Verificado em GitHub Actions:** quatro arquivos `.mq5` obtidos efetivamente por ZIP HTTP e arquivados na pasta [12_utt_telegram_sources](../08_indicadores_originais/12_utt_telegram_sources/README.md). O manifesto fornece SHA-256 de ZIP e de arquivo; não houve execução das fontes.

| Código | Fonte original creditada | Licença citada pelo publicador | Uso potencial no Nexus | Flags estáticas de MQL5 |
|---|---|---|---|---|
| BuyersSellersProfile_DynamicSR_Deriv.mq5 | Zeiierman | CC BY-NC-SA 4.0 | Perfil de preços, POC, VAH/VAL, zonas com retestes HELD/BROKEN | 8 referências a SetIndexBuffer; 1 CopyBuffer; nenhuma OrderSend/WebRequest/#import detectada |
| Liquidity_Entry_Signals.mq5 | MarkitTick | CC BY-NC-SA 4.0 | Sweep fechado, stops por ATR, bias de H4 confirmado | 2 SetIndexBuffer; 6 CopyBuffer; 0 OrderSend/WebRequest/#import detectadas |
| UTT_WickSequenceBreakout.mq5 | Uncle_the_shooter | MPL-2.0 | clusters de rejeição + fechamento fora de caixa | 19 SetIndexBuffer; 0 CopyBuffer; 0 OrderSend/WebRequest/#import detectadas |
| UTT_AdaptiveMarketIntelligence.mq5 | InvestyourAsset | MPL-2.0 | contexto de regime e confluência sem exigir filtros cumulativos | 31 SetIndexBuffer; 0 CopyBuffer; 0 OrderSend/WebRequest/#import detectadas |

**Observação:** contagens são ocorrências textuais e não equivalem a validação de segurança, implementação, qualidade ou documentação das saídas. Ausência de `OrderSend` não significa análise de segurança completa.

## Conclusões para o NOSSO indicador

1. **Prioridade P1: Dynamic S/R**. Testar a vida útil de cada nível com relógio causal e contagem de toques conhecidos no instante do sinal; usar perfil apenas quando o dado do broker for adequado. Preocupação: volume tick do CFD XAUUSD é atividade do broker, não volume global de compradores e vendedores.
2. **Prioridade P1: Liquidity Entry Signals**. Comparar a qualidade de sweep e o contexto do último H4 totalmente fechado com a biblioteca Nexus Liquidity Sweep existente. Não acrescentar filtro obrigatório sem ablação.
3. **Prioridade P1: Wick Sequence**. Testar se a persistência de rejeição por pavio acrescenta vantagem a breakout simples; separar volume proxy de volume agressor verdadeiro.
4. **Prioridade P2: Adaptive Market Intelligence**. Medir impacto de seis fatores na frequência. O score 0–100 é pontuação heurística e NÃO uma chance de acerto validada. Não copiar a interface volumosa.

## Pendências obrigatórias

- Inspecionar integralmente os fluxos de atualização de cada fonte, incluindo buffers, pivôs e HTF: esta análise não atesta não-repaint.
- Compilar individualmente no MetaEditor MT5; corrigir apenas cópias experimentais, preservando originais e licenças.
- Testar comportamentos em ticks e comparação incremental x recálculo completo.
- Avaliar em XAUUSD M1/M5/M30/H1 com spreads reais e custos do broker, sem alegar lucros antes de evidência.
- Respeitar CC BY-NC-SA no uso e redistribuição não comerciais e manter os avisos MPL-2.0.

[Manifesto](../08_indicadores_originais/12_utt_telegram_sources/manifesto_downloads.json) · [Produtos publicados](../09_pesquisa_telegram/ORIGINAIS_COM_DOWNLOAD_DIRETO_2026-11-11.md)
