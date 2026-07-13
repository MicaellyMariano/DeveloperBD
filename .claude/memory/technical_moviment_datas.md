---
name: technical-moviment-datas
description: MOVIMENT com DATA_PATO errada (data do fechamento do caixa em vez da data da venda) — caixa aberto por vários dias causa isso
metadata: 
  node_type: memory
  type: project
  originSessionId: a100ae82-53d4-4114-8172-c23e8386b847
---

## MOVIMENT com data do fechamento em vez da data da venda

Quando um caixa fica aberto por vários dias (ex: 13/06 a 30/06), alguns pedidos podem ter o MOVIMENT gravado com `DATA_PATO` = data do fechamento (30/06) em vez da data da venda (13/06).

**Sintoma:** Pedido de 13/06 aparece no MOVIMENT com DATA_PATO=30/06. Consultas que filtram MOVIMENT por data não encontram o registro no dia correto.

**Tabelas afetadas:** MOVIMENT e REFS (DATA_EMISSAO, DATA_VENC).

**Fix:**
```sql
UPDATE moviment SET data_pato = '<data_venda>', data_venc = '<data_venda>'
WHERE codigo = <financeiro>;

UPDATE refs SET data_emissao = '<data_venda>', data_venc = '<data_venda>'
WHERE codigo = <financeiro>;
```

**Why:** Encontrado em CEM_menezes030726.FDB, pedido 340656, financeiro 303230. Caixa 1752 ficou aberto 17 dias (13/06 a 30/06).

**How to apply:** Ao investigar pedido com data errada no financeiro, verificar `DATA_PATO` no MOVIMENT vs `DATAEMISSAO` no PEDIDOS. Se divergirem e o caixa ficou aberto vários dias, é esse o motivo.

## Campos de data no MOVIMENT
- `DATA_PATO` — data do pagamento/movimento
- `DATA_VENC` — data de vencimento

## Campos de data no REFS
- `DATA_EMISSAO` — data de emissão
- `DATA_VENC` — data de vencimento
- `DATA_PGTP` — data de pagamento
- `DATA_BAIXA` — data de baixa
