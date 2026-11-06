# Tino · Motion (v1, 6 nov 2026)

Direção do manual: mola suave inspirada no iOS. Inércia leve, continuidade, desaceleração natural, acomodação sem quicar demais. Movimento serve pra explicar de onde as coisas vêm e pra onde vão, nunca pra enfeitar.

Veja rodando: `motion/prototipo.html` (tem câmera lenta e modo de movimento reduzido).

## Regras gerais

1. **Mola em posição e escala; cor e opacidade com transição simples** (linear ou ease-out, 150–250 ms).
2. **Tudo interrompível.** Uma animação nova parte da posição e da velocidade atuais, nunca do começo. Gesto que solta herda a velocidade do dedo.
3. **Nada contínuo no scanner.** Sem linha de varredura, sem pulsar. O visor só se mexe quando trava.
4. **Origem espacial.** O que abre cresce de onde foi tocado; o que fecha volta pra lá.
5. **Uma coisa principal por vez.** No máximo 40 ms de defasagem entre elementos de um mesmo grupo.
6. **Movimento reduzido:** trocar deslocamento e escala por troca de opacidade de 150 ms, sem contagem de números, sem mola com quique.

## Molas

Massa 1 em todas. `response` e `amortecimento` são a notação da Apple; `rigidez` e `atrito` são as mesmas molas em física pura, pra qualquer biblioteca.

| Nome | Uso | response (s) | amortecimento | rigidez | atrito | Duração percebida |
| --- | --- | --- | --- | --- | --- | --- |
| `toque` | pressionar e soltar | 0,20 | 0,90 | 987 | 56,5 | ~200 ms |
| `selecao` | segmentado, aba, switch | 0,25 | 0,85 | 632 | 42,7 | ~250 ms |
| `cartao` | entrar/sair item, barra, cantos do visor | 0,35 | 0,82 | 322 | 29,4 | ~350 ms |
| `confirmacao` | item adicionado, check | 0,38 | 0,70 | 273 | 23,1 | ~380 ms, com leve acomodação |
| `navegacao` | empurrar tela, abrir scanner | 0,42 | 0,92 | 224 | 27,5 | ~420 ms |
| `folha` | folhas e modais | 0,45 | 0,88 | 195 | 24,6 | ~450 ms |

Conversão usada: rigidez = (2π / response)², atrito = 4π · amortecimento / response.

Como fica em cada tecnologia (mesmos números):
- React Native Reanimated: `withSpring(v, { mass: 1, stiffness: 322, damping: 29.4 })`
- Flutter: `SpringDescription(mass: 1, stiffness: 322, damping: 29.4)`
- Jetpack Compose: `spring(dampingRatio = 0.82f, stiffness = 322f)`
- SwiftUI: `.spring(response: 0.35, dampingFraction: 0.82)`

Curvas simples (cor/opacidade): `ease-out` = cubic-bezier(0.2, 0, 0, 1).

---

## Interações

### M1 · Pressionar
- Botões: escala 1 → 0,97 ao tocar, volta a 1 ao soltar. Mola `toque`.
- Cartões e linhas tocáveis: escala 0,98 + fundo vai pra `surface-soft` em 120 ms.
- Botão primário: fundo `action` → `action-pressed` em 100 ms.
- Se o dedo sai do botão, cancela e volta.

### M2 · Abrir o scanner
- O botão "Escanear preço" vira a tela do scanner: o retângulo do botão cresce até a tela cheia (posição, tamanho e raio 16 → 0 juntos). Mola `navegacao`.
- O conteúdo do Comprar escala 1 → 0,94 e escurece (opacidade de uma camada preta 0 → 0,3) atrás.
- Controles do scanner (fechar, pílula, lanterna) entram com opacidade 0 → 1 em 200 ms, começando 120 ms depois.
- Fechar: caminho inverso, voltando pro botão.

