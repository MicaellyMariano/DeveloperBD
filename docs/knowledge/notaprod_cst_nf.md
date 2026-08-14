# NOTAPROD — CST real da NF e estrutura de ligação

## Tabelas

| Tabela | Descrição |
|---|---|
| `NOTA` | Cabeçalho da NF emitida (saída) |
| `NOTAPROD` | Itens da NF com dados fiscais reais |

## Campo CST real

```
NOTAPROD.NFP_SITU = CST gravado na NF (o que saiu na nota)
```

Esse é o campo correto para relatórios fiscais — reflete o que foi efetivamente transmitido à SEFAZ, não o cadastro do produto.

## Ligação com PEDIDOS

```sql
NOTA.NF_PEDIDO  →  PEDIDOS.CODIGO
NOTAPROD.NF_NUMERO + NOTAPROD.CODEMP  →  NOTA.NF_NUMERO + NOTA.CODEMP
NOTAPROD.NFP_CODPROD  →  PRODUTOS.CODIGO
```

## JOIN para relatório fiscal

```sql
LEFT JOIN (
    SELECT n.NF_PEDIDO, np.NFP_CODPROD, n.CODEMP,
           MIN(np.NFP_SITU) AS NFP_SITU
    FROM NOTA n
    JOIN NOTAPROD np ON np.NF_NUMERO = n.NF_NUMERO AND np.CODEMP = n.CODEMP
    WHERE n.CODEMP = 1
    GROUP BY n.NF_PEDIDO, np.NFP_CODPROD, n.CODEMP
) np ON np.NF_PEDIDO = ped.CODIGO
    AND np.NFP_CODPROD = ip.CODPROD
    AND np.CODEMP = ip.CODEMP
```

O `MIN()` + `GROUP BY` evita duplicatas quando há mais de uma NF por pedido (ex: correções).

## Observações

- `NOTA` armazena apenas NFs **emitidas pela empresa** (saídas). Para entradas (NF do fornecedor), usar `PRODUTOS.SITU` como fallback — não existe CST por item nas entradas.
- `NOTA.NF_STATUS = 4` = NF cancelada (Cancelamento Autorizado SEFAZ)
- Para entradas sem NF emitida, usar `COALESCE(np.NFP_SITU, 'SEM NF')` ou `p.SITU`
