---
name: technical_nfe_predbc_sp020520
description: "NF-e CST-20 SP020520 — pRedBC correto é 33,33%, não 12%; \"carga tributária de 12%\" é taxa efetiva, não redução da BC"
metadata: 
  node_type: memory
  type: project
  originSessionId: a100ae82-53d4-4114-8172-c23e8386b847
---

## NF-e CST-20 — Benefício SP020520: pRedBC = 33,33%

**O erro recorrente:** escritório/cliente instrui "use 12% de redução", mas o campo `pRedBC` no XML deve ser **33,33%**, não 12%.

### Por quê

A SEFAZ descreve SP020520 como **"carga tributária de 12%"** — isso é a alíquota efetiva final sobre o valor do produto, não o percentual de redução da base.

Com alíquota SP de 18%:
- `pRedBC = 12%` → ICMS efetivo = 18% × (1 − 12%) = **15,84%** ❌
- `pRedBC = 33,33%` → ICMS efetivo = 18% × (1 − 33,33%) = **12,00%** ✓

**Fórmula:** `pRedBC = (1 − carga_tributária / pICMS) × 100 = (1 − 12/18) × 100 = 33,33%`

### Verificação no DANFE

O campo `BC ICMS` deve ser ≈ 66,67% do `V.TOTAL` do produto:
- Ex: vProd = 4.500,00 → BC = 3.000,16 → ICMS = 540,01 (≈ 12% de 4.500)

### Onde corrigir no Sistema RAM

Cadastro de Produtos → aba Fiscal/Tributação → campo **"Redução BC"** → alterar de `12` para `33,33`.

As informações complementares da NF devem constar: *"Redução de 33,33% - ARTIGO 52, INCISO II, DO ANEXO II DO RICMS/SP"*

### Caso real

- Cliente: DOME FLAIBAM IND COM IMP E EXP DE CONF LTDA (CNPJ 58.325.291/0001-78)
- NCM 6111.20.00 (malha bebê), CFOP 5101, CST-20, cBenef SP020520
- NFs 8457 e 8458 emitidas com pRedBC=12% → canceladas
- Reemitidas como NFs **8462** (POLIANE, R$ 402,26 ICMS) e **8463** (LOJAO ITAPEVI, R$ 540,01 ICMS) com pRedBC=33,33% ✓
- Data: 14/07/2026

**Why:** Confusão semântica — "12%" é o resultado que a lei quer, não o parâmetro do XML.

**How to apply:** Sempre que cliente/escritório disser "ICMS de 12% com CST-20", verificar se pRedBC no sistema está em 33,33%. Se estiver em 12%, corrigir e reemitir se a NF ainda puder ser cancelada (dentro de 24h).
