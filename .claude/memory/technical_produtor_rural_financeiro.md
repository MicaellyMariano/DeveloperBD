---
name: technical_produtor_rural_financeiro
description: Compra de produtor rural gera 2 documentos fiscais mas só 1 lançamento financeiro
metadata: 
  node_type: memory
  type: project
  originSessionId: a100ae82-53d4-4114-8172-c23e8386b847
---

## Produtor Rural — dois documentos, um pagamento

**Situação:** ao comprar de produtor rural, o sistema pode ter dois lançamentos no financeiro para a mesma compra:

1. **Nota do produtor (azul)** — emitida pelo produtor rural; lançada no financeiro para não perder o prazo de pagamento
2. **Nota fiscal de entrada / contra-partida (vermelho)** — emitida pela própria empresa como exigência contábil (escritório pede para produtores rurais)

**O erro:** lançar as duas no financeiro gera duplicidade — aparece uma conta a pagar vencida sem motivo.

**Regra:** são dois documentos fiscais da **mesma compra** e do **mesmo pagamento**. Só a nota do produtor fica no financeiro. A nota de entrada é apenas fiscal — o lançamento financeiro dela deve ser cancelado.

**How to apply:** sempre que cliente reportar conta a pagar duplicada com mesmo fornecedor, mesma data e mesmo valor, verificar se um dos dois é nota de contra-partida de produtor rural.
