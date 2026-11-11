# Política permanente — NENHUM SINAL PODE REPINTAR

Obrigatória para todos os indicadores próprios, experimentos e integrações futuras.

## Invariantes
1. **BUY/SELL apenas após o fechamento** da vela de confirmação. No gráfico M1, a seta pode ser desenhada no candle anterior somente quando o próximo candle começar; o sinal não estava disponível antes.
2. Cálculos e filtros utilizam exclusivamente dados conhecidos até a confirmação. Nunca usar futuros, `lookahead_on`, `shift` que incorpore informações futuras ou extremos futuros de regressões centralizadas.
3. **Seta confirmada é imutável** durante novas cotações: não deslocar, esconder, excluir, recalcular ou reclassificar depois para remover sinais perdedores.
4. Os níveis desenhados não podem começar antes do momento em que ficaram conhecidos. Canal de abertura exige `N` candles fechados; TP/SL aparecem apenas com sinal confirmado.
5. `AGUARDANDO` é estado **provisório**, distinto de BUY/SELL confirmado; pode expirar/cancelar sem infringir a regra.
6. Alertas somente em novos sinais confirmados; evitar repetição a cada tick.
7. Em reimportação/correção de OHLC da corretora, histórico reconstruído pode mudar. Não chamar isso de garantia absoluta; registrar evento e comparar versões.
8. Indicadores com pivôs/ZigZag devem marcar apenas pivôs **confirmados causalmente**; nunca fingir que o último pivot provisório era conhecido antes.

## Testes obrigatórios
- **Prefixo temporal:** calcular sinais com prefixo de dados `D[:t]`, acrescentar dados futuros; todos sinais confirmados até `t` devem permanecer iguais.
- **Velas em formação:** alterar artificialmente OHLC do candle corrente; nenhuma seta histórica confirmada pode mudar.
- **Relógio de disponibilidade:** verificar que linha de canal, alvo e entrada não existiam antes da confirmação.
- **Reinicialização:** comparar sinais entre execução incremental e reconstrução histórica, explicando diferenças de correções dos dados.
- **MT5 real/demo:** observação com ticks em tempo real + recarga do gráfico + troca de ativo/período, antes de aprovar.

## Situação real H1 Vector Factor v1.20
15 testes Python/estáticos locais passaram em 11/11/2026; **a compilação no MetaEditor e os testes ao vivo ainda não foram realizados nesta migração**. Os testes não bastam para atestar comportamento sem repintura em todas as condições do terminal.
