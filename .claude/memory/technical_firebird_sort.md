---
name: technical-firebird-sort
description: Firebird 2.5 — erro "sort record size of X bytes is too big" causado por SELECT com colunas demais
metadata:
  node_id: memory
  type: project
  originSessionId: a100ae82-53d4-4114-8172-c23e8386b847
---

## Firebird 2.5 — Sort Record Size Too Big

**Erro:** `sort record size of 67828 bytes is too big`

**Limite:** Firebird 2.5 tem limite de **64KB (65536 bytes)** por registro para operações de ordenação (ORDER BY, DISTINCT, GROUP BY).

**Causa comum no Sistema RAM:** Queries que usam `refs.*` ou `tabela.*` com tabelas largas.
- Tabela `REFS` tem ~86 colunas → `SELECT refs.*` estourou o limite em alguns clientes
- O número de colunas varia entre versões (esquemas divergem entre clientes)
- Em clientes com versão de banco mais antiga (~86 cols), o erro ocorre; em outros não

**Fix:** Substituir `refs.*` por lista explícita das colunas necessárias:
```sql
SELECT DISTINCT refs.codigo, tipoplan.nome AS classfin,
    (SELECT FIRST 1 m.tipo_baixa FROM moviment m WHERE ...) AS tipo_baixa,
    CASE WHEN refs.fluxo = 1 THEN (refs.valor * 1) ELSE (refs.valor * (-1)) END AS VALOR_CASE,
    TRIM(cadastro.nomfant) AS nome,
    (SELECT FIRST 1 m.data_liq FROM moviment m WHERE ...) AS data_liq,
    (SELECT FIRST 1 m.data_pato FROM moviment m WHERE ...) AS data_pato,
    refs.parcela, refs.codemp, refs.fluxo, refs.valor, refs.saldo, refs.data_venc,
    refs.cod_class, refs.cod_cli, refs.caixa, refs.cancelado, refs.previsao,
    refs.agrupado, refs.parcela_origem, 0 AS sequencia
FROM refs ...
```

**Onde ocorreu:** Relatório `FrmRelatMovimentosAgrupados` no Sistema RAM.

**Why:** O erro é de schema — versões mais novas do banco têm menos colunas em REFS e não estouram o limite; versões antigas com 86+ colunas estouram. Não é bug do relatório em si, mas incompatibilidade de versão de banco.
**How to apply:** Se aparecer esse erro em qualquer relatório do Sistema RAM, procurar SELECT com `tabela.*` e substituir por colunas explícitas.
