# Onde paramos (7 nov 2026)

**Pronto:** etapas 1–4 do design (tema claro/escuro, componentes, três abas, Comprar, Scanner). Scanner escuro com visor sobre a moldura do OCR, folha inferior e M2, M3 (a–c) e M4; leitura isolada em `ScanReader`. Item por unidade com nome entra sozinho ao travar (sem duplicar em 3 s); Desfazer volta o carrinho e desmarca a lista; preço diferente pergunta na folha (Usar R$ X · Manter R$ Y, que descarta a leitura nova · Somar como outro).

**Telas complementares, etapa 1 (Tema + Ajustes):** Ajustes no visual de `telas/10`: chaves "Adicionar ao travar o preço" e "Vibrar ao ler" (ligadas por padrão, valem no scanner), Aparência Automático | Claro | Escuro guardada no aparelho (app e folha do scanner seguem a escolha), Sobre com licenças (Lucide ISC registrada) e "Rever apresentação", rodapé com a versão (`package_info_plus`). Sons, recortes de etiqueta e Apoiar ficam escondidos até existirem.

**Falta no scanner:** mensagem "Não deu pra ler o preço. Quer digitar?" após tempo sem leitura (etapa 5); M8 inverso na folha; regra "50× o passo" do M4 sem definição; preço da folha em 32 (spec pede 28, fora da escala).

**Testar no aparelho:** trocar a aparência e ver o app e a folha do scanner mudarem; desligar "Adicionar ao travar" e conferir que o item só entra no "Adicionar"; desligar "Vibrar ao ler"; licenças e versão. Pendências anteriores do scanner seguem valendo.

**Próximo passo:** etapa 2, Detalhe do item (`telas/05`, M5 e M6). Aprovado: passar o texto bruto da etiqueta do leitor até a folha ("Na etiqueta: …"). A memória de nomes corrigidos fica para uma etapa própria.

**Depois das 9 etapas (aguardam decisão, não implementar):**
- Sons: o app não toca som; falta decidir se haverá e quais.
- Enviar recortes das etiquetas: coleta opcional para treinar a Saúva (desligada por padrão, só a imagem do preço).
- Apoiar o Tino: falta definir o destino.

`.vscode/` é configuração local e não vai para o Git.
