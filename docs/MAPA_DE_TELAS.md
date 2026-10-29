# Tino — Mapa de telas do aplicativo

Fonte: mapa do MVP fornecido diretamente pelo usuário nesta conversa, em 29/10/2026.
Formatação normalizada sem acrescentar telas ao mapa. Prioridades: navegação
simples, poucos toques e funcionamento offline.

## 1. Navegação principal

**Início · Listas · Comprar · Histórico · Ajustes**

Cinco áreas principais, com **Comprar como ação central**.

## 2. Estrutura das telas

| Área | Conteúdo e função |
| --- | --- |
| Início | Resumo do orçamento, compra em andamento, acesso rápido às listas e botão para começar a comprar. |
| Listas | Listas de compras, criação, edição e gerenciamento dos produtos. |
| Comprar | Iniciar compra, escanear etiquetas, reconhecer preços, adicionar produtos e acompanhar o total em tempo real. |
| Histórico | Compras anteriores, valores, datas e detalhamento dos itens. |
| Ajustes | Tema claro/escuro, preferências, permissões, dados locais e informações do aplicativo. |

## 3. Fluxo principal de compra

| Passo | Tela/estado | Ação |
| --- | --- | --- |
| 1 | Início | Tocar em Comprar. |
| 2 | Nova compra | Definir orçamento, se desejar. |
| 3 | Scanner | Apontar a câmera para a etiqueta. |
| 4 | Produto identificado | Confirmar ou corrigir, quando necessário. |
| 5 | Carrinho | Acompanhar o total atualizado em tempo real. |
| 6 | Finalizar | Salvar a compra no histórico. |

## 4. Telas e estados complementares

Usar preferencialmente bottom sheets ou modais para ações auxiliares, sem criar
navegação desnecessária. A decisão de apresentação deve considerar cada interação;
o scanner, por exemplo, não precisa ser um modal apenas por constar nesta tabela.

| Área | Telas e estados |
| --- | --- |
| Primeira abertura | Três telas curtas de apresentação, opcionais. |
| Listas | Criar lista, editar lista, adicionar/editar item. |
| Comprar | Definir orçamento, scanner, correção de leitura, carrinho, editar produto e confirmação de finalização. |
| Histórico | Detalhes da compra. |
| Ajustes | Aparência, permissões e gerenciamento de dados. |

Estimativa anterior: aproximadamente **22 telas e estados**, não 22 páginas
independentes. A estimativa não obriga a criar telas extras para atingir um número.

## 5. Decisões estabelecidas

- Sem login obrigatório e sem anúncios.
- Offline-first, com dados armazenados no dispositivo.
- Câmera solicitada apenas no primeiro uso do scanner.
- Plus Jakarta Sans, paleta Jade e ícones Lucide.
- Animações fluidas, discretas e responsivas.
- Comunidade, comparação colaborativa de preços, mapa de mercados e sincronização
  na nuvem ficam para versões futuras.

Princípio central: abrir o Tino, começar uma compra e registrar um preço com o
mínimo possível de interações.

## 6. Desenvolvimento por etapas

Instrução explícita do usuário: **não executar tudo de uma vez; trabalhar por etapa**.
O mapa define o destino do MVP, não autorização para construir todo o escopo em
uma única tarefa. Concluir e validar cada incremento antes de passar ao próximo.

### Recorte sugerido para a etapa 1 — base visual e navegação

Este recorte é uma proposta de execução acrescentada à documentação; não faz parte
do texto original do mapa. Executá-lo quando solicitado pelo usuário.

- Substituir o contador por uma base do Tino organizada por funcionalidades.
- Integrar Riverpod e GoRouter em versões compatíveis com o SDK existente.
- Aplicar tema claro, paleta definida, Plus Jakarta Sans local e ícones Lucide.
- Disponibilizar as cinco áreas principais na ordem definida e destacar Comprar
  como ação central, respeitando o padrão outline dos ícones.
- Criar somente as superfícies iniciais necessárias para validar navegação.
  Indicar recursos indisponíveis sem inventar compras, totais ou leituras.
- Validar mudança entre áreas, seleção ativa e comportamento de retorno no Android.
- Não instalar ainda Drift, câmera ou OCR; não implementar cálculos, listas
  editáveis, histórico persistente, onboarding ou ajustes funcionais nesta etapa.
- Não apresentar tokens escuros provisórios como identidade aprovada; o modo
  escuro será implementado em etapa própria após definição dos tokens restantes.
- Substituir o teste do contador por testes de abertura e navegação, executar
  análise/testes e verificar a interface no Moto G54.

Critério de conclusão: base visual consistente, cinco áreas acessíveis, navegação
sem erros e validação documentada. A lógica de negócio permanece para as próximas
etapas, cujo detalhamento deve ser tratado separadamente.

### Etapa 2 — apresentação e primeiro acesso

Solicitada separadamente pelo usuário: três páginas de apresentação, com
deslize horizontal e indicadores tocáveis no refinamento posterior. Pular nas
duas primeiras páginas e Começar na última; lembrar localmente a conclusão ou o
pulo e permitir rever em Ajustes → Sobre o Tino, com saída para Ajustes. Sem permissões, login ou banco de
compras. Comportamento, persistência e validação registrados em
`ETAPA_2_APRESENTACAO.md`.
