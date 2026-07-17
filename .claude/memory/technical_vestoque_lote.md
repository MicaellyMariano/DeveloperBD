---
name: technical_vestoque_lote
description: "V_ESTOQUE_LOTE: ENTRADA/SAIDA são quantidades, DATA_FAB é fabricação; datas de movimento ficam em ESTOQUE_LOTE"
metadata: 
  node_type: memory
  type: technical
  originSessionId: a100ae82-53d4-4114-8172-c23e8386b847
---

## V_ESTOQUE_LOTE — estrutura e armadilhas

**Colunas da view:**
`CODPROD, LOTE, CODEMP, SALDO, ENTRADA, SAIDA, DATA_FAB, DATA_VALIDADE`

**Armadilhas:**
- `ENTRADA` e `SAIDA` são **quantidades** (total que entrou/saiu), NÃO datas
- `DATA_FAB` = data de fabricação do lote (útil para queijaria e produtos com lote)
- `DATA_VALIDADE` = 1899-12-30 quando não tem validade cadastrada

**Para obter datas reais de movimento, usar ESTOQUE_LOTE:**
- `TIPO = 'E'` = entrada (Status=Bloqueado)
- `TIPO = 'S'` = saída (Status=Baixa)
- `DATA_ENTRADA` = data do movimento (tanto para E quanto para S)

**Query padrão — relatório de lotes com datas:**
```sql
SELECT
    p.CODIGO, p.DESCRICAO, cc.NOME AS CATEGORIA,
    v.LOTE, v.SALDO, v.DATA_VALIDADE,
    v.DATA_FAB      AS DATA_FABRICACAO,
    e_sai.DATA_SAI  AS DATA_ULTIMA_SAIDA
FROM V_ESTOQUE_LOTE v
LEFT JOIN PRODUTOS p ON p.CODIGO = v.CODPROD AND p.CODEMP = v.CODEMP
LEFT JOIN CLASSCOMERCIAL cc ON cc.CODIGO = CAST(p.CLASSIFICACAO AS INTEGER) AND cc.CODEMP = p.CODEMP
LEFT JOIN (
    SELECT CODPROD, LOTE, CODEMP, MAX(DATA_ENTRADA) AS DATA_SAI
    FROM ESTOQUE_LOTE WHERE TIPO = 'S' AND CODEMP = 1
    GROUP BY CODPROD, LOTE, CODEMP
) e_sai ON e_sai.CODPROD = v.CODPROD AND e_sai.LOTE = v.LOTE AND e_sai.CODEMP = v.CODEMP
WHERE v.CODEMP = 1 AND v.SALDO > 0 AND p.DISPONIVEL = 'Sim'
```

**Filtro queijos:** `AND p.TIPO = 'QUEIJOS'` — ver [[technical_classcomercial_arvore]]

**Why:** Construído para CEM_MOGIANA (17/07/2026). Outra IA sugeriu usar e.entrada/e.saida como datas — erro: são quantidades.

**How to apply:** Ao montar relatório de estoque por lote, sempre verificar se o campo pedido é data ou quantidade. Datas de movimento ficam em ESTOQUE_LOTE, não na view.
