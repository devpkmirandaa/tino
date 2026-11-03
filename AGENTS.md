# Tino — instruções para agentes

Responda em português brasileiro, curto e objetivo.

## Produto

Tino: "Comprar bem começa antes." App brasileiro, gratuito, open source e sem
anúncios para ler preços, somar compras e controlar o orçamento antes do caixa.
O MVP funciona offline: scanner, confirmação/correção, carrinho, produtos por
peso, orçamento e alertas, listas e histórico local. Mapa, nuvem e comunidade
são futuros; compartilhamento futuro será voluntário e com aviso prévio.

## Documentos (abra só o que a tarefa exige)

- `docs/BRIEFING_TECNICO.md`: decisões técnicas, identidade e pendências.
- `docs/MAPA_DE_TELAS.md`: navegação e fluxo do MVP.
- `docs/ETAPA_2_APRESENTACAO.md`: só se mexer no onboarding.

Lacunas são pendências, não decisões aprovadas. Decisões duradouras ficam no
repositório, não em conversas.

## Design system

Fonte da verdade: `docs/marca/` (manual provisório v0.2). Leia
`docs/marca/README.md` antes de mexer em tela, componente ou asset visual;
`tokens.json` traz cores claro/escuro, tipografia, espaçamento, raios e medidas.
Vitrine: https://claude.ai/artifact/BFnLRLhQYhhA9nrvtNNbx1.

- No código, só tokens semânticos (`canvas`, `surface`, `text-primary`,
  `action`…) via `lib/core/theme/`; nunca hex solto em widgets.
- Plus Jakarta Sans só na escala do manual; preço em 700, numerais tabulares.
- Lucide Outline, traço 2 px, 24/20 px; ativo muda só a cor. Nunca Filled.
- Espaços 4, 8, 12, 16, 24, 32, 48. Raios: cartão 20, compacto 16,
  botão/input 12, painel 24. Toque mínimo 48, input 52, contraste AA.
- Wordmark sempre pelo SVG (positivo em fundo claro, negativo em escuro).
- Não invente símbolo da saúva, lockup, ícone do app ou componente aprovado;
  o UI Kit é exploratório.
- Antes de trocar token ou decisão definida, explique o motivo e peça
  aprovação. Se um token mudar, atualize `docs/marca/tokens.json` e avise que
  a vitrine no Claude precisa ser atualizada.

## Stack

Flutter + Dart; feature-first com Clean Architecture pragmática; Riverpod;
GoRouter; Drift/SQLite; Google ML Kit (OCR inicial); design system próprio, sem
o tema padrão do Flutter.

- Confira versões e o estado real do código antes de adicionar dependência.
- Não atualize Gradle, Java, NDK ou SDK sem necessidade demonstrada.
- Ambiente: Windows, VS Code, Flutter, Android SDK, celular real. Sem emulador,
  Node.js, Firebase ou Docker como requisito.

## Forma de trabalho

- Rode `git status` antes de editar e preserve alterações do usuário.
- Diferencie o que existe, o que é decisão de produto e o que é proposta nova.
- Faça só a etapa pedida, em incrementos pequenos e executáveis. Ao concluir,
  reporte a validação e o próximo passo; não avance sozinho.
- Cinco áreas: Início, Listas, Comprar, Histórico e Ajustes, com Comprar como
  ação central. As ~22 telas/estados incluem modais e painéis inferiores; não
  crie 22 páginas.
- Regras de cálculo ficam separadas de widgets e OCR, com testes para cálculos,
  preço por peso, correções, duplicatas e transições de orçamento.
- Defina e documente precisão monetária e arredondamento antes do cálculo por peso.
- Sem dados simulados ou OCR fictício apresentados como funcionalidade real.
- Sem credenciais, tokens ou configs locais no Git.
- Ao terminar, diga o que mudou, o que foi validado e o que falta. Nunca afirme
  que rodou um comando ou teste sem tê-lo rodado.

## Git

Ao concluir cada etapa: valide, revise o diff, faça um commit descritivo só com
os arquivos da etapa e dê `git push` na branch de trabalho. Nunca use force push.
Se validação, commit ou push falhar, informe o bloqueio e não dê a etapa como
concluída. Reporte branch, hash do commit e resultado do push.

## Validação

Após mudanças em Dart: formate os arquivos alterados, rode `flutter analyze` e
os `flutter test` relevantes. Valide a compilação Android quando a mudança
justificar.

- Aparelho: Moto G54 5G, id `ZF524K6WC6`. Confira com `flutter devices` e rode
  com `flutter run -d ZF524K6WC6`.
- No PowerShell deste Windows, use `$env:FLUTTER_WINDOWS='false'` no processo
  (evita erro de link simbólico dos plugins desktop).
- O usuário acompanha pelo app aberto (F5 ou `flutter run`): mudanças visuais
  devem aparecer por hot reload. Avise quando exigirem hot restart (`R`) ou
  nova compilação (dependência, código nativo, inicialização, assets novos).
- Câmera, permissões e OCR só se validam no aparelho real; teste de widget não
  substitui. Se o ambiente não permitir um teste, relate a limitação.