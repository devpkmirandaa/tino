# Tino · Especificação das telas (v1, 6 nov 2026)

Referência visual de cada tela em `telas/NN-nome.html` (abre no navegador, 390 × 844, links entre telas funcionam).
Todo valor de cor, tipo, espaço e raio vem de `tokens/tokens.json`. Nunca usar hex direto no código: mapear para os tokens semânticos (`canvas`, `surface`, `surface-soft`, `border`, `border-strong`, `text-primary`, `text-secondary`, `action`, `on-action`, `action-pressed`, `info`).
Animações: ver `motion/motion.md`. Cada tela abaixo cita as interações pelo código (M1, M2…).

---

## Navegação

- **Abas (3):** Comprar (inicial), Listas, Histórico. Barra inferior com ícone + rótulo sempre visíveis.
  - Ativo: contorno do ícone e rótulo em `action`, rótulo peso 600. Inativo: `text-secondary`, peso 500. Nunca preencher o ícone.
  - Barra: fundo `surface`, borda superior `border`, altura 76 (inclui área segura).
- **Fora das abas:** Boas-vindas (só na primeira abertura), Ajustes (engrenagem no topo do Comprar), Scanner (tela cheia), Lista, Finalizar.
- **Folhas (bottom sheets):** Detalhe do item, Orçamento, Digitar preço, Organizar lista.
- Some do app atual: aba Início (vira o Comprar) e aba Ajustes (vira a engrenagem).

## Componentes base

| Componente | Medidas | Observações |
| --- | --- | --- |
| Botão primário | altura 52 (padrão) ou 64 (Escanear), raio 12 / 16 | fundo `action`, texto `on-action` 16/600; pressionado `action-pressed` + M1 |
| Botão contornado | altura 48, raio 12 | borda 1 `border-strong`, texto `text-primary` ou `action` |
| Botão de texto | altura 48 | sem fundo, texto `action` 14/600 |
| Chip | altura 40, raio pílula | borda `border-strong`, ícone 20 (compacto) + rótulo 14/600 |
| Botão só ícone | 48 × 48 | sempre com rótulo de acessibilidade |
| Input | altura 52, raio 12 | borda `border-strong`, rótulo acima 14/600 |
| Cartão | raio 20 (principal) ou 16 (compacto), padding 16 | fundo `surface`, borda 1 `border`, sem sombra |
| Linha de item | altura mín. 64, padding 12/16 | nome 16/600, apoio 12/500 `text-secondary`, preço 16/700 tabular à direita |
| Controle segmentado | altura 48 (trilho), segmento 40, raio 12/8 | trilho `surface-soft`, selecionado `surface` (M6) |
| Contador de quantidade | 48 de altura, botões 48 × 48 | número 16/700 tabular |
| Barra de progresso | altura 8 (6 nas listas), pílula | trilho `surface-soft`, preenchimento `action` (M9) |
| Folha | raio superior 24, alça 40 × 4 `border` | fundo `surface` (M5) |

Dinheiro sempre com `tabular-nums`, preço em 700, alinhado à direita.

---

## 01 · Boas-vindas
**Quando:** só na primeira abertura. **Objetivo:** explicar o app em uma imagem e uma frase.
- Wordmark (arquivo, nunca recompor com fonte), altura 32.
- Ilustração funcional: cantos do visor + etiqueta "Molho de tomate R$ 3,00" + selo "No carrinho". Não desenhar a saúva.
- Título "Comprar bem começa antes." (32/40/700) e frase de apoio.
- Três benefícios com ícone de check.
- Botão "Começar" → Comprar vazio (M7). Aviso: a câmera só é pedida no primeiro scan.
- Motion de entrada: M10.

## 02 · Comprar (vazio)
**Aba inicial.** Estado sem itens.
- Topo: título "Comprar" (24/32/700) + engrenagem → Ajustes (M7).
- Cartão do total: "Total" + `R$ 0,00` em 40/48/700 + chips "Orçamento" (abre folha) e "Usar uma lista" (abre seletor de listas).
- Estado vazio: ícone num quadrado `surface-soft` 64, "Carrinho vazio", frase de apoio.
- Botão "Escanear preço" (64, raio 16) → Scanner (M2). Botão de texto "Digitar preço" → folha de digitar.
- **Permissão da câmera:** pedida no primeiro toque em Escanear, com uma frase antes do diálogo do sistema. Se negada: "Sem a câmera, dá pra digitar o preço." + botão para abrir os ajustes do sistema.

## 03 · Scanner
**Tela cheia, fundo escuro** (`canvas` do tema escuro, independente do tema do app).
- Topo: fechar (48, círculo `surface` escuro) · pílula com "N itens" + total (M4 no total) · lanterna.
- Visor: quatro cantos em `jade-claro`, traço 4, raio 16. **Sem animação contínua** (nada de linha de varredura).
- Quando o preço trava: cantos se ajustam à etiqueta (M3a), selo "Preço travado".
- Folha inferior fixa (sobe em M3b quando o item entra):
  - "Adicionado ao carrinho" (12/600 `action` + ícone) · nome curto 20/700 · apoio "Marca · peso" · preço 28/700.
  - Contador de quantidade · "Desfazer" (M8) · lápis "Corrigir" → Detalhe do item (M5).
  - "Já pode apontar para a próxima etiqueta."
