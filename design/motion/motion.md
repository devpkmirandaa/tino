# Tino · Motion (v2, 6 nov 2026)

Direção do manual: mola suave inspirada no iOS, com inércia, continuidade e desaceleração natural. **Na v2 o movimento fica mais evidente:** deslocamentos maiores, escala que se nota, e um quique curto no que confirma uma ação (item adicionado, check, total). Continua explicando de onde as coisas vêm e pra onde vão, nunca pra enfeitar.

Veja rodando: `motion/prototipo.html` (tem câmera lenta e modo de movimento reduzido).

## Regras gerais

1. **Mola em posição e escala; cor e opacidade com transição simples** (ease-out, 150–300 ms).
2. **Tudo interrompível.** Uma animação nova parte da posição e da velocidade atuais, nunca do começo. Gesto que solta herda a velocidade do dedo.
3. **Nada contínuo no scanner.** Sem linha de varredura, sem pulsar parado. O visor só se mexe quando trava.
4. **Origem espacial.** O que abre cresce de onde foi tocado; o que fecha volta pra lá.
5. **Quique só em confirmação.** Navegação e folhas acomodam sem quicar; item adicionado, check e total quicam uma vez, de leve.
6. **Defasagem entre elementos de um grupo:** 60 ms.
7. **Movimento reduzido:** trocar deslocamento e escala por troca de opacidade de 150 ms, sem contagem de números, sem quique.

## Molas

Massa 1 em todas. `response` e `amortecimento` são a notação da Apple; `rigidez` e `atrito` são as mesmas molas em física pura, pra qualquer biblioteca.

| Nome | Uso | response (s) | amortecimento | rigidez | atrito | Sensação |
| --- | --- | --- | --- | --- | --- | --- |
| `toque` | pressionar e soltar | 0,22 | 0,75 | 816 | 42,8 | afunda e volta com um repique curto |
| `selecao` | segmentado, aba, switch | 0,30 | 0,75 | 439 | 31,4 | desliza e assenta com leve passada |
| `cartao` | entrar/sair item, barra, cantos do visor | 0,40 | 0,72 | 247 | 22,6 | chega com uma pequena sobra |
| `confirmacao` | item adicionado, check, total | 0,45 | 0,58 | 195 | 16,2 | quique visível, uma vez |
| `navegacao` | empurrar tela, abrir scanner | 0,45 | 0,85 | 195 | 23,7 | longa e macia, quase sem sobra |
| `folha` | folhas e modais | 0,50 | 0,80 | 158 | 20,1 | sobe com peso e assenta |

Conversão usada: rigidez = (2π / response)², atrito = 4π · amortecimento / response.

No Flutter (o Tino), as mesmas molas:

```dart
const toque       = SpringDescription(mass: 1, stiffness: 816, damping: 42.8);
const selecao     = SpringDescription(mass: 1, stiffness: 439, damping: 31.4);
const cartao      = SpringDescription(mass: 1, stiffness: 247, damping: 22.6);
const confirmacao = SpringDescription(mass: 1, stiffness: 195, damping: 16.2);
const navegacao   = SpringDescription(mass: 1, stiffness: 195, damping: 23.7);
const folha       = SpringDescription(mass: 1, stiffness: 158, damping: 20.1);
```

Usar com `SpringSimulation` + `AnimationController.animateWith` (ou `animateWith` a partir do valor e da velocidade atuais, pra manter interrompível).

Curva simples (cor/opacidade/contagem): ease-out = `Cubic(0.2, 0, 0, 1)`.

---

## Interações

### M1 · Pressionar
- Botões: escala 1 → **0,94** ao tocar, volta a 1 ao soltar com mola `toque` (repique leve passando de 1).
- Cartões e linhas tocáveis: escala **0,96** + fundo vai pra `surface-soft` em 120 ms.
- Botão primário: fundo `action` → `action-pressed` em 100 ms.
- Se o dedo sai do botão, cancela e volta.

### M2 · Abrir o scanner
- O botão "Escanear preço" vira a tela do scanner: o retângulo do botão cresce até a tela cheia (posição, tamanho e raio 16 → 0 juntos). Mola `navegacao`.
- O conteúdo do Comprar escala 1 → **0,90** e escurece (camada preta 0 → **0,45**) atrás.
- Controles do scanner entram descendo: y −16 → 0 + opacidade 0 → 1, mola `cartao`, começando 140 ms depois.
- O visor entra com escala 1,15 → 1 (mola `cartao`), como se a câmera focasse.
- Fechar: caminho inverso, voltando pro botão.

