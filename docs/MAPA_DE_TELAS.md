# Tino — mapa de telas

Fonte: mapa do MVP fornecido pelo usuário em 29/10/2026. Prioridades: navegação
simples, poucos toques, funcionamento offline.

Instrução do usuário: **não executar tudo de uma vez; trabalhar por etapa.** O
mapa é o destino do MVP, não autorização para construir tudo numa tarefa.

## Navegação principal

**Início · Listas · Comprar · Histórico · Ajustes**, com Comprar como ação central.

| Área | Função |
| --- | --- |
| Início | Resumo do orçamento, compra em andamento, acesso rápido às listas, botão para começar a comprar. |
| Listas | Criar, editar e gerenciar listas e seus produtos. |
| Comprar | Iniciar compra, escanear etiquetas, reconhecer preços, adicionar produtos, acompanhar o total em tempo real. |
| Histórico | Compras anteriores, valores, datas e detalhe dos itens. |
| Ajustes | Tema claro/escuro, preferências, permissões, dados locais, informações do app. |

## Fluxo de compra

1. Início → tocar em Comprar.
2. Nova compra → definir orçamento (opcional).
3. Scanner → apontar a câmera para a etiqueta.
4. Produto identificado → confirmar ou corrigir, se preciso.
5. Carrinho → total atualizado em tempo real.
6. Finalizar → salvar no histórico.

## Telas e estados complementares

Prefira modais ou painéis inferiores para ações auxiliares; decida por interação
(o scanner não precisa ser modal só por constar aqui). São ~22 telas/estados, não
22 páginas, e esse número não obriga a criar telas extras.

- Primeira abertura: três telas curtas, opcionais.
- Listas: criar lista, editar lista, adicionar/editar item.
- Comprar: definir orçamento, scanner, correção de leitura, carrinho, editar
  produto, confirmação de finalização.
- Histórico: detalhes da compra.
- Ajustes: aparência, permissões, gerenciamento de dados.

## Decisões estabelecidas

Sem login e sem anúncios · offline, dados no aparelho · câmera pedida só no
primeiro uso do scanner · Plus Jakarta Sans, paleta Jade, ícones Lucide ·
animações fluidas e discretas · comunidade, comparação colaborativa, mapa e
nuvem ficam para versões futuras.

Princípio central: abrir o Tino, começar uma compra e registrar um preço com o
mínimo de interações.

## Etapas

- Etapa 1 (feita): base visual e navegação das cinco áreas, sem Drift, câmera,
  OCR, cálculos nem modo escuro (tokens escuros ainda indefinidos).
- Etapa 2 (feita): apresentação e primeiro acesso. Ver `ETAPA_2_APRESENTACAO.md`.
- Etapa 3 (feita): regras de cálculo, sem interface. Ver `BRIEFING_TECNICO.md`.
- Próximas: definir com o usuário, uma por vez.