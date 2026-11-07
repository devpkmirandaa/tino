# Onde paramos (7 nov 2026)

**Pronto:** etapas 1–4 do design (tema claro/escuro, componentes, três abas, Comprar, Scanner). Scanner escuro com visor sobre a moldura do OCR, folha inferior e M2, M3 (a–c) e M4; leitura isolada em `ScanReader`. Item por unidade com nome entra sozinho ao travar (sem duplicar em 3 s); Desfazer volta o carrinho e desmarca a lista; preço diferente pergunta na folha (Usar R$ X · Manter R$ Y, que descarta a leitura nova · Somar como outro).

**Telas complementares, etapa 1 (Tema + Ajustes):** Ajustes no visual de `telas/10`: chaves "Adicionar ao travar o preço" e "Vibrar ao ler" (ligadas por padrão, valem no scanner), Aparência Automático | Claro | Escuro guardada no aparelho (app e folha do scanner seguem a escolha), Sobre com licenças (Lucide ISC e OFL da fonte) e "Rever apresentação", rodapé com a versão (`package_info_plus`).

**Etapa 2 (Detalhe do item):** folha nova `item_detail_sheet.dart` no visual de `telas/05` (M5, M6), só para item já no carrinho: tocar na linha do Comprar ou no lápis do scanner depois de adicionar. "Na etiqueta: …" vem do texto cru do nome (`tagText`, guardado no banco, versão 6). "Tirar do carrinho": linha sai pra esquerda e aviso "Item tirado. Desfazer" por 4 s, que volta o item ao mesmo lugar (M8). Rascunho do scanner e Digitar preço seguem na folha antiga até a etapa 3.

**Etapa 2b (atacado como nome):** a escolha do nome descarta linhas de atacado/varejo ("A PARTIR DE 10 UN", "PARTIR DE 10 UN", "PREÇO ATACADO") em qualquer posição; leitura de preço intacta.

**Falta no scanner:** mensagem "Não deu pra ler o preço. Quer digitar?" após tempo sem leitura (etapa 5); M8 inverso na folha; regra "50× o passo" do M4 sem definição; preço da folha em 32 (spec pede 28, fora da escala).

**Etapa de atacado (pendente):** mínimo do atacado só é lido com "a partir de" completo; com o "A" perdido ("PARTIR DE 10 UN") o preço de atacado entra, mas o mínimo fica para digitar (`_bulk`/`_minQty` em `tag_reader.dart`).

**Testar no aparelho:** etiqueta com "A partir de 10 UN" mostra o nome do produto, não a linha do atacado. Abrir um item do Comprar, corrigir preço, quantidade, trocar para Por quilo e salvar; arrastar a folha pra baixo; "Tirar do carrinho" e "Desfazer"; item escaneado mostra "Na etiqueta: …" (itens antigos não têm). Migração do banco 5 → 6 roda na primeira abertura.

**Próximo passo:** etapa 3, Digitar preço (`telas/11`): visual novo da folha "Adicionar produto", com o rascunho do scanner. A memória de nomes corrigidos fica para uma etapa própria.

**Depois das 9 etapas (aguardam decisão, não implementar):**
- Sons: o app não toca som; falta decidir se haverá e quais.
- Enviar recortes das etiquetas: coleta opcional para treinar a Saúva (desligada por padrão, só a imagem do preço).
- Apoiar o Tino: falta definir o destino.
- Folha do item com esqueletos de carregamento, aberta assim que houver imagem suficiente, para a pessoa tirar o celular da etiqueta enquanto a leitura termina.

`.vscode/` é configuração local e não vai para o Git.
