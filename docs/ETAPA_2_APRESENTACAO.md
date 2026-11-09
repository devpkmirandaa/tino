# Etapa 2 — apresentação e primeiro acesso (concluída)

> **Substituída pela etapa 9 (telas complementares).** As três páginas de
> deslize, o "Pular" e os indicadores deram lugar à tela única de boas-vindas
> (`design/telas/01-boas-vindas.html`, entrada M10). Continuam valendo a
> preferência local, a espera pela gravação e o modo de revisão pelos Ajustes,
> agora sem botão de fechar ("Começar" e Voltar retornam aos Ajustes).

Escopo: apresentação inicial e uma preferência local. Sem banco de compras,
câmera, permissões ou login.

## Comportamento

- Três páginas horizontais por deslize, com os textos fornecidos pelo usuário.
  O conteúdo acompanha o dedo; indicadores inferiores também escolhem a página.
- Sem botões Próximo/Voltar. "Pular" nas duas primeiras e "Começar" na última.
  A barra das cinco áreas só aparece depois de sair da apresentação.
- Concluir/pular aguarda a gravação (controles desabilitados enquanto grava).
  Se falhar, mostra o erro e permite tentar de novo.
- A abertura aguarda a leitura da preferência. Se falhar, oferece nova tentativa
  sem presumir primeiro acesso.
- Interrompida antes de concluir/pular, reaparece desde a primeira tela. Voltar
  nas telas 2 e 3 retorna à anterior; na 1 sai do app sem marcar como vista.
- Ajustes → Sobre o Tino reabre a apresentação em modo de revisão. Qualquer
  saída (ícone de fechar, Voltar do Android, Pular, Começar) retorna aos
  Ajustes, sem apagar nem regravar a preferência.

## Marca

`TinoWordmark` renderiza `assets/branding/tino-wordmark.svg` (fornecido pelo
usuário) via `flutter_svg` 2.3.2 nas cinco áreas. Na apresentação, aparece apenas
na primeira página, com largura de 96 dp e altura proporcional.
`viewBox` e caminhos originais preservados; a cor `#16221F` foi movida da classe
CSS para o preenchimento do grupo SVG.

## Persistência

`shared_preferences` 2.5.6 (`SharedPreferencesAsync`), um booleano
`onboarding_seen`; ausente = não visto. Sem associação com versão do app, sem
migração e sem tratamento especial de backup. Apagar os dados do app remove a
preferência. Drift/SQLite segue reservado para os dados de compras. Riverpod
fornece a preferência e a leitura inicial; o roteador escolhe Início ou
apresentação.

## Como validar no Moto G54

```powershell
$env:FLUTTER_WINDOWS='false'
flutter devices
flutter run -d ZF524K6WC6
```

1. Sem preferência salva: confira as três telas e a ausência de pedido de
   permissão; deslizar duas vezes para a esquerda e tocar em Começar abre o Início.
2. Encerre e reabra: entra direto no Início.
3. Ajustes → Sobre o Tino: reveja e teste as saídas e o gesto Voltar.
4. Novo primeiro acesso: apague os dados do Tino nas configurações do Android,
   reabra e toque em Pular na primeira tela.
5. Confira paisagem, rolagem, texto ampliado e TalkBack. Reinstalar o APK
   mantendo os dados preserva a escolha.

## Validação anterior ao ajuste de movimento

`dart format`, `flutter analyze` sem problemas, `flutter test` com 14 testes
aprovados, `flutter build apk --debug` e execução no Moto G54 (Android 15),
incluindo persistência via ADB e substituição do APK com dados preservados.

Pendente de revisão manual: paisagem, TalkBack e gestos físicos/preditivos.
Não simulados: incremento de versão e restauração de backup.

## Movimento e transições

Contrato de movimento, preservação das áreas e validação em profile:
ver [MOVIMENTO_INTERFACE.md](MOVIMENTO_INTERFACE.md).
