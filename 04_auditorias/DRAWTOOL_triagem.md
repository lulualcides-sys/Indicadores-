# Drawing Toolbox — triagem estática

**Arquivo:** `Drawing Toolbox.ex4` — compilado MetaTrader 4, 1.949.554 bytes. **Não executado.**

## Evidências reais
- Cabeçalho binário começa por `EX-`, compatível com arquivo EX4.
- Texto UTF-16 recuperável: `Copyright 2021, Jagg`, `based on 'Boxes and Lines.ex4'`, e `https://www.forexfactory.com/showthread.php?t=907317`.
- Referências a arquivos de alerta em `Sounds\...` (beeps, bell, click etc.). Não comprova disparo de sinais ou negociação.
- O nome e os textos internos apontam para **desenho de caixas e linhas** em gráficos; não há prova de lógica de entrada automatizada.

## Possíveis aplicações — não funcionalidades verificadas
- Interface para desenhar faixa de lateralização, suporte/resistência e zonas de rompimento/reteste no XAUUSD.
- As anotações não geram uma estratégia quantitativa automaticamente; idealmente implementar ferramentas visuais próprias, sem copiar binário de terceiros.

## Decisão
Manter na biblioteca original; prioridade baixa para extração de robô. Não classificar como lucrativo, nem descartado definitivamente.

## Limites e segurança
Código-fonte MQ4 indisponível. Não foi feita engenharia reversa, nem teste em MT4; binários não confiáveis devem ser avaliados apenas em ambiente isolado. Não é possível afirmar origem confiável ou ausência de malware com essa inspeção.

SHA-256: `6bfef06323bc035e930867a8987c2741ee2b497dd78fe91989ce2aee8226b4d6`