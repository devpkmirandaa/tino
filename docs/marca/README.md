# Tino

**Comprar bem começa antes.**

Aplicativo brasileiro gratuito, sem anúncios e open source. A câmera identifica preços no supermercado; soma automática durante a compra, listas, orçamento e cálculo de itens por peso. No futuro: mapa de mercados, colaboração e comparação de preços. Público prioritário: jovens adultos brasileiros.

> Fonte: *Manual de marca provisório v0.2* (24 out 2026). Não substitui o manual definitivo. O que está marcado como **definido** se preserva; o que está **exploratório** ou **pendente** não deve ser tratado como especificação.

| Área | Situação |
| --- | --- |
| Paleta, tokens claro/escuro | definida |
| Tipografia | definida |
| Grid, espaçamento, raios | definidos |
| Iconografia | decisão fechada |
| Motion | direção fechada; parâmetros provisórios |
| Símbolo (saúva) | conceito definido; desenho pendente |
| Wordmark "Tino" | desenhado (positivo e negativo) |
| Lockups, área de proteção, tamanhos mínimos | pendentes |
| Ícone do app | não existe ainda |
| UI Kit | exploratório, não aprovado |

## Essência

Conceito: sensatez, discernimento, prudência, previsão e orientação.

Personalidade: sensata, simples, ágil, amigável, serena, transparente e colaborativa.

Linguagem: minimalista, geométrica, contemporânea, funcional, amigável, sem frieza corporativa.

### Voz

O Tino fala como alguém prudente do lado de quem compra: frase curta, verbo no imperativo gentil, número em destaque, nada de exclamação vendedora.

- Sim: "Aponte a câmera para a etiqueta." · "Faltam R$ 32,60 do orçamento." · "Não deu pra ler o preço. Quer digitar?"
- Não: "Uau! Economize já!!" · "Ops, algo deu errado 😅" · jargão técnico em mensagens de erro.

## Símbolo e marca

Símbolo escolhido: **formiga saúva (Atta)**, metáfora de coleta, organização, inteligência coletiva e cooperação. Deve ser original, sintético, geométrico, escalável, sem estética infantil ou caricata.

**O símbolo vetorial da saúva ainda não existe.** Não desenhar saúva provisória em telas, e não confundir a saúva com ícones funcionais da interface.

### Wordmark

O wordmark "Tino" é desenho próprio (não é texto em Plus Jakarta Sans): minúsculo, geométrico, terminais arredondados, pingo do i em círculo. Sempre usar o arquivo, nunca recompor com fonte.

- Positivo `tino-wordmark.svg`, tinta `grafite-profundo`: fundos claros (`canvas` claro, `surface`, `branco-suave`, `jade-claro`, `azul-glacial`).
- Negativo `tino-wordmark-negativo.svg`, tinta `off-white-frio`: fundos escuros (`canvas` escuro, `grafite-profundo`, `jade-profundo`).
- Sem distorcer, contornar, aplicar sombra ou outras cores.

Próximos entregáveis: 1. símbolo vetorial da saúva; 2. lockups símbolo + wordmark; 3. versões, área de proteção, tamanhos mínimos e monocromia; 4. ícone do app, splash e aplicações claro/escuro; 5. manual definitivo, exportações e tokens.

## Cor

Seis cores fixas formam a paleta oficial: `jade-profundo` #246B55, `jade-claro` #ABD8C5, `azul-glacial` #C8E1ED, `off-white-frio` #F5F7F6, `grafite-profundo` #16221F, `branco-suave` #EAF1EE.

Na interface, use sempre os tokens semânticos, nunca o hex da paleta direto:

- Fundo de tela `canvas`; cartões e inputs `surface`; áreas de apoio `surface-soft`.
- Texto `text-primary`; apoio e ícone inativo `text-secondary`.
- Ação primária `action` com `on-action` por cima; pressionado `action-pressed`.
- Informação: fundo `info` com texto `grafite-profundo` (nos dois temas).
- Divisórias `border`; contorno de input e controle `border-strong` (a `border` fica abaixo de 3:1).
- `jade-tint` e `blue-tint` só existem no escuro.

