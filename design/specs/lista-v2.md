# Tino · Lista v2 (8 nov 2026)

Substitui a seção "08 · Lista" de `specs/telas.md`. Referência: `telas/08-lista.html` e `telas/08-lista-escuro.html`.
Objetivo: usar no mercado com uma mão. Tudo que se faz durante a compra fica na metade de baixo.

## Topo
- Voltar · nome da lista (24/700) · botão "Mais opções" (⋮, 48) com: Renomear, Apagar lista e, se estiver ligada à compra, "Tirar da compra".
- Cartão de progresso: "N de M no carrinho" (18/600 tabular) + barra de 6 px (M9). Se a lista está ligada à compra, selo "Na compra" (ícone de corrente, fundo `surface-soft`, texto `action`; no escuro fundo `jade-tint`).
- Linha: "Faltam N" (14/600 `text-secondary`) à esquerda; chip "Por categoria ˅" ou "Ordem manual ˅" à direita, que abre a folha Organizar (`telas/13`).

## Itens
- Só os itens que faltam aparecem na lista principal, agrupados por categoria (rótulo 12/600 `text-secondary`) ou numa lista única na ordem manual.
- Linha de 56: área de 48 com a caixa de marcar à esquerda; o resto da linha é um botão que abre a folha de edição do item (nome 16/500, apoio 12/500 com quantidade/tamanho, lápis 20 à direita). Nada de toque longo.
- Marcar um item tira ele da lista principal (M12) e manda para a seção "No carrinho".
- Seção "No carrinho · N" no fim, recolhida por padrão (botão 48, fundo `surface-soft`, "Ver" + seta). Aberta, mostra os marcados em `text-secondary` com a caixa marcada; desmarcar devolve o item à categoria.

## Painel de baixo (fixo, fundo `surface`, raio superior 24, borda superior `border`)
- Campo "Adicionar item" (56). Vazio (`telas/08`): só o placeholder, borda `border-strong`, sem ícone e sem botão.
- Digitando (`telas/08a`): borda de 2 em `action` e, dentro do campo à direita, o botão "Adicionar" (pílula de 40, toque 48, fundo `action`, check 18 + "Adicionar" 14/600 `on-action`). Entra e sai com opacidade (150 ms) e escala 0,8 → 1 na mola `selecao`. Apagou tudo, ele some.
- Botão ou tecla de confirmar do teclado: adiciona com categoria sugerida e quantidade 1, limpa o campo, o botão some e o teclado continua aberto para o próximo.
- Enquanto há texto, abaixo do campo, 12/500 `text-secondary`: "Vai pra [categoria sugerida]".
- Chips "Você costuma levar" (40, pílula `surface-soft`, + em `action`): itens frequentes das compras anteriores que não estão na lista. Rolagem horizontal. Enquanto há texto, só os que contêm o que foi digitado (sem diferença de acento e caixa); sem correspondência, somem. Toque adiciona o item e limpa o campo. Sem histórico, os chips não aparecem.
- Botão primário "Escanear preço" (56, raio 16). Liga a lista à compra (se ainda não estiver) e abre o Scanner.

## Fora desta tela
- "Comprar com esta lista" sai: o "Escanear preço" faz isso.
- A folha Organizar não tem mais renomear e apagar (foram para o ⋮).
