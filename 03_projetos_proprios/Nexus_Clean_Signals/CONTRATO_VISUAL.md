# Contrato visual — Nexus Clean Signals NR

Objetivo: permitir decisões legíveis em XAUUSD M1/M5/M15 **sem poluir o gráfico**, nem encobrir candles.

| Elemento | Padrão | Condição |
|---|---|---|
| Setas BUY / SELL | **Ativo** | Só após fechamento da vela que gerou o evento |
| Mini painel | **Ativo** | Uma linha com símbolo, modo, ER (contexto) e último sinal |
| TP1, TP2, TP3, SL, Entry | **Oculto** | Só em `NCS_LAST_PLAN`; apenas último sinal |
| Caixas FVG / OB | **Não existem** | São projetos independentes, não empilhar |
| Zonas S/R históricas | **Não existem** | Máximas/mínimas são cálculos internos |
| Alertas | **Desativados** | Opcional; uma vez por candle confirmado |
| COOL DOWN | 1 barra | Evita duas setas consecutivas sem bloquear muitos sinais |

## Critérios de aceitação visual
- Não sobrepor labels enormes; texto pequeno e neutro.
- Uma única seta para cada candle sinalizado, nunca seta provisória.
- Visual não altera cálculos; alternar `CLEAN` ↔ `LAST_PLAN` não pode alterar o histórico de setas.
- Níveis projetados ficam no **início do candle posterior** e são indicação hipotética, não preço de execução garantido.
- Sinais são eventos de estratégia — não conselhos financeiros ou odds de acerto.

## Comparação objetiva
Executar os três modos em mesmas janelas de XAUUSD, mesmos custos e mesma regra de preenchimento de ordem. Avaliar frequência, MDD, PF e expectativa líquida **fora da amostra**, e reportar também quantidade de sinais; não rejeitar modo apenas por sinais mais frequentes ou menor proporção de acerto.

## Evidência
Código e testes em `v1.00/`, `research/`, `tests/`. Até existir teste real no MetaEditor, não apresentar screenshot simulado como captura do indicador em funcionamento.
