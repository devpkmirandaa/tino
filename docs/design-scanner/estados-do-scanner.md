# Estados do scanner (design de 7/nov)

Referência visual: os 4 arquivos `.dc.html` desta pasta (abrem no navegador). Seguem o mesmo visual do Scanner atual. Mudar só o que está descrito aqui.

## 3a · Preço diferente

Quando a leitura nova trava num item que já está no carrinho com outro preço.

- Título da folha: ícone de informação + "Já está no carrinho com outro preço" (cor secundária, não jade).
- Abaixo: nome do item e marca/peso, iguais ao estado "Adicionado".
- Dois blocos lado a lado:
  - "No carrinho": fundo tonal, preço atual.
  - "Leitura nova": borda de 2 px na cor de destaque, rótulo na cor de destaque, preço novo.
- Botão principal (cheio, largura total, 52 px): "Atualizar para R$ X".
- Botão secundário (contorno, 48 px): "Manter R$ Y". Ao tocar, mantém o carrinho e mostra "Mantido R$ Y no carrinho" (já está no código).
- Botão de texto (48 px), abaixo de "Manter": "Somar como outro". Entra como linha separada, no preço novo, e a folha mostra "Somado como outro item". O mesmo bloco e os mesmos três botões valem na folha Digitar preço.
- Rodapé: "Confira se a etiqueta é mesmo desse produto."
- O total no topo não muda até a escolha.

## 3b · Varejo e atacado

Só aparece quando a etiqueta tem preço de atacado.

- Folha "Adicionado ao carrinho" normal, com o preço de varejo.
- Entre o cabeçalho e a linha de quantidade, um seletor de 2 opções (fundo tonal, 4 px de respiro, raio 14):
  - Opção ativa: fundo cheio na cor principal, texto claro.
  - Cada opção: rótulo pequeno em cima ("Varejo" / "Atacado · 6+ un") e preço embaixo.
- Varejo vem marcado. Trocar muda o preço do item que acabou de entrar e não mexe na quantidade.
- Linha de quantidade, Desfazer e Corrigir continuam iguais.

## Tema escuro

Mesmas regras. Cor de destaque vira o jade claro, botão principal fica jade claro com texto escuro, blocos tonais usam a superfície elevada do tema escuro. Ver os arquivos `-escuro`.
