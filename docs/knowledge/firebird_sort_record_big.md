# Firebird — Sort Record Too Big

## Erro

```
sort record too big
```

## Causa

`SELECT *` em tabelas com muitas colunas (86+) estoura o limite de 64KB do Firebird para ordenação.

A tabela `REFS` no Sistema RAM tem 86+ colunas — `SELECT refs.*` com `ORDER BY` causa esse erro.

## Fix

Listar apenas as colunas necessárias em vez de usar `*`:

```sql
-- Errado:
SELECT refs.* FROM refs ORDER BY data_emissao

-- Correto:
SELECT codigo, parcela, tipovenda, valor, data_emissao, data_venc, data_pgtp, data_baixa, idcaixa
FROM refs ORDER BY data_emissao
```

## Regra geral

Evitar `SELECT *` com `ORDER BY` em tabelas grandes no Firebird. Preferir listar colunas explícitas.
