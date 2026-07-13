---
name: technical-financeiro-duplic-realizar
description: "Duplicação de parcelas no financeiro causada por cliques múltiplos em \"Realizar\""
metadata: 
  node_type: memory
  type: project
  originSessionId: a100ae82-53d4-4114-8172-c23e8386b847
---

## Problema
Parcelas duplicadas aparecem no financeiro com `PARCELA_ORIGEM` apontando para o mesmo registro pai.

## Causa
Operador clicou no botão "Realizar" múltiplas vezes no mesmo financeiro, gerando parcelas extras.

## Caso documentado — Santa Tereza (CEM_SantaTereza_070726.FDB)
- **Financeiro:** 27 (pedido 29, versão Sistema RAM 34)
- **Sintoma:** 3 parcelas de -69,80 (parcelas 2, 3, 4) com PARCELA_ORIGEM=1
- **Causa:** operador clicou "Realizar" 3 vezes
- **Impacto:** parcelas 3 e 4 já estavam canceladas — sem impacto financeiro real

## Como identificar
```sql
SELECT * FROM financeiro_parcelas
WHERE parcela_origem = :id_financeiro
ORDER BY numero_parcela
```
Se aparecerem parcelas repetidas com mesmo PARCELA_ORIGEM, verificar se foram canceladas.

## Fix
Se as parcelas extras estiverem canceladas: sem ação necessária.
Se estiverem abertas/ativas: cancelar manualmente as duplicatas, manter apenas a parcela correta.

**Why:** sistema não trava o botão "Realizar" durante o processamento, permitindo cliques duplos/triplos.
**How to apply:** ao receber reclamação de "duplicando financeiro", perguntar ao operador se clicou várias vezes e checar PARCELA_ORIGEM.
