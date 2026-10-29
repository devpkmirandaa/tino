# Tino — contexto técnico consolidado

Consolidação em 29/10/2026. Base: decisões técnicas recuperadas da conversa de
28/10/2026, decisões de identidade já registradas e inspeção do repositório.
Este documento não é uma cópia integral do briefing original. Onde a recuperação
não trouxe detalhes, eles são marcados como pendências.

Atualização: o usuário forneceu diretamente o mapa do MVP, registrado em
`docs/MAPA_DE_TELAS.md`. Esse mapa é a referência de navegação e substitui a
descrição parcial de telas desta consolidação. O desenvolvimento será por etapas.

## Propósito

Tino significa sensatez, prudência e previsão. Slogan: “Comprar bem começa antes.”
Ajuda a pessoa a conhecer o total da compra antes do caixa, usando leitura de
etiquetas, cálculo de valores, listas e controle de orçamento.
Gratuito, de código aberto, sem anúncios. Personalidade minimalista, serena,
inteligente, acessível, amigável, contemporânea e brasileira. Símbolo: saúva.

## Stack e arquitetura recuperadas

| Área | Direção definida |
| --- | --- |
| Aplicativo | Flutter + Dart |
| Organização | Feature-first + Clean Architecture pragmática |
| Estado | Riverpod |
| Navegação | GoRouter |
| Dados locais | Drift / SQLite |
| OCR inicial | Google ML Kit |
| Interface | Design system próprio |
| Operação do MVP | Offline-first |
| Versionamento | Git / GitHub |

As bibliotecas são direção de implementação, não dependências já instaladas.
Versões e wrappers específicos precisam ser verificados antes da adoção.
Não introduzir infraestrutura remota para funções locais do MVP.

## Escopo da primeira versão

- Leitura ao vivo de etiquetas de supermercado.
- Separação e associação entre nome do produto e preço.
- Confirmação da leitura, prevenção de duplicatas e correção pelo usuário.
- Carrinho e total acumulado antes do caixa.
- Cálculo para produtos vendidos por peso.
- Orçamento da compra e alertas.
- Lista de compras.
- Histórico local de compras finalizadas.
- Feedback leve, sonoro/animado conforme a interação.

ML Kit fornece reconhecimento de texto; a aplicação precisa tratar os resultados
e resolver associação produto/preço, repetições e unidades de venda.

## Navegação e fluxo

Cinco áreas principais: **Início, Listas, Comprar, Histórico e Ajustes**, com
**Comprar como ação central**. Consulte o mapa completo em `MAPA_DE_TELAS.md`.

Primeira abertura: três telas curtas de apresentação opcionais, com “Pular”.
Sem login obrigatório. Solicitar a permissão de câmera no primeiro uso do scanner.

Início → Comprar → Nova compra (orçamento opcional) → Scanner → Produto identificado
(confirmar/corrigir quando necessário) → Carrinho → Finalizar e salvar no histórico.

O inventário estima cerca de 22 telas e estados, incluindo bottom sheets/modais;
não são 22 páginas independentes. Rótulos finais e estados de erro devem ser
detalhados na etapa correspondente.

## Fora do MVP

Mapa de mercados, sincronização em nuvem e comunidade/compartilhamento de preços.
A comunidade futura é opcional. Informar antes do envio de dados e manter a
experiência básica independente da participação na comunidade.

## Identidade e interface já definidas

- Tipografia: Plus Jakarta Sans.
- Ícones: Lucide, exclusivamente outline, traço uniforme de 2 px; 24 px padrão
  e 20 px compacto. Estado ativo muda somente a cor, sem preenchimento ou mudança
  de espessura: jade no claro e jade claro no escuro.
- Layout responsivo, preferência por espaçamento de 20 px, botões outline e
  animações fluidas. Não tratar todo espaçamento do sistema como obrigatoriamente 20 px.
- Modo escuro com grafite neutro; valores finais de todos os tokens escuros ainda
  não foram recuperados.

| Cor | HEX |
| --- | --- |
| Jade | #246B55 |
| Jade claro | #ABD8C5 |
| Azul glacial | #C8E1ED |
| Off-white | #F5F7F6 |
| Quase preto | #16221F |
| Branco suave | #EAF1EE |

O azul glacial substitui o roxo das propostas anteriores. Os nomes das cores ainda
podem ser renomeados. Não inventar símbolo definitivo a partir da descrição da saúva.

## Estado observado em 29/10/2026

- Repositório: https://github.com/devpkmirandaa/tino
- Projeto local informado: `C:\Projetos\tino`.
- `lib/main.dart` ainda contém o contador padrão do Flutter.
- `pubspec.yaml` contém Flutter, Cupertino Icons, flutter_test e flutter_lints;
  as bibliotecas da arquitetura ainda não estão declaradas.
- O usuário já compilou, instalou e iniciou o APK no Moto G54 5G.
- Flutter, Android SDK, NDK e VS Code estão configurados no computador do usuário.
- O Codex foi aberto pelo usuário; sua forma final de acesso não foi confirmada.
- A primeira compilação bem-sucedida não valida funcionalidades do Tino nem
  substitui `flutter analyze`, os testes ou validação de câmera/OCR.
- Em relato posterior, o Codex local informou Flutter 3.47.8, Dart 3.13.7,
  `flutter analyze --no-pub` sem problemas e um teste do contador aprovado com
  `flutter test --no-pub`. Esses comandos não foram reexecutados nesta consolidação.
- O usuário informou que colocou o briefing na raiz do projeto Windows. O destino
  canônico é `docs/BRIEFING_TECNICO.md`; consolidar nesse caminho, preservando
  eventuais alterações locais, para evitar duas versões divergentes.

## Pendências que não devem ser inventadas como decisões anteriores

- Texto integral do briefing original e eventuais detalhes não recuperados.
- Versões e pacotes Flutter exatos de câmera, OCR, ícones e demais dependências.
- Precisão monetária, regras de arredondamento e representação de pesos.
- Limites dos alertas de orçamento; política de duplicatas; confiança mínima do OCR.
- Tratamento de promoções, preço por unidade/kg e múltiplos preços na mesma etiqueta.
- Modelo de dados detalhado, migrações, edição/remoção e recuperação de compra ativa.
- Textos completos do onboarding, telas finais e tokens escuros definitivos.
- Licença do código e política detalhada de privacidade.

## Sequência sugerida nesta consolidação (não recuperada como roadmap aprovado)

1. Validar o contexto e o estado inicial do projeto.
2. Preparar a base de arquitetura, tema claro e navegação das cinco áreas em um
   incremento executável, conforme o recorte proposto no mapa.
3. Desenvolver e validar o núcleo local de compras, cálculos e persistência.
4. Integrar câmera/OCR e o fluxo de confirmação com testes no aparelho.
5. Completar listas, histórico, alertas e refinamento da experiência do MVP.

Ajustar a sequência ao briefing integral quando ele estiver disponível.
O mapa completo orienta o projeto; cada tarefa deve executar apenas a etapa
solicitada. Não antecipar funcionalidades posteriores.

## Registro posterior de implementação

As etapas 1 (base visual/navegação) e 2 (apresentação e primeiro acesso) foram
implementadas por solicitações separadas do usuário. O estado observado acima é
histórico; consulte `../README.md` e `ETAPA_2_APRESENTACAO.md` para comportamento,
preferência local, validações executadas e limitações atuais. As funções de
compras, cálculos e persistência de compras ainda não foram implementadas.
