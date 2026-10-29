# Etapa 2 — apresentação e primeiro acesso

Recorte solicitado pelo usuário: apresentação inicial e uma preferência local,
sem antecipar banco de compras, câmera, permissões ou login.

## Comportamento implementado

- Três telas curtas: conhecer o Tino, acompanhar a compra e controlar o orçamento.
  Os textos foram escritos nesta implementação; não são textos recuperados do
  briefing. Recursos ainda indisponíveis são identificados como em preparação.
- Reutiliza `AreaPage`, tema claro, fonte local, botões outline e Lucide da etapa 1.
- “Pular” está disponível nas três telas, “Próximo” nas duas primeiras e “Começar”
  na última. A barra das cinco áreas só aparece após sair da apresentação.
- Concluir e pular aguardam a gravação antes de abrir o Início. Durante a gravação,
  os controles são desabilitados para evitar ações duplicadas. Se falhar, a tela
  informa o erro e permite tentar novamente.
- A abertura aguarda a leitura da preferência, sem mostrar o Início por um
  instante. Falha de leitura oferece nova tentativa, sem presumir primeiro acesso.
- Se a apresentação for interrompida antes de concluir/pular, ela reaparece desde
  a primeira tela na próxima abertura. No primeiro acesso, Voltar nas telas 2 e 3
  retorna à anterior; na tela 1 permite sair do app sem marcar como vista.
- Ajustes → Sobre o Tino abre a mesma apresentação em modo de revisão.
  “Voltar aos Ajustes”, Voltar do Android, “Pular” ou “Começar” encerram a revisão
  nos Ajustes. Rever não apaga nem regrava a escolha de primeiro acesso.

## Marca no aplicativo

Os logos textuais das telas foram substituídos pelo asset fornecido pelo usuário,
`assets/branding/tino-wordmark.svg`, registrado no `pubspec.yaml` e renderizado
por `flutter_svg` 2.3.2. O componente compartilhado `TinoWordmark` é usado no Início,
Listas, Comprar, Histórico, Ajustes, nas três telas de apresentação e na revisão;
menções ao nome Tino nos textos permanecem como texto. O `viewBox` e os caminhos
originais foram preservados. Para compatibilidade, a cor `#16221F` foi movida da
classe CSS para o preenchimento herdado do grupo SVG, sem filtro de cor no app.

Validação da integração inicial no onboarding: análise sem problemas, 14 testes aprovados,
verificação pontual da renderização com dimensões e pixels opacos em `#16221F`,
APK compilado e instalado via `flutter run` no Moto G54. O logo foi conferido
por captura na revisão da apresentação. Arquivos temporários de verificação
e capturas permanecem fora do Git.

A padronização posterior nas demais telas reutiliza o mesmo SVG, sem novas
dependências. Foi validada com `flutter analyze` sem problemas e `flutter test`
com 14 testes aprovados, incluindo navegação e layout com texto ampliado.

## Persistência mínima

Nova dependência: `shared_preferences` 2.5.6, compatível com Flutter 3.47.8 e
Dart 3.13.7. A API `SharedPreferencesAsync` guarda um único booleano
`onboarding_seen`; chave ausente equivale a apresentação ainda não vista.
No Android, usa o backend padrão DataStore Preferences do plugin.

É uma preferência simples e não crítica, adequada ao armazenamento chave/valor;
Drift/SQLite continua reservado para os dados de compras de etapas futuras.
Não há associação com versão do aplicativo, limpeza automática nem migração que
redefina esse valor em atualizações comuns. Apagar os dados do app remove também
a preferência. Não foi implementado tratamento especial de restauração de backup;
o comportamento de backup do sistema permanece sem personalização.

Referência do pacote: [shared_preferences](https://pub.dev/packages/shared_preferences).
Riverpod fornece a preferência e a leitura inicial; o roteador usa o resultado
para escolher Início ou apresentação. O passo atual e o estado de gravação ficam
apenas na apresentação; nenhuma entidade ou camada de compras foi adicionada.

## Como validar no Moto G54

```powershell
flutter devices
flutter run -d ZF524K6WC6
```

Neste Windows, o Flutter encontrou restrição de links simbólicos dos plugins
desktop. Para trabalhar apenas no alvo Android sem alterar configurações globais,
os comandos desta etapa usam `$env:FLUTTER_WINDOWS='false'` no processo PowerShell.
Se necessário, aplique essa variável em um terminal dedicado antes dos comandos.
Ela não modifica a configuração do Flutter nem o aplicativo.

Na primeira compilação com esse plugin, o Gradle instalou automaticamente o
Android SDK Platform 35, revisão 2, e o CMake 3.22.1, requeridos pela cadeia
nativa de dependências. Os arquivos do projeto não alteram versões de Gradle,
Java, NDK ou SDK; não foram acrescentados requisitos de emulador ou serviços.

1. Sem a preferência salva, confira as três telas e a ausência de pedidos de
   permissão. Toque em Próximo duas vezes e em Começar; deve abrir o Início.
2. Encerre o processo e reabra: deve entrar diretamente no Início.
3. Em Ajustes → Sobre o Tino, reveja e use a saída para Ajustes. Confira também
   Pular, concluir a revisão e o gesto Voltar. Reabrir continua levando ao Início.
4. Para testar um novo primeiro acesso, apague os dados **do Tino** pelas
   configurações Android (isso remove todos os dados locais do aplicativo).
   Reabra e toque em Pular na primeira tela; deve entrar no Início e lembrar
   dessa escolha na próxima abertura.
5. Confira paisagem, rolagem, texto ampliado e TalkBack. Substituir o APK mantendo
   os dados deve preservar a escolha; desinstalar não é um teste de atualização.

Os testes de widgets simulam apenas a fronteira do plugin. Recriam ProviderScope,
app e roteador para testar uma nova abertura, mantendo ou apagando o mapa que
representa o disco. A persistência nativa exige conferência no aparelho.

## Validação executada

- `dart format lib test`: arquivos formatados.
- `flutter analyze`: sem problemas.
- `flutter test`: 14 testes aprovados, incluindo os cinco da etapa 1. Cobrem
  primeiro acesso, concluir, pular em cada tela, interrupção, reabrir, preferência
  ausente após limpeza, revisão e retorno pelos Ajustes, falhas de leitura e
  gravação, espera pela gravação e layout com texto ampliado em tela estreita.
- `flutter build apk --debug`: APK compilado com sucesso.
- `flutter devices`: Moto G54 `ZF524K6WC6`, Android 15, conectado.
- `flutter run -d ZF524K6WC6 --no-resident`: compilado, instalado e iniciado.
- Via ADB no aparelho: dados somente do Tino apagados; três telas percorridas e
  concluídas; processo encerrado e reaberto diretamente no Início. Em Ajustes →
  Sobre o Tino, conferidos saída explícita, Voltar do Android e conclusão da
  revisão retornando aos Ajustes. Após nova abertura, o app continuou no Início.
- APK substituído com `adb install -r`, mantendo os dados: a escolha foi
  preservada. Isso verifica substituição do pacote com preservação de dados;
  não foi simulado incremento de versão nem restauração de backup.
- Dados somente do Tino apagados novamente: a apresentação reapareceu. Pular na
  primeira tela abriu o Início e a escolha persistiu após encerrar/reabrir.
- Interface revisada por captura em retrato. Texto ampliado foi validado em
  widgets; paisagem, TalkBack e gestos físicos/preditivos no celular continuam
  para revisão manual. O comando Voltar via ADB foi validado.

A etapa termina aqui. Scanner, compras, cálculos, banco local, preferências de
aparência e demais funções do MVP continuam fora deste incremento.
