---
name: technical-estoque-lote
description: Sistema RAM — comportamento de ESTOQUE vs ESTOQUE_LOTE ao cancelar pedido, controle por status
metadata:
  node_id: memory
  type: project
  originSessionId: a100ae82-53d4-4114-8172-c23e8386b847
---

## Sistema RAM — ESTOQUE vs ESTOQUE_LOTE no Cancelamento

**Tabelas:**
- `ESTOQUE` — Movimentações de estoque principal. Campo `CODORIGEM` = código do pedido de origem
- `ESTOQUE_LOTE` — Rastreio por lote. Campos principais: `CODPROD`, `LOTE`, `QTD_ENTRADA`, `QTD_SAIDA`, `CODORIGEM`, `TIPO` (E/S), `STATUS`

**Comportamento ao cancelar pedido:**
- `ESTOQUE` → linha da saída é **deletada** (linha removida do banco, não estornada)
- `ESTOQUE_LOTE` → só é deletada se o **status do pedido** tiver a opção **"controlar lote" ATIVADA**
  - Se "controlar lote" estiver DESATIVADO → ESTOQUE_LOTE **não é limpo** → linha fica órfã

**Isso NÃO é bug** — é comportamento por design. O status do pedido controla o comportamento.

**Caso NALIN (2026-06-22) — produto 1746, pedido 118537, lote 7561:**
- Status do pedido estava com "controlar lote" DESATIVADO
- Ao cancelar: ESTOQUE deletou a linha de saída (correto)
- ESTOQUE_LOTE ficou com linha de saída órfã: QTD_SAIDA=2831, STATUS=Baixa, CODORIGEM=118537, TIPO='S'
- Resultado: saldo do lote 7561 aparecia zerado/negativo mesmo sem movimento real

**Fix manual (quando houver órfão):**
```sql
DELETE FROM estoque_lote
WHERE codprod = 1746
  AND lote = '7561'
  AND codorigem = 118537
  AND tipo = 'S';
COMMIT;
```
Após o DELETE, editar e gravar o pedido no sistema para recalcular o saldo.

**Causa raiz no caso do cliente:** status configurado sem controle de lote. Solução definitiva: ativar "controlar lote" no status do pedido usado.

**Verificação útil:**
```sql
-- Ver se há linhas de ESTOQUE para o pedido (se não houver, foi deletado no cancelamento)
SELECT * FROM estoque WHERE codorigem = 118537 AND codprod = 1746;

-- Ver linhas de ESTOQUE_LOTE que podem estar órfãs
SELECT * FROM estoque_lote WHERE codprod = 1746;
```

**Why:** Cliente relatou que saldo não voltou ao cancelar pedido. Investigação revelou que ESTOQUE estava correto (linha deletada), mas ESTOQUE_LOTE tinha linha órfã por falta de controle de lote no status.
**How to apply:** Sempre que cliente reclamar de saldo de estoque errado após cancelamento, verificar tanto ESTOQUE quanto ESTOQUE_LOTE, e verificar configuração de "controlar lote" no status do pedido.
