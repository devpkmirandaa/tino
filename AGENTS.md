# Tino — instruções para agentes

## Contexto obrigatório

Leia `docs/BRIEFING_TECNICO.md` e `docs/MAPA_DE_TELAS.md` antes de planejar ou
implementar funcionalidades. O mapa foi fornecido diretamente pelo usuário e é
a referência de navegação do MVP; não é uma lista de telas a executar de uma vez.
O documento consolida decisões recuperadas das conversas; não é transcrição integral
do briefing original. Trate lacunas como pendências, não como decisões aprovadas.
Não presuma acesso às conversas do ChatGPT. Mantenha decisões duradouras no repositório.
Responda em português brasileiro, de forma curta e objetiva.

## Produto e escopo

Tino: “Comprar bem começa antes.” Aplicativo brasileiro gratuito, open source e sem
anúncios para ler preços, somar compras e controlar o orçamento antes do caixa.
O MVP é offline-first: scanner, confirmação/correção, carrinho, produtos por peso,
orçamento e alertas, listas e histórico local. Mapa, nuvem e comunidade são futuros.
Compartilhamento futuro deve ser voluntário, transparente e precedido de aviso.

## Direção técnica recuperada

- Flutter + Dart; arquitetura feature-first com Clean Architecture pragmática.
- Riverpod para estado; GoRouter para navegação; Drift/SQLite para persistência.
- Google ML Kit como direção inicial de OCR. Reconhecer texto não resolve sozinho
  associação produto/preço, deduplicação ou identificação de preço por kg.
- Design system próprio, descrito no briefing. Não substituir a identidade por
  tema padrão do Flutter.
- Verifique SDK, versões compatíveis e estado real do código antes de adicionar
  dependências. Não atualize Gradle, Java, NDK ou SDK sem necessidade demonstrada.
- Ambiente inicial: Windows, VS Code, Flutter e Android SDK; testes em celular real.
  Não introduzir emulador, Node.js, Firebase ou Docker como requisitos iniciais.

## Forma de trabalho

- Confira `git status` antes de editar e preserve alterações existentes do usuário.
- Diferencie implementação existente, decisão de produto e proposta nova.
- Entregue incrementos pequenos e executáveis; não tente implementar o MVP inteiro
  na primeira tarefa. Evite camadas vazias e abstrações sem uso.
- Trabalhe somente na etapa solicitada. Ao concluí-la, reporte a validação e o
  próximo passo; não avance automaticamente para a etapa seguinte.
- Preserve as cinco áreas: Início, Listas, Comprar, Histórico e Ajustes, com
  Comprar como ação central. As cerca de 22 telas/estados incluem modais e
  bottom sheets; não criar 22 páginas independentes.
- Mantenha regras de cálculo separadas dos widgets e do OCR. Cubra com testes os
  cálculos, preços por peso, correções, duplicatas e transições de orçamento.
- Defina e documente precisão monetária e arredondamento antes dos cálculos por peso;
  esses detalhes ainda não foram recuperados do briefing original.
- Não apresente dados simulados ou OCR fictício como funcionalidade real.
- Não registre credenciais, tokens ou arquivos locais de configuração no Git.
- Ao terminar, diga o que mudou, o que foi validado e o que ainda falta. Nunca afirme
  que um comando/teste foi executado sem tê-lo executado.

## Conclusão de cada etapa e Git

- Ao concluir cada etapa, execute as validações pertinentes, revise o diff,
  faça um commit descritivo e envie com `git push` para a branch de trabalho.
- Inclua no commit apenas arquivos e alterações da etapa. Preserve alterações
  alheias; não versione segredos, configurações locais ou artefatos de build.
- Nunca use force push.
- Se alguma validação, o commit ou o push falhar, informe o bloqueio e não
  apresente a etapa como concluída com sucesso.
- Ao finalizar, reporte a branch, o hash do commit e o resultado do push.

## Validação

Após mudanças Dart, formate os arquivos alterados, execute `flutter analyze` e
os testes relevantes com `flutter test`. Mantenha os testes alinhados ao produto
quando substituir o contador de demonstração.
Para integração Android, valide a compilação quando a mudança justificar.
O aparelho de desenvolvimento informado é um Moto G54 5G, id `ZF524K6WC6`:
`flutter run -d ZF524K6WC6`. Confirme conexão com `flutter devices`.
OCR, permissões e câmera exigem validação real no aparelho; testes de widgets não
substituem essa validação. Se o ambiente não permitir um teste, relate a limitação.

## Estado da preparação

A inspeção inicial foi realizada pelo Codex local e relatada pelo usuário:
Flutter 3.47.8, Dart 3.13.7, análise sem problemas e um teste aprovado do contador.
Esses resultados são um registro anterior, não validação de mudanças futuras.
Antes da próxima edição, confira o estado atual do projeto. O primeiro incremento
proposto é a base visual/navegação das cinco áreas, com tema claro, sem implementar
scanner, cálculos ou persistência. Consulte o recorte em `docs/MAPA_DE_TELAS.md`.
