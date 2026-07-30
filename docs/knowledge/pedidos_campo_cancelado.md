# PEDIDOS — Campo CANCELADO: valores possíveis

## Problema

O campo `PEDIDOS.CANCELADO` **não é booleano NULL/not-NULL**. Usar `WHERE CANCELADO IS NULL` para filtrar "não cancelados" está errado — exclui pedidos válidos com `CANCELADO='Não'`.

## Valores reais

| Valor | Significado |
|---|---|
| `NULL` | Pedido válido (mais antigos) |
| `'0'` | Pedido válido |
| `'Não'` | Pedido válido |
| `'Sim'` | Pedido **cancelado** |

## Filtro correto

```sql
-- Apenas não cancelados:
WHERE (ped.CANCELADO IS NULL OR ped.CANCELADO <> 'Sim')

-- Apenas cancelados:
WHERE ped.CANCELADO = 'Sim'
```

## Armadilha

Em Python, `'Não'` é truthy (`bool('Não') == True`), então:
```python
cancelado = 'CANCELADO' if r[3] else ''  # ERRADO — 'Não' aparece como CANCELADO
cancelado = 'CANCELADO' if r[3] == 'Sim' else ''  # CORRETO
```
