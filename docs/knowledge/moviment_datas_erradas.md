# MOVIMENT — Datas Erradas (Caixa Aberto Vários Dias)

## Problema

Quando um caixa fica aberto por vários dias (ex: 13/06 a 30/06), alguns pedidos podem ter o MOVIMENT gravado com `DATA_PATO` = data do fechamento em vez da data da venda.

**Sintoma:** Pedido de 13/06 aparece no MOVIMENT com `DATA_PATO=30/06`. Consultas que filtram por data não encontram o registro no dia correto.

## Diagnóstico

```sql
-- Comparar data do pedido vs data no MOVIMENT
SELECT p.codigo, p.dataemissao, m.tipovenda, m.valor, m.data_pato
FROM pedidos p
JOIN moviment m ON m.codigo = p.financeiro
WHERE p.codigo = <numero_pedido>
ORDER BY m.parcela
```

Se `p.dataemissao` ≠ `m.data_pato` → datas erradas.

## Fix

```sql
UPDATE moviment
SET data_pato = '<data_venda>',
    data_venc = '<data_venda>'
WHERE codigo = <financeiro>;

UPDATE refs
SET data_emissao = '<data_venda>',
    data_venc    = '<data_venda>'
WHERE codigo = <financeiro>;
```

## Campos de data

**MOVIMENT:**
- `DATA_PATO` — data do pagamento/movimento
- `DATA_VENC` — data de vencimento

**REFS:**
- `DATA_EMISSAO` — data de emissão
- `DATA_VENC` — data de vencimento
- `DATA_PGTP` — data de pagamento
- `DATA_BAIXA` — data de baixa

## Caso real

- Banco: `CEM_menezes030726.FDB`
- Pedido: 340656 | Financeiro: 303230
- Caixa 1752 aberto em 13/06/2026, fechado em 30/06/2026 (17 dias)
- MOVIMENT gravou DATA_PATO=30/06 em vez de 13/06
