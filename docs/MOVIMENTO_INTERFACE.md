# Movimento do tutorial e das cinco áreas

Refinamento restrito à apresentação e à navegação demonstrativa. Sem novas
dependências, permissões, dados simulados ou funcionalidades de compras.

## Tutorial

- Três páginas horizontais, acompanhando o dedo inclusive ao inverter o gesto.
  Bordas com clamping e encaixe amortecido, sem bounce ou efeito elástico.
- Indicadores tocáveis: transição de 300 ms, `easeOutCubic`; largura e cor
  interpoladas diretamente pela posição do `PageController` durante o arraste.
- Wordmark e textos entram uma vez por abertura: fade e deslocamento de 10 dp
  em 220 ms. Ao tocar/arrastar, a entrada termina imediatamente; não se soma
  uma segunda animação às páginas nem se repete a entrada em rebuilds.
- Sem Próximo/Voltar. Pular nas duas primeiras páginas, Começar na última.
  A dica desaparece após o primeiro avanço, mesmo ao retornar à primeira página.
- Controles aparecem/desaparecem em 180 ms, sem espera para habilitar o toque;
  controles ocultos não recebem toque nem aparecem na árvore de acessibilidade.
- A gravação local, o bloqueio enquanto salva, a mensagem de erro e a nova
  tentativa foram preservados. Revisão por Ajustes → Sobre o Tino mantém o
  retorno aos Ajustes e não regrava a preferência.

## Áreas e acessibilidade

- As cinco áreas usam ramos persistentes do `StatefulShellRoute`. A barra fica
  estável; a área selecionada entra com fade de 180 ms. Rolagem e navegadores
  são mantidos ao alternar áreas; tickers das áreas inativas ficam desabilitados.
- Cor ativa dos ícones/textos muda em 180 ms; os ícones continuam outline,
  sem troca de desenho ou espessura. Voltar do Android retorna ao Início.
- `MediaQuery.disableAnimations` remove entrada, fades e deslocamento por toque.
  O arraste continua direto, acompanhando o dedo. Não há animações contínuas.
- Rótulos, seleção dos indicadores, alvos de toque e exclusão semântica de
  páginas inativas foram mantidos. Texto ampliado continua com rolagem.
- Durante o arraste, só os pequenos indicadores observam a posição por frame;
  o conteúdo das páginas não é reconstruído por essa animação.

## Validação

- Formatação Dart, `flutter analyze` sem problemas e `flutter test`: 24 testes
  aprovados. Incluem persistência/erros, revisão, texto ampliado, reversão e
  cancelamento do arraste, bordas, interpolação, entrada única, toques rápidos,
  movimento reduzido, barra estável, preservação da rolagem entre áreas e saída
  da revisão com toques duplicados.
- APK profile compilado e instalado no Moto G54 5G (`ZF524K6WC6`, Android 15).
  Após o desbloqueio, a validação foi retomada com a mesma compilação, sem
  alterações Dart nem repetição desnecessária de análise/testes.
- No aparelho, via ADB: avanço/retorno e arraste parcial, indicadores, dica que
  não reaparece ao retornar à primeira página, Pular e Começar voltando aos
  Ajustes; saída pelo ícone de fechar e pelo Voltar do Android. As cinco áreas
  foram alternadas, inclusive rapidamente. Capturas e árvore de acessibilidade
  confirmaram os estados finais; os gestos automatizados não substituem a
  avaliação tátil nem a leitura falada com TalkBack.
- A fala e o foco reais do TalkBack precisam de revisão manual. Testes de
  widgets não substituem essa verificação.

### Medição em profile no Moto G54

Timeline do Dart VM Service, streams `Dart` e `Embedder`, com durações dos pares
de eventos `Frame` (UI) e `Rasterizer::DoDraw` (raster), em milissegundos.
Sem usar debug como evidência de desempenho. As amostras controladas coletam
somente uma sequência curta por vez para evitar perda pelo buffer da timeline.

| Amostra | Pares UI/raster | UI p95 | Raster p95 | Raster máximo | Raster > 8,33 ms / > 16,67 ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Tutorial, amostra inicial | 158/158 | 3,91 | 8,38 | 35,67 | 8 / 1 |
| Tutorial, repetição controlada 1 | 175/175 | 2,19 | 7,52 | 9,78 | 5 / 0 |
| Tutorial, repetição controlada 2 | 164/164 | 2,53 | 7,69 | 11,76 | 2 / 0 |
| Cinco áreas, sequência controlada | 57/57 | 1,26 | 4,30 | 5,67 | 0 / 0 |

No tutorial controlado: deslize de ida e volta e salto pelo indicador da última
página. Nas áreas: Início → Listas → Comprar → Histórico → Ajustes, com 220 ms
entre os comandos de toque. São amostras pequenas do aplicativo já aberto.
O pico inicial de 35,67 ms não reapareceu nessas duas repetições; a causa não foi
determinada. Há frames acima do orçamento de 8,33 ms no tutorial, portanto não
se afirma 120 fps constantes nem ausência de engasgos em todas as condições.
Também não se mediu latência completa entre toque e apresentação na tela.

O log do motor registrou três mensagens `Reported frame time is older than
the last one; clamping`. Não foram observadas exceções Dart nesse log nem
encerramento do app durante a validação. A origem dos avisos não foi investigada
neste recorte; nenhuma versão de Flutter/Android foi alterada para ocultá-los.
Capturas, traces e auxiliares de medição ficam em `build/`, fora do Git.

Para repetir a avaliação, desbloqueie o aparelho e execute:

```powershell
$env:FLUTTER_WINDOWS='false'
flutter devices
flutter run --profile -d ZF524K6WC6
```

Em Ajustes → Sobre o Tino, arraste parcialmente e inverta/cancele; avance e
retorne rapidamente; toque nos indicadores; confira Pular/Começar e o retorno
aos Ajustes. Alterne as cinco áreas e confira barra, cores e rolagem preservada.
No DevTools, grave a timeline em Performance; examine frames de UI e raster
separadamente, repetindo as interações após o primeiro uso. Não use debug como
evidência de desempenho. Teste também a opção de remover animações e o TalkBack
do Android; restaure as preferências de acessibilidade após a avaliação.
