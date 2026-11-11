# H1 Vector Factor NR v1.30 — melhoria SEM regressão

**v1.20 não foi alterada**. O objetivo da v1.30 é melhorar a instrumentação e permitir comparação A/B, não inventar lucratividade.

## Duas opções novas, DESLIGADAS por padrão
- `InpMaxSpreadATR = 0.00`: opcional. Se maior que 0, bloqueia candidatos com `spread[i] × _Point > InpMaxSpreadATR × PreviousATR(i)`. Spread de candle histórico é fornecido pelo broker, e pode não representar o preço realmente executável.
- `InpDirectionalBodyGate = 0.00`: opcional. Se maior que 0, exige que a força relativa do corpo da **vela de rompimento fechada** seja compatível com o lado do sinal: `direcao × (close-open)/(high-low) >= limiar`.

As duas variáveis usam apenas dados disponíveis no fechamento do candle, não aplicam filtros de forma compulsória e **não alteram o comportamento padrão de sinais da versão 1.20**.

## Critérios de qualidade
- A v1.20 permanece disponível para rollback e comparação.
- Testes estáticos foram adicionados, mas só o MetaEditor pode comprovar compilação; teste incremental MT5 é necessário para verificar não repintura real.
- Antes de habilitar filtros, comparar a frequência e o desempenho líquido v1.20 x v1.30 em XAUUSD M1, mantendo custos e divisão de amostras iguais.
