# Tino · Pacote de design para implementação

Versão 1 · 6 nov 2026 · base: Manual de marca provisório v0.2 e o canvas "Tino — Mapa de telas".

Coloque esta pasta na raiz do projeto como `design/` e peça ao Claude Code pra ler este arquivo primeiro.

## O que tem aqui

| Caminho | O que é |
| --- | --- |
| `tokens/tokens.json` | Cores (claro e escuro), tipografia, espaçamento, raios e tamanhos. Fonte única de valores. |
| `assets/tino-wordmark.svg` | Wordmark positivo. Usar o arquivo, nunca recompor com fonte. |
| `telas/*.html` | Referência visual das 11 telas, 390 × 844. Abra `telas/00-mapa.html` e navegue clicando. |
| `specs/telas.md` | O que cada tela faz, componentes, estados, regras de texto e acessibilidade. |
| `motion/motion.md` | Molas, coreografia de cada interação (M1 a M12), háptico e som. |
| `motion/prototipo.html` | As animações principais rodando de verdade, com câmera lenta e movimento reduzido. |

## Regras pra implementar

1. **Tokens primeiro.** Gerar o tema do app a partir de `tokens/tokens.json` (claro e escuro) antes de qualquer tela. Nenhum hex solto no código das telas.
2. **Os HTML são referência visual, não código pra copiar.** Medidas, cores e textos valem; a estrutura HTML não.
3. **Ícones:** Lucide, só contorno, traço 2, tamanho 24 (compacto 20). Ativo muda só a cor do contorno.
4. **Fonte:** Plus Jakarta Sans 400, 500, 600 e 700. Dinheiro sempre com números tabulares.
5. **Motion:** criar um módulo único com as seis molas de `motion/motion.md` e usar só elas. Respeitar movimento reduzido do sistema.
6. **Textos:** usar exatamente os textos das telas; mudar só se a spec mandar.

## Ordem sugerida

1. Tema (tokens), fonte, ícones e o módulo de molas.
2. Componentes base da tabela em `specs/telas.md` com o pressionar (M1).
3. Navegação de 3 abas + Comprar vazio e com itens.
4. Scanner com M2, M3 e M4 (o coração do app).
5. Detalhe do item (folha, M5 e M6).
6. Finalizar, Listas, Lista, Histórico, Ajustes.
7. Boas-vindas com M10.

## Pendências de marca

- O arquivo do wordmark negativo do design system está igual ao positivo (tinta escura). Até corrigir, não usar wordmark em fundo escuro.
- Total em 40 px e botão de escanear com 64 px fogem da escala do manual e estão aguardando aprovação.
- Símbolo da saúva e ícone do app ainda não existem: não desenhar versões provisórias.

## Pedido sugerido pro Claude Code

> Leia `design/README.md`, `design/specs/telas.md` e `design/motion/motion.md`. Comece pelo passo 1 da ordem sugerida: gere o tema a partir de `design/tokens/tokens.json` e o módulo de molas, sem mexer em telas ainda. Me mostre o plano antes de editar.
