# Tino

Comprar bem começa antes.

Aplicativo brasileiro gratuito, de código aberto e sem anúncios. O MVP é
planejado para funcionar offline; consulte [o briefing](docs/BRIEFING_TECNICO.md)
e [o mapa de telas](docs/MAPA_DE_TELAS.md) para decisões e pendências.

## Etapa 1 — base visual e navegação

Implementado: tema claro, Plus Jakarta Sans incluída no aplicativo e ícones
Lucide outline; cinco áreas na ordem Início, Listas, Comprar, Histórico e Ajustes.
Comprar ocupa o centro da barra. Os atalhos do Início abrem Comprar e Listas.
Os recursos posteriores são indicados como indisponíveis, sem dados fictícios.

Organização por funcionalidades em `lib/features/`, composição e rotas em
`lib/app/`, tema e componentes compartilhados em `lib/core/`.
Riverpod gerencia o ciclo de vida do GoRouter; a seleção da barra deriva da rota,
sem manter outro estado de navegação. As outras áreas são rotas filhas do Início:
o botão/gesto Voltar retorna ao Início; no Início, permite sair do aplicativo.
Essa política de retorno é uma escolha de implementação desta etapa.

Ainda não implementados: scanner, cálculos, persistência de compras, edição de
listas, histórico de compras e preferências de ajustes, incluindo modo escuro.
Nenhuma permissão de câmera é solicitada nesta etapa.

## Etapa 2 — apresentação e primeiro acesso

Na primeira abertura, três telas apresentam o Tino, o acompanhamento da compra
e o orçamento. Deslize para a esquerda para avançar e para a direita para retornar,
ou toque nos três indicadores inferiores. “Pular” aparece nas duas primeiras
páginas e “Começar” somente na última. Concluir ou pular grava a preferência local
antes de abrir o Início. Nas próximas aberturas, o app vai direto ao Início.

Em Ajustes → Sobre o Tino, a apresentação pode ser revista. O ícone de fechar,
Voltar do Android, “Pular” e “Começar” retornam aos Ajustes durante essa revisão,
sem modificar a preferência. Nenhuma permissão ou login é solicitado.

A única persistência desta etapa é um booleano via `shared_preferences`.
Atualizações comuns preservam essa escolha; limpar os dados do app faz a
apresentação reaparecer. Não há banco de compras nem tratamento especial de
restauração de backup. Detalhes e roteiro em
[Apresentação e primeiro acesso](docs/ETAPA_2_APRESENTACAO.md).

## Desenvolvimento e validação

Para ver alterações Dart no celular ao salvar, inicie a depuração pelo VS Code
com **F5**, mantendo o Moto G54 conectado. Ative
`dart.flutterHotReloadOnSave: "allIfDirty"`; para arquivos salvos por ferramentas
externas, a extensão também oferece `dart.previewHotReloadOnSaveWatcher: true`.
As configurações locais de `.vscode/` não são versionadas neste projeto.

No terminal, mantenha `flutter run -d ZF524K6WC6` aberto e use `r` para hot reload
ou `R` para hot restart. `--no-resident` encerra a sessão e não permite esse ciclo.
Hot reload preserva o estado atual; mudanças em inicialização podem exigir hot
restart, e mudanças em dependências ou código nativo podem exigir nova compilação.
Referência: [hot reload do Flutter](https://docs.flutter.dev/tools/hot-reload).

Ambiente usado: Flutter 3.47.8 e Dart 3.13.7. Não requer emulador.

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter devices
flutter run -d ZF524K6WC6
```

No Moto G54 conectado por USB, com depuração autorizada:

1. Conclua ou pule a apresentação no primeiro acesso; confira o Início,
   tipografia, cores e ícones sem preenchimento.
2. Abra cada uma das cinco áreas. A selecionada deve ficar jade; Comprar deve
   permanecer no centro, com contorno fixo e sem alterar o desenho do ícone.
3. Nas outras áreas, use Voltar: deve aparecer o Início. Troque também entre
   áreas pela barra e confira os atalhos do Início para Comprar e Listas.
4. Confira rolagem, modo paisagem e tamanho de texto ampliado; a barra não deve
   cobrir conteúdo ou a navegação do Android.
5. Confira os avisos de indisponibilidade e ausência de compras, preços ou
   leituras inventados. A fonte deve continuar disponível sem internet.

A validação automatizada cobre abertura, ordem dos destinos, seleção acessível,
troca de áreas, retorno, atalhos e layout estreito com texto ampliado. Testes de
widgets não substituem a revisão visual e de gestos no aparelho.

Validação registrada ao concluir a etapa 1 (anterior à etapa 2):

- `dart format lib test`: arquivos Dart formatados.
- `flutter analyze`: sem problemas.
- `flutter test`: cinco testes aprovados.
- `flutter build apk --debug`: APK gerado.
- `flutter devices`: Moto G54 `ZF524K6WC6`, Android 15, conectado.
- `flutter run -d ZF524K6WC6 --no-resident`: compilado, instalado e iniciado.
- Via ADB: seleção das cinco áreas conferida pela árvore de acessibilidade;
  comando Voltar de Ajustes retornou ao Início. Interface revisada por capturas
  em retrato. Paisagem, gesto preditivo, TalkBack e texto ampliado no aparelho
  ainda precisam de revisão manual; texto ampliado foi coberto em widgets.

A fonte está em `assets/fonts/`, com licença SIL OFL e autoria no arquivo
`OFL.txt`, obtidas do repositório google/fonts, pasta `ofl/plusjakartasans`.
A licença do código do aplicativo continua pendente de definição.