O modo escuro é **grafite neutro**, não verde/petróleo dominante. `border-strong` e `action-pressed` são auxiliares exploratórios e não ampliam a paleta oficial.

## Tipografia

**Plus Jakarta Sans** (SIL OFL 1.1, Google Fonts). Pesos: 400 corpo, 500 apoio, 600 subtítulos/rótulos, 700 títulos/preços.

| Estilo | px / altura | Peso |
| --- | --- | --- |
| display | 32 / 40 | 700 |
| tela | 24 / 32 | 700 |
| seção | 20 / 28 | 700 |
| subtítulo | 18 / 26 | 600 |
| corpo | 16 / 24 | 400 |
| secundário | 14 / 20 | 500 |
| label | 14 / 20 | 600 |
| caption | 12 / 16 | 500 |

Dinheiro: numerais tabulares (`font-variant-numeric: tabular-nums`) e alinhamento à direita em colunas monetárias. Preço em 700.

## Grid, espaçamento e geometria

Escala de 4 pt: `space-4` 4 · `space-8` 8 · `space-12` 12 · `space-16` 16 · `space-24` 24 · `space-32` 32 · `space-48` 48.

- Mobile: 4 colunas, margem 16 dp, gap 12, padding de cartão 16, seção 24–32.
- Tablet: 8 colunas, margem 24, gap 16.
- Layout fluido, leitura prioritária.

Raios: cartão principal `radius-card` 20, compacto `radius-card-compact` 16, botão/input `radius-control` 12, modal/painel `radius-panel` 24, chip `radius-chip` 8 ou `radius-pill`.

Bordas 1 px. Elevação muito discreta, sobretudo no escuro (o manual não fixa valores de sombra; prefira borda a sombra).

## Iconografia

**Lucide, exclusivamente Outline, nunca Filled.** Traço 2 px, tamanho padrão 24 px, compacto 20 px, cantos e terminais arredondados.

- Ativo: só a cor do contorno muda, para `action` (#246B55 claro / #ABD8C5 escuro).
- Inativo: `text-secondary` (#52655E / #AFC1BB).
- Nunca mudar preenchimento, espessura ou geometria entre estados.
- Navegação principal de preferência com rótulos.
- Preservar a licença do Lucide (ISC) nos créditos do app.

## Motion

Spring suave, inspirado na fluidez do iOS: inércia leve, continuidade, desaceleração natural e acomodação sem quicar em excesso. Parâmetros provisórios:

| Interação | Duração |
| --- | --- |
| toque | 180–220 ms |
| seleção | 220–280 ms |
| cartão | 300–380 ms |
| navegação | 350–450 ms |
| modal / painel | 400–500 ms |
| confirmação | 300–400 ms |

Spring em deslocamento e escala; cor com transição simples. Mola física interrompível quando viável. Respeitar movimento reduzido e evitar animação contínua no scanner.

## Componentes

O UI Kit ainda é **exploratório** (avaliação do primeiro kit: "bom, não excelente") e por isso não entra aqui como componente validado. Referências mínimas já fixadas pelo manual:

- Botões primário, secundário, contornado e texto: altura mínima `touch-target` 48, raio `radius-control` 12.
- Input: `input-height` 52, raio 12, contorno `border-strong`.
- Cartão: raio `radius-card` 20, padding `space-16`.
- A refinar em contexto real com o Codex: chips, switch, checkbox, progresso de orçamento, navegação, toast, scanner, preço/peso, quantidade, correção, erro, carregamento e diálogos.

## Acessibilidade

Metas: WCAG AA; texto ≥4,5:1; controles e ícones ≥3:1; toque ~48×48 dp; escala dinâmica de texto; estados que não dependam só de cor. Todos os pares de texto dos tokens passam AA nos dois temas. Validar na beta: contraste, responsividade, legibilidade de preços, dispositivos reais e parâmetros físicos do motion.

## Continuidade

Preserve tudo que está definido. Não invente símbolo, lockup, ícone final ou componentes validados. Distinga identidade visual de interface do produto. Ao propor mudança, justifique e peça aprovação antes de substituir tokens ou escolhas. Prioridade: identidade central (saúva + logotipo), enquanto a UI é refinada em implementação real.
