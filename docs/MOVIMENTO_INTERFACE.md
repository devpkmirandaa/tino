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
  A avaliação das interações/fluidez ficou bloqueada pela tela de bloqueio do
  aparelho. Não foi feita medição válida de frames nem afirmado desempenho
  a partir de debug; a validação em profile permanece pendente.
- A fala e o foco reais do TalkBack precisam de revisão manual. Testes de
  widgets não substituem essa verificação nem comprovam fluidez no aparelho.

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
