---
name: technical-nfe-troco-arredondamento
description: "Erro NF-e \"Ausência de troco\" causado por diferença de 0,01 entre vPag e vNF por arredondamento"
metadata: 
  node_type: memory
  type: project
  originSessionId: a100ae82-53d4-4114-8172-c23e8386b847
---

## Erro
"Ausência de troco quando o valor dos pagamentos informados for maior que o total da nota"

## Causa
O sistema gera a fatura/duplicata com valor arredondado (ex: 969,66) mas a soma real dos itens resulta em valor diferente (ex: 969,65). O SEFAZ detecta `vPag > vNF` e exige `<vTroco>` declarado no bloco `<pag>`.

## Caso documentado — RJ COMERCIO (NF 21761, v18.0.0.32)
- `vNF = 969,65` (soma dos itens)
- `vPag = 969,66` (fatura arredondada)
- Diferença: 0,01

## Fixes possíveis

**Opção 1 (recomendada):** Corrigir `vPag`, `vOrig`, `vLiq` e `vDup` para o valor exato da nota (969,65).

**Opção 2:** Adicionar `<vTroco>0.01</vTroco>` no bloco `<pag>`:
```xml
<pag>
  <detPag>
    <tPag>15</tPag>
    <vPag>969.66</vPag>
  </detPag>
  <vTroco>0.01</vTroco>
</pag>
```

**Fix confirmado em produção:** ajustar o valor no pedido dentro do sistema (Opção 1) — nota aprovada pelo SEFAZ.

**Why:** Arredondamento na geração da fatura cria diferença de centavo vs soma real dos itens.
**How to apply:** Ao receber erro "ausência de troco", comparar `vPag` com `vNF` — se diferir por centavos, ajustar `vPag` ou adicionar `vTroco`.
