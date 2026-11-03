# Tino — contexto técnico

Consolidação de decisões recuperadas das conversas; não é o briefing original
integral. O que não foi recuperado está em "Pendências".

## Propósito e identidade

Tino = sensatez, prudência e previsão. Slogan: "Comprar bem começa antes."
Gratuito, open source, sem anúncios. Personalidade: minimalista, serena,
inteligente, acessível, amigável, contemporânea e brasileira. Símbolo: saúva
(não inventar símbolo definitivo a partir da descrição).

- Fonte: Plus Jakarta Sans.
- Ícones: Lucide, só outline, traço de 2 px; 24 px padrão, 20 px compacto.
  Estado ativo muda só a cor (jade no claro, jade claro no escuro), sem
  preenchimento nem mudança de espessura.
- Layout responsivo, espaçamento preferido de 20 px (não é regra para todo o
  sistema), botões outline, animações fluidas.
- Modo escuro: grafite neutro; tokens finais ainda não definidos.

| Cor | HEX |
| --- | --- |
| Jade | #246B55 |
| Jade claro | #ABD8C5 |
| Azul glacial | #C8E1ED |
| Off-white | #F5F7F6 |
| Quase preto | #16221F |
| Branco suave | #EAF1EE |

Azul glacial substitui o roxo de propostas antigas. Os nomes das cores podem mudar.

## Stack

Flutter + Dart · feature-first + Clean Architecture pragmática · Riverpod ·
GoRouter · Drift/SQLite · Google ML Kit (OCR inicial) · design system próprio ·
offline no MVP · Git/GitHub.

São direções, não dependências instaladas: confirme versões e wrappers antes de
adotar. Sem infraestrutura remota para funções locais. O ML Kit só reconhece
texto; associação produto/preço, repetições e unidade de venda são da aplicação.

## Escopo do MVP

Leitura ao vivo de etiquetas; associação nome/preço; confirmação, prevenção de
duplicatas e correção; carrinho com total antes do caixa; produtos por peso;
orçamento e alertas; lista de compras; histórico local; feedback leve
(sonoro/animado).

Fora do MVP: mapa de mercados, nuvem, comunidade/compartilhamento de preços
(opcional no futuro, com aviso antes do envio e experiência básica independente).

Navegação e fluxo: ver `MAPA_DE_TELAS.md`. Sem login. Câmera só no primeiro uso
do scanner.

## Estado atual

Repositório: https://github.com/devpkmirandaa/tino · local: `C:\Projetos\tino`.
Feitas: etapa 1 (base visual e navegação das cinco áreas), etapa 2
(apresentação e primeiro acesso, ver `ETAPA_2_APRESENTACAO.md`), etapa 3
(regras de cálculo), etapa 4a (carrinho manual em Comprar) e 4b (compra ativa
salva em Drift/SQLite: `lib/core/database/`, Drift 2.35.3, drift_flutter 0.3.1;
uma compra sem `finishedAt` é a ativa; cada alteração regrava seus itens).
Etapa 5: finalizar compra e Histórico com detalhe.
Não implementados: câmera/OCR, listas, apagar compras, resumo no Início.
Ver `../README.md` para o comportamento atual.

## Regras de cálculo (etapa 3)

Dart puro em `lib/features/shopping/domain/`, testado em
`test/shopping_domain_test.dart`.

- Dinheiro em centavos inteiros (`Money`), nunca `double`; formato R$ 1.234,56.
- Peso em gramas inteiras; preço por kg em centavos. Item por peso arredondado
  meio para cima no centavo (0,347 kg × R$ 39,90/kg = R$ 13,85).
- Total da compra = soma exata dos itens já arredondados.
- Duplicata (mesmo nome normalizado): mesmo preço soma a quantidade; preço
  diferente devolve conflito sem alterar o carrinho, para o usuário decidir.
  Itens por peso nunca são mesclados (cada pesagem é uma embalagem).
- Orçamento opcional e positivo: dentro; perto a partir de 90% (inclusive o
  valor exato); estourado acima dele.

## Pendências (não tratar como decisões)

- Texto integral do briefing original.
- Versões exatas dos pacotes de câmera, OCR e demais dependências.
- Confiança mínima do OCR; conferir o arredondamento real das balanças.
- Promoções, preço por unidade/kg, múltiplos preços na mesma etiqueta.
- Migrações futuras do banco; aviso visível se a gravação falhar (hoje só log).
- Textos finais do onboarding e das telas, tokens escuros definitivos.
- Licença do código e política de privacidade.