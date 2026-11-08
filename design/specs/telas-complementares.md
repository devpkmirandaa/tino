# Tino · Telas complementares (v1, 7 nov 2026)

Completa `specs/telas.md`. Mesmas regras: valores só de `tokens/tokens.json`, textos exatamente como nas telas, HTML é referência visual. As telas novas estão em `telas/11` a `telas/16` e `telas/03c` (abrem no navegador). Versão escura: aplicar os tokens `dark`.

## Tema (vale pro app todo)
- Ajustes → Aparência: segmentado **Automático | Claro | Escuro** (já em `telas/10-ajustes.html`). Padrão: Automático. Guardar a escolha no aparelho.
- O app inteiro segue essa escolha, não só o tema do celular.
- Scanner: câmera e topo sempre escuros; a folha inferior segue a escolha de Ajustes (hoje segue `platformBrightness`, trocar).

## 03c · Scanner sem leitura
- Depois de um tempo sem travar preço (mesmo tempo que o código já usar; se não houver, propor um valor), a folha mostra: "Não deu pra ler o preço. Quer digitar?" (20/700) + "Chegue mais perto, segure firme ou ligue a lanterna." (14/500 `text-secondary`).
- Primário "Digitar preço" (ícone teclado) → folha 11. Texto "Continuar tentando" volta a procurar.
- Some sozinho assim que um preço travar.

## 11 · Digitar preço (folha)
- Substitui o visual da folha "Adicionar produto". Usa o teclado numérico do celular; **sem teclado desenhado**. A faixa cinza do HTML só marca o espaço do teclado.
- Ordem: título "Digitar preço" + fechar · segmentado "Por unidade | Por quilo" · linha com Preço (input 56, borda 2 `action` quando focado, 24/700 tabular, abre focado) e Quantidade (contador) · Nome (opcional), placeholder "Ex.: Arroz" · primário "Adicionar · R$ X" com o subtotal.
- Por quilo: troca Quantidade por Peso (kg) e o preço vira preço/kg, como a folha atual já faz.
- A folha precisa caber acima do teclado aberto.

## 12 · Orçamento (folha)
- "Quanto você quer gastar nesta compra?" · input Valor (64, 28/700) · atalhos R$ 100, 150, 200, 300 (chip; o escolhido com borda 2 `action`).
- Bloco `surface-soft` "Avisar quando faltar pouco" + "Avisa e vibra quando passar de 90% do valor." + switch, guardado no aparelho e ligado por padrão. O switch controla o aviso de 90% inteiro: a faixa "Perto do limite do orçamento" no Comprar (`telas/04a`) e a vibração. Desligado, nenhum dos dois aparece. "Passou do orçamento" (barra em `text-primary`, faixa invertida e vibração dupla, `telas/04b`) continua sempre.
- Primário "Usar R$ X" · texto "Compra sem orçamento" (remove).

## 13 · Organizar lista (folha)
- Abre pelo botão "Organizar" da Lista.
- Radio "Por categoria" (Agrupa como os corredores do mercado.) | "Ordem manual" (Você arrasta cada item pra onde quiser.). Mapear para o `ListOrder` existente.
- "Ordem das categorias": lista com alça de arrastar (Lucide grip-vertical, botão 48). Usa o `categoryOrder` que o banco já guarda.
- Primário "Pronto".

## 14 · Câmera, antes de pedir (folha)
- No primeiro toque em Escanear, antes do diálogo do sistema.
- Ícone câmera em quadrado 64 `surface-soft`, "O Tino lê o preço pela câmera", "Aponte pra etiqueta e o item entra no carrinho. Nenhuma foto sai do celular."
- Bloco `surface-soft` com escudo: "Enviar recortes de etiqueta pra treinar a Saúva é opcional e fica desligado até você ligar em Ajustes."
- Primário "Permitir câmera" → pedido do sistema → Scanner. Texto "Agora não, vou digitar" → folha 11.

## 15 · Câmera sem permissão (folha)
- Quando o acesso foi negado (hoje vira mensagem na folha do scanner; trocar por esta folha).
- Ícone câmera cortada, "Sem a câmera, dá pra digitar o preço.", "Se mudar de ideia, libere a câmera pro Tino nos ajustes do celular."
- Primário "Digitar preço" → folha 11 · contornado "Abrir ajustes do celular" (abre os ajustes do app no sistema).

## 16 · Resumo da compra
- Página `/historico/:id` atual, com visual novo. Somente leitura.
- Título = data ("4 de novembro") + "Dia · N itens · lista usada".
- Cartão "Você pagou" (40/48) + selo do orçamento + mercado (ícone pino), só se houver.
- Cartão de itens com linha de item padrão; mostra 5 e "Ver os N itens".
- Rodapé: "Compras guardadas ficam como foram registradas."
