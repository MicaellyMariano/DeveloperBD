---
name: technical-cnab400-itau
description: Posições do CNAB 400 Itaú — campo prazo de protesto (pos 392-393), confirmado pelo banco
metadata:
  node_type: memory
  type: project
  originSessionId: a100ae82-53d4-4114-8172-c23e8386b847
---

## CNAB 400 Itaú — Campo Prazo de Protesto

**Layout de registro tipo 1 (remessa):**

| Pos (1-indexed) | Campo | Tamanho | Observação |
|---|---|---|---|
| 157-158 | Instrução 1 | 2 | `81` = fixo (estrutural, não é o prazo) |
| 146-151 | Vencimento | 6 | DDMMAA |
| 386-391 | Data limite pagamento | 6 | DDMMAA |
| 392-393 | **Prazo de protesto** | 2 | NN dias corridos após vencimento |

**Python (0-indexed):**
```python
prazo        = rec[391:393]   # pos 392-393
data_limite  = rec[385:391]   # pos 386-391
```

**Bug identificado no cliente NALIN (2026):**
- Remessa 26161686 (29/05/2026): prazo = `10` → banco protestava só após 10 dias ✓
- Remessa 26161687 (01/06/2026+): prazo = `00` → banco protestava após só 2 dias ✗
- Campo `00` = banco usa o prazo mínimo (2 dias corridos após vencimento), confirmado por email do Itaú
- Causa provável: atualização do sistema 18.0.0.25 em 29/05/2026 entre 14:13-14:15 alterou o parâmetro "dias para protesto"
- **Fix:** desenvolvedor deve restaurar o parâmetro "dias para protesto" para `10` no ERP

**Scripts auxiliares criados:**
- `C:\Temp\compara_prazo_protesto.py` — compara o campo entre 3 remessas
- `C:\Temp\mostra_campo_visual.py` — exibe o campo com marcação visual no bloco 381-400

**Why:** Investigação para cliente NALIN — boletos sendo protestados incorretamente após atualização do sistema.
**How to apply:** Ao analisar remessas Itaú com problema de protesto, verificar pos 392-393 nos registros tipo 1.
