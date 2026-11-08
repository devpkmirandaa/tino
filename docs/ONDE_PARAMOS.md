# Onde paramos (7 nov 2026)

**Pronto:** etapas 1–4 do design (tema claro/escuro, componentes, três abas, Comprar, Scanner). Scanner escuro com visor sobre a moldura do OCR, folha inferior e M2, M3 (a–c) e M4; leitura isolada em `ScanReader`. Item por unidade com nome entra sozinho ao travar (sem duplicar em 3 s); Desfazer volta o carrinho e desmarca a lista; preço diferente pergunta na folha ("Atualizar para R$ X" · "Manter R$ Y", que descarta a leitura nova · "Somar como outro", botão de texto, linha separada no preço novo). Mesmos três botões na Digitar preço.

**Telas complementares, etapa 1 (Tema + Ajustes):** Ajustes no visual de `telas/10`: chaves "Adicionar ao travar o preço" e "Vibrar ao ler" (ligadas por padrão, valem no scanner), Aparência Automático | Claro | Escuro guardada no aparelho (app e folha do scanner seguem a escolha), Sobre com licenças (Lucide ISC e OFL da fonte) e "Rever apresentação", rodapé com a versão (`package_info_plus`).

**Etapa 2 (Detalhe do item):** folha nova `item_detail_sheet.dart` no visual de `telas/05` (M5, M6), só para item já no carrinho: tocar na linha do Comprar ou no lápis do scanner depois de adicionar. "Na etiqueta: …" vem do texto cru do nome (`tagText`, guardado no banco, versão 6). "Tirar do carrinho": linha sai pra esquerda e aviso "Item tirado. Desfazer" por 4 s, que volta o item ao mesmo lugar (M8). Rascunho do scanner e Digitar preço seguem na folha antiga até a etapa 3.

**Etapa 2b (atacado como nome):** a escolha do nome descarta linhas de atacado/varejo ("A PARTIR DE 10 UN", "PARTIR DE 10 UN", "PREÇO ATACADO") em qualquer posição; leitura de preço intacta.

**Etapa 3 (Digitar preço):** folha nova `type_price_sheet.dart` (`telas/11`), com teclado do celular e folha acima dele. Abre pelos botões "Digitar preço", pelo "Digitar" do scanner e pelo rascunho do scanner; título segue o que abriu ("Informar peso", "Dar nome" ou "Digitar preço") e o foco vai ao campo que falta. Nome opcional: vazio fica gravado vazio e aparece "Sem nome" em `text-secondary`; não soma, não abre conflito, não risca lista. Conflito de preço com o mesmo bloco e regra do scanner (`PriceConflictBlock`). Item novo entra com M3c. Folha antiga "Adicionar/Editar produto" removida.

**Etapa 4 (Orçamento):** folha nova `budget_sheet.dart` (`telas/12`): valor em 64 com texto 24/32 (28 fica fora da escala), atalhos R$ 100/150/200/300 (chip escolhido com borda 2 `action`), "Usar R$ X" e "Compra sem orçamento". Novo aviso de 90%: vibra uma vez ~300 ms depois de passar de 90% por gasto, se "Avisar quando faltar pouco" estiver ligado (chave no aparelho, ligada por padrão; `budget_alert.dart`). A chave controla o aviso de 90% inteiro (faixa "Perto do limite" e vibração); "Passou do orçamento" continua sempre. Não vibra quando o 90% é alcançado mudando o orçamento, nem quando a compra pula direto para além de 100% (log `tino-orçamento` no `flutter run` mostra cada mudança de estado).

**Ajustes antes da etapa 5:** vibração direta pelo `Vibrator` do Android (canal `tino/vibration` no `MainActivity`, permissão `VIBRATE`), uso de mídia: vibra no modo silencioso e não depende da "vibração ao tocar"; padrões leve 30 ms (era 20 ms e não vibrava no Desfazer), sucesso 40 ms, aviso 2 × 30 ms com 120 ms (motion.md atualizado). "Vibrar ao ler" passa a valer também para o Desfazer do scanner. Orçamento no Comprar como `telas/04`, `04a` e `04b`: "Faltam R$ X" / "de R$ Y" + chip "Mudar"; perto do limite, faixa `info` com "Você já usou N%" (arredondado para baixo); passou, barra em `text-primary` e faixa invertida.

**Falta nas folhas:** ícone de balança no segmento "Por quilo" (Detalhe e Digitar preço juntas); o segmentado ainda só tem texto.

**Falta no scanner:** mensagem "Não deu pra ler o preço. Quer digitar?" após tempo sem leitura (etapa 5); M8 inverso na folha; regra "50× o passo" do M4 sem definição; preço da folha em 32 (spec pede 28, fora da escala).

**Etapa de atacado (pendente):** mínimo do atacado só é lido com "a partir de" completo; com o "A" perdido ("PARTIR DE 10 UN") o preço de atacado entra, mas o mínimo fica para digitar (`_bulk`/`_minQty` em `tag_reader.dart`).

**Testar no aparelho:** vibração ao adicionar, no Desfazer, a 90% e a 100%, nos modos normal, vibrar e silencioso, e com as chaves desligadas; faixas de perto do limite e de passou no claro e no escuro; "Mudar". Orçamento pelo chip e pela barra; atalhos e valor digitado; passar de 90% com a chave ligada (vibra) e desligada (não vibra), inclusive pelo scanner; "Compra sem orçamento". Digitar preço por unidade e por quilo, com e sem nome; a folha inteira visível acima do teclado; "Informar peso" e "Dar nome" vindos do scanner; nome já no carrinho com outro preço abre o conflito; item novo entra no topo com M3c. Etiqueta com "A partir de 10 UN" mostra o nome do produto, não a linha do atacado. Abrir um item do Comprar, corrigir preço, quantidade, trocar para Por quilo e salvar; arrastar a folha pra baixo; "Tirar do carrinho" e "Desfazer"; item escaneado mostra "Na etiqueta: …" (itens antigos não têm). Migração do banco 5 → 6 roda na primeira abertura.

**Próximo passo:** etapa 5, câmera e falha de leitura (`telas/14`, `telas/15`, `telas/03c`). A memória de nomes corrigidos fica para uma etapa própria.

**Depois das 9 etapas (aguardam decisão, não implementar):**
- Sons: o app não toca som; falta decidir se haverá e quais.
- Enviar recortes das etiquetas: coleta opcional para treinar a Saúva (desligada por padrão, só a imagem do preço).
- Apoiar o Tino: falta definir o destino.
- Folha do item com esqueletos de carregamento, aberta assim que houver imagem suficiente, para a pessoa tirar o celular da etiqueta enquanto a leitura termina.

`.vscode/` é configuração local e não vai para o Git.
