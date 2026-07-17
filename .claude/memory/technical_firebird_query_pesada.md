---
name: technical_firebird_query_pesada
description: Queries cross-período com auto-join em PEDIDOS travam IBExpert; usar LEFT JOIN anti-join ou Python dois passos
metadata: 
  node_type: memory
  type: project
  originSessionId: a100ae82-53d4-4114-8172-c23e8386b847
---

## Firebird — Queries pesadas com PEDIDOS (cross-período)

Queries que cruzam a tabela PEDIDOS com ela mesma (ex: clientes que compraram num período mas não em outro) travam o IBExpert em bases com 100k+ registros.

### Padrão que TRAVA

```sql
-- NOT EXISTS correlacionado = trava
WHERE NOT EXISTS (SELECT 1 FROM PEDIDOS p2 WHERE p2.CODCLI = c.CODIGO AND ...)
```

### Padrão otimizado para IBExpert — LEFT JOIN anti-join com subqueries derivadas

```sql
FROM CADASTRO c
INNER JOIN (
    SELECT CODCLI, COUNT(*) AS QTD, SUM(TOTALPEDIDO) AS TOTAL, MAX(DATAEMISSAO) AS ULTIMA
    FROM PEDIDOS
    WHERE TIPO = 'S' AND (CANCELADO IS NULL OR CANCELADO <> 'Sim') AND CODEMP = 1
      AND DATAEMISSAO BETWEEN '2025-01-01' AND '2025-12-31'
    GROUP BY CODCLI
) p25 ON p25.CODCLI = c.CODIGO
LEFT JOIN (
    SELECT DISTINCT CODCLI FROM PEDIDOS
    WHERE TIPO = 'S' AND (CANCELADO IS NULL OR CANCELADO <> 'Sim') AND CODEMP = 1
      AND DATAEMISSAO >= '2026-01-01'
) p26 ON p26.CODCLI = c.CODIGO
WHERE p26.CODCLI IS NULL
```

Firebird materializa subqueries derivadas no FROM antes do JOIN → muito mais eficiente.

### Alternativa via Python (dois passos — mais rápido ainda)

1. `SELECT DISTINCT CODCLI FROM PEDIDOS WHERE ... 2026` → set Python
2. `SELECT CODCLI, COUNT, SUM, MAX FROM PEDIDOS WHERE ... 2025 GROUP BY CODCLI` → filtrar em memória
3. Buscar cadastro em lotes de 100 com `WHERE CODIGO IN (?,...)`

Usado para gerar CSV/PDF de 333 clientes inativos da BASE_paraisodascaixas.

**Why:** IBExpert não tem timeout generoso; subquery correlacionada força varredura por linha; Python faz o filtro em memória sem sobrecarregar o Firebird.

**How to apply:** sempre que uma query "clientes que fizeram X mas não Y" travar no IBExpert, reescrever com subqueries derivadas no FROM ou usar Python dois passos.