### M3 · Preço travado e item adicionado (a interação mais importante)
Sequência, a partir da leitura confirmada:
- **M3a (0 ms)** Cantos do visor se fecham na etiqueta lida, com mola `confirmacao` (passam um pouco e voltam). O visor inteiro dá um "pulo" de escala 1 → 1,06 → 1. Cantos trocam de `jade-claro` pra branco por 250 ms e voltam. Háptico leve. Som curto (se ligado). Selo "Preço travado" entra com escala 0,7 → 1 (`confirmacao`) e opacidade 150 ms.
- **M3b (80 ms)** Folha inferior troca de conteúdo: o item anterior sai (y 0 → **−24**, opacidade 1 → 0, 180 ms) e o novo entra (y **32** → 0 com mola `confirmacao`, opacidade 0 → 1 em 200 ms). Ícone de check: escala **0,3** → 1 com `confirmacao`. O preço entra 60 ms depois do nome, com o mesmo movimento.
- **M3c (no carrinho)** A linha nova entra no topo da lista: altura 0 → natural com `cartao`, conteúdo y **−20** → 0, escala 0,96 → 1 e opacidade 0 → 1. Fundo da linha nova começa em `surface-soft` e esmaece pra `surface` em 900 ms, marcando o que acabou de entrar. As linhas abaixo descem com a mesma mola.
- Total e contador atualizam com M4 ao mesmo tempo que M3b.
- Háptico de sucesso só quando o item entra no carrinho (não a cada leitura).
- Depois de 600 ms os cantos voltam ao tamanho do visor com `cartao`, prontos pra próxima.

### M4 · Total mudando
- O número conta do valor antigo pro novo em 450 ms, ease-out, sempre em `tabular-nums`.
- Junto, escala 1 → ~**1,10** → 1 com mola `confirmacao` (um impulso de velocidade, não um valor fixo, pra acumular se vierem leituras seguidas).
- A cor do número vai pra `action` no impulso e volta pra `text-primary` em 500 ms.
- Diferença maior que 50 vezes o passo: pula a contagem e só faz a troca com opacidade.
- Movimento reduzido: troca direta.

### M5 · Folhas (Detalhe do item, Orçamento, Digitar preço, Organizar)
- Abrir: y 100% → 0 com mola `folha`. Fundo escurece 0 → 0,5 em 250 ms. A tela de trás escala 1 → 0,94 junto (efeito de cartão empilhado do iOS).
- Conteúdo da folha entra em cascata: cada bloco y 24 → 0 + opacidade, 60 ms entre eles, mola `cartao`.
- Arrastar: a folha segue o dedo 1:1 pra baixo; pra cima, resistência (deslocamento × 0,3). A tela de trás volta proporcionalmente.
- Soltar: fecha se passou de 30% da altura **ou** velocidade pra baixo > 800 px/s. A mola parte com a velocidade do dedo.
- Teclado abrindo: a folha sobe junto com a mesma curva do teclado do sistema.

### M6 · Controle segmentado e abas
- Segmentado: o fundo branco desliza até o segmento escolhido, mola `selecao`, e estica na direção do movimento enquanto anda (largura +12% no meio do caminho).
- Abas: o ícone da aba tocada dá um pulo de escala 0,85 → 1 com `confirmacao`; cor troca em 150 ms. Conteúdo troca com y 8 → 0 + opacidade em 200 ms.
- Toque na aba ativa: rola o conteúdo pro topo com mola `navegacao`.

### M7 · Empurrar tela (Lista, Finalizar, Ajustes)
- Entra: nova tela x 100% → 0. A anterior vai x 0 → −30%, escala 0,96 e escurece 0 → 0,2. Mola `navegacao`.
- Voltar por gesto da borda: segue o dedo, conclui se passou de 40% ou velocidade > 500 px/s, herdando a velocidade.

### M8 · Desfazer
- No scanner: a folha volta pro item anterior com o inverso de M3b; a linha sai da lista deslizando pra esquerda (x 0 → −80, opacidade → 0) e a altura fecha com `cartao`; total faz M4.
- Remover item no carrinho: mesma saída pra esquerda; toast "Item tirado. Desfazer" sobe de baixo (y 80 → 0, `confirmacao`), fica 4 s.

### M9 · Barras de progresso
- Largura anima com `cartao` (passa um pouco e volta) sempre que o valor muda. Nunca anima ao abrir a tela pela primeira vez.
- Passou do orçamento: a barra treme uma vez na horizontal (x 0 → 6 → −6 → 0 com `toque`) + háptico de aviso + texto "Passou R$ X".

### M10 · Entrada da boas-vindas
- Wordmark, ilustração, título, benefícios e botão entram em sequência: y **32** → 0 + opacidade, mola `cartao`, **60 ms** entre cada.
- A ilustração entra com escala 0,9 → 1.
- O selo "No carrinho" entra por último com escala **0,5** → 1 (`confirmacao`), mostrando o que o app faz.

### M11 · Concluir compra
- Botão vira check (rótulo some 120 ms, check entra com escala 0,3 → 1 em `confirmacao`), háptico de sucesso.
- 400 ms depois, navega pro Histórico; a compra nova entra no topo com M3c.

### M12 · Marcar item da lista
- Check: escala 0,5 → 1 com `confirmacao`. Texto vai pra `text-secondary` e o rótulo "No carrinho" entra com x 12 → 0 + opacidade.
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
- Animar só transformações e opacidade sempre que possível; altura apenas em M3c e M8.
- No Flutter: `Transform`/`FadeTransition` com `RepaintBoundary` nos itens que animam; nada de reconstruir a lista inteira por quadro.
- No scanner, nenhuma animação pode atrasar a leitura: o processamento dos quadros da câmera roda separado e nunca espera uma animação terminar.