### M3 · Preço travado e item adicionado (a interação mais importante)
Sequência, a partir da leitura confirmada:
- **M3a (0 ms)** Cantos do visor se ajustam ao retângulo da etiqueta lida. Mola `cartao`. Háptico leve. Som curto (se ligado). Selo "Preço travado" entra com opacidade em 150 ms.
- **M3b (80 ms)** Folha inferior troca de conteúdo: o item anterior sai (y 0 → −12, opacidade 1 → 0, 150 ms) e o novo entra (y 16 → 0 com mola `confirmacao`, opacidade 0 → 1 em 180 ms). Ícone de check: escala 0,6 → 1 com `confirmacao`.
- **M3c (no carrinho)** A linha nova entra no topo da lista: altura 0 → natural com `cartao`, conteúdo y −8 → 0 e opacidade 0 → 1. As linhas abaixo descem com a mesma mola.
- Total e contador atualizam com M4 ao mesmo tempo que M3b.
- Háptico de sucesso só quando o item entra no carrinho (não a cada leitura).
- Depois de 600 ms os cantos voltam ao tamanho do visor com `cartao`, prontos pra próxima.

### M4 · Total mudando
- O número conta do valor antigo pro novo em 350 ms, ease-out, sempre em `tabular-nums` (as casas não pulam de lugar).
- Junto, escala 1 → 1,04 → 1 com mola `confirmacao`.
- Diferença maior que 50 vezes o passo: pula a contagem e só faz a troca com opacidade (evita rolagem longa).
- Movimento reduzido: troca direta.

### M5 · Folhas (Detalhe do item, Orçamento, Digitar preço, Organizar)
- Abrir: y 100% → 0 com mola `folha`. Fundo escurece 0 → 0,4 em 250 ms linear.
- Arrastar: a folha segue o dedo 1:1 pra baixo; pra cima, resistência (deslocamento × 0,3).
- Soltar: fecha se passou de 30% da altura **ou** velocidade pra baixo > 800 px/s. A mola parte com a velocidade do dedo.
- Teclado abrindo: a folha sobe junto com a mesma curva do teclado do sistema.

### M6 · Controle segmentado e abas
- Segmentado: o fundo branco desliza até o segmento escolhido, mola `selecao`. Texto troca de cor em 150 ms.
- Abas: ícone e rótulo trocam de cor em 150 ms. Conteúdo troca com opacidade em 180 ms (sem deslizar, como no iOS).
- Toque na aba ativa: rola o conteúdo pro topo com mola `navegacao`.

### M7 · Empurrar tela (Lista, Finalizar, Ajustes)
- Entra: nova tela x 100% → 0. A anterior vai x 0 → −30% e escurece 0 → 0,1. Mola `navegacao`.
- Voltar por gesto da borda: segue o dedo, conclui se passou de 40% ou velocidade > 500 px/s, herdando a velocidade.

### M8 · Desfazer
- No scanner: a folha volta pro item anterior com o inverso de M3b; a linha sai da lista com altura → 0 (`cartao`); total faz M4.
- Remover item no carrinho: linha desliza pra esquerda e some, toast "Item tirado. Desfazer" sobe de baixo (`folha`), fica 4 s.

### M9 · Barras de progresso
- Largura anima com `cartao` sempre que o valor muda. Nunca anima ao abrir a tela pela primeira vez (já aparece no valor).

### M10 · Entrada da boas-vindas
- Wordmark, ilustração, título, benefícios e botão entram em sequência: y 12 → 0 + opacidade, mola `cartao`, 40 ms entre cada.
- O selo "No carrinho" entra por último com escala 0,8 → 1 (`confirmacao`), mostrando o que o app faz.

### M11 · Concluir compra
- Botão vira check (rótulo some 120 ms, check entra com `confirmacao`), háptico de sucesso.
- 300 ms depois, navega pro Histórico; a compra nova entra no topo com M3c.

### M12 · Marcar item da lista
- Check: escala 0,8 → 1 com `confirmacao`. Texto vai pra `text-secondary` e o rótulo "No carrinho" entra com opacidade em 150 ms.
- Quando o scanner marca o item sozinho, a faixa "2 de 6" no Comprar atualiza com M4 e M9.

---

## Háptico e som

| Momento | Háptico | Som |
| --- | --- | --- |
| Preço travado | leve | estalo curto (opcional) |
| Item no carrinho | sucesso | — |
| Passou do orçamento | aviso | — |
| Desfazer | leve | — |
| Concluir compra | sucesso | som de conclusão (opcional) |

Respeitar o modo silencioso e os switches de Ajustes.

## Desempenho
- Animar só `transform` e `opacity` sempre que possível; altura apenas em M3c e M8.
- Rodar as molas na thread de interface/animação, nunca esperando a lógica do app.
- No scanner, nenhuma animação pode atrasar a leitura: o processamento dos quadros da câmera roda separado e nunca espera uma animação terminar.
