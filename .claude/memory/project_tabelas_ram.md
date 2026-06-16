---
name: project-tabelas-ram
description: Descrição das principais tabelas do banco de dados do Sistema RAM
metadata: 
  node_type: memory
  type: project
  originSessionId: a100ae82-53d4-4114-8172-c23e8386b847
---

Mapeamento das tabelas do Sistema RAM (Firebird/Delphi):

- **PRODUTOS** — Dados dos produtos cadastrados
- **ESTOQUE** — Movimentações de estoque dos produtos
- **SUGESTAOVENDA** — Itens filhos que compõem um combo/kit
- **PADRAOPRODUTOS** — Vínculos entre produtos e fornecedores
- **REFS** — Lançamentos financeiros e suas parcelas
- **MOVIMENT** — Baixas dos lançamentos financeiros da REFS
- **PEDIDOS** — Dados do pedido (orçamentos, pedidos e PDV)
- **ITENSPAD** — Itens dos pedidos armazenados em PEDIDOS
- **CONF_IMP_CAMPOS** — Opções da esteira de configuração de custo da tela de entrada de produtos por XML

**Why:** Definição oficial fornecida pela usuária para evitar confusões nas consultas.
**How to apply:** Usar sempre esses conceitos ao analisar queries, erros e estrutura do banco.