- **Comportamento:** item entra sozinho ao travar (configurável em Ajustes). Lendo de novo o mesmo produto em menos de 3 s, não duplica.
- Erro de leitura: "Não deu pra ler o preço. Quer digitar?" com botão para a folha de digitar.

## 04 · Comprar (com itens)
- Cartão do total: "Total · N itens" + valor 40/48 (M4). Se tem orçamento: barra (M9) + "Orçamento R$ X" / "Faltam R$ Y". Passou do orçamento: "Passou R$ Y do orçamento." (texto, não só cor).
- Faixa da lista ativa (fundo `info`, texto `grafite-profundo`): nome da lista + "2 de 6 no carrinho · faltam arroz, café…" → Lista (M7).
- Lista de itens num cartão: **nome curto** + apoio (marca · peso, ou peso · preço/kg) + preço. Toque → Detalhe do item (M5). Novos itens entram no topo (M3c).
- "Finalizar compra" (contornado) → Finalizar (M7).
- Rodapé: botão quadrado 64 "Digitar preço" + "Escanear preço" (M2).

## 05 · Detalhe do item (folha)
- Título = nome curto. Fechar no canto.
- Campo "Nome" + linha "Na etiqueta: TEXTO CRU". Se a pessoa corrige o nome, guardar a correção para esse produto.
- Segmentado "Por unidade | Por quilo" (M6). Por quilo: campos peso (kg) + preço/kg, subtotal calculado.
- Preço (input decimal, 18/700) + quantidade.
- Subtotal em faixa `surface-soft`.
- "Salvar" (primário) · "Tirar do carrinho" (texto, com ícone de lixeira; tem Desfazer em toast, M8).
- Arrastar pra baixo fecha (M5).

## 06 · Finalizar
- Voltar + título.
- Cartão central: "Você vai pagar" + valor 44/52 (M4 ao entrar) + selo "Sobraram R$ X do orçamento" (ou "Passou R$ X").
- Faixa `info` "Ficaram fora do carrinho" com chips dos itens da lista não comprados + "Eles continuam na lista pra próxima vez."
- Campo opcional "Onde foi a compra?".
- "Concluir e guardar" → Histórico (M11) · "Continuar comprando".

## 07 · Listas
- Título + botão "Nova lista" (pílula `action`).
- Cartões: nome 18/600 + "N itens · contexto". A lista em uso mostra progresso (M9).
- Rodapé de ajuda: "Com uma lista ativa, cada item escaneado sai dela sozinho."

## 08 · Lista
- Voltar + nome + "Organizar" (folha com: ordem por categoria, ordem manual, arrastar).
- Campo "Adicionar item" fixo no topo, com botão +.
- Itens agrupados por categoria (rótulo 12/600 `text-secondary`), linha 52 com checkbox. Marcado: texto `text-secondary` + "No carrinho" em `action` (M12).
- "Comprar com esta lista" → Comprar com a faixa da lista ativa.

## 09 · Histórico
- Cartão com mês atual × mês anterior (valor 24/700 + número de compras).
- Compras agrupadas por mês: data, "N itens · lista usada", valor. Toque → resumo da compra (mesmo layout de Finalizar, só leitura).
- Futuro: "Da última vez custou R$ X" no scanner, usando esses dados.

## 10 · Ajustes
- Na compra: Adicionar ao travar o preço · Sons · Vibrar ao ler (switches).
- Aparência: segmentado Automático | Claro | Escuro.
- Ajude o Tino a ler melhor: "Enviar recortes das etiquetas", com a explicação "Só a imagem do preço, sem local nem dados seus. Treina a Saúva."
- Sobre: Código aberto e licenças (incluir licença ISC do Lucide) · Apoiar o Tino · versão.

---

## Texto e voz
Frase curta, imperativo gentil, número em destaque, sem exclamação vendedora, sem emoji. Erros dizem o que fazer: "Não deu pra ler o preço. Quer digitar?".

## Acessibilidade
- Toque mínimo 48 × 48. Texto ≥ 4,5:1, ícones e bordas de controle ≥ 3:1 (os tokens já passam).
- Estado nunca só por cor (orçamento estourado tem texto; item no carrinho tem rótulo).
- Escala dinâmica de texto: layouts quebram linha, não cortam.
- Leitor de tela anuncia "Molho de tomate, 3 reais, adicionado" quando o item entra.
- Movimento reduzido: ver `motion/motion.md`.

## Tema escuro
Usar os valores `dark` dos tokens. O escuro é grafite neutro. O Scanner é sempre escuro.
