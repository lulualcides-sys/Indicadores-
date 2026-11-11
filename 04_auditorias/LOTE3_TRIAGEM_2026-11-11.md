# Auditoria causal inicial — Lote 3 (21 fontes)

**Esta classificação é inspeção conceitual de código-fonte e documentação, não teste funcional ou backtest.** Não interpretar fonte aberta como prova de não repintura.

| Classe | Principais cuidados | Decisão inicial |
|---|---|---|
| MQL5 Sessions/SupplyDemand | Mudança de fuso, horário de servidor, pivôs que usam candles futuros e objetos retrospectivos | Úteis para validar níveis de sessão, **nunca** usar instante do pivô como instante da seta |
| MQL5 MTF RSI / Heikin Ashi | HTF corrente mutável e preço sintético suavizado | Contexto, não gatilho obrigatório |
| Pine CVD / DeltaPulse | Volume agressor estimado por proxy e sinais durante perna ainda aberta | Módulo **experimental** de pressão, somente quando o feed oferecer dados válidos |
| Pine Leg Delta Profile | Pivôs de perna e POC podem evoluir; dados de volume perfil necessitam conferir feed | Não apresentar dados como fluxo institucional sem identificação da fonte |
| Pine NW / LOESS / Kalman / Wavelet | Checar borda temporal: regressão simétrica e kernels centrados podem usar amostra posterior | Selecionar implementações unilaterais causais |
| Pine Hurst / Entropy / CHOP / PFE | Estimadores de regime podem variar com janela, warm-up e atrasar | Comparar **ablação** do melhor contexto, não somar todos como filtros |
| Pine Yang–Zhang Vol / VWAP bands | CFD tem horário/volume diferentes de ações/futuros; VWAP precisa de âncora ex-ante | Apenas contexto com condições de dados explícitas |

**Triagem automatizada adicional** estará disponível na execução da GitHub Action: scans por `request.security`, `barmerge.lookahead_on`, `ta.pivothigh/low`, `barstate.isconfirmed`, `offset=-N`, `WebRequest` e chamadas externas MQL5. Trata-se de indícios, não de atestado.

## Ordem de experimentação
1. **Zonas/sessões**: validar timestamp dos níveis e histórico de toques; comparar com Nexus Structure e Liquidity Sweep.
2. **Pressão/delta proxy**: testar se acrescenta informação sobre reversão sem inventar volume bid/ask.
3. **Hurst/CHOP**: comparar contexto de tendência com Efficiency Ratio já existente (um por vez).
4. **VWAP bandas + Kernel**: analisar diferença de entrada, latência e frequência sem sobrescrever o nosso Kernel causal.
5. **Backtest real MT5** somente com compilação e histórico da corretora, seguindo padrões aprovados pelo usuário.
