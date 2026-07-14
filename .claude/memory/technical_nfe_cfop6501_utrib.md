---
name: technical-nfe-cfop6501-utrib
description: Regras de unidade tributável (uTrib) para CFOP 6501 — operação com comércio exterior
metadata: 
  node_type: memory
  type: project
  originSessionId: a100ae82-53d4-4114-8172-c23e8386b847
---

## CFOP 6501 — Remessa com fim específico de exportação

CFOP 6501 = "Remessa de produção do estabelecimento, com fim específico de exportação". Apesar de ser série 6 (interestadual), o SEFAZ aplica validação de **comércio exterior** para uTrib, cruzando NCM com tabela própria.

## Regras de uTrib confirmadas

| NCM | Descrição | uTrib aceito | Cálculo |
|-----|-----------|-------------|---------|
| 61xx, 62xx | Vestuário malha/tecido | UN | qTrib = qCom × peças/CJ ou KIT |
| 63026000 | Toalha terry woven | ? | Nem UN nem PC funcionaram |

### CJ (conjunto) = 2 peças
- uCom=CJ, uTrib=UN, qTrib=qCom×2, vUnTrib=vProd/qTrib

### KIT 4 PEÇAS (ex: babador)
- uCom=KIT, uTrib=UN, qTrib=qCom×4, vUnTrib=vProd/qTrib

### NCM 63026000 (toalhas)
- Produto "TOALHA DE BANHO EM MALHA" — nem UN nem PC aceitos pelo SEFAZ
- Suspeita: NCM errado. 63026000 é para terry TECIDO (froco atoalhado). Se a toalha é em malha (knit), o NCM correto pode ser 6302.91.00 (outros de algodão) ou 6307.90.90
- **Pendente**: cliente DOME FLAIBAM vai verificar NCM correto com fornecedor

## Casos confirmados DOME FLAIBAM → RIOS COMERCIO (PR), NCM 61112000

| NF | Itens | Resultado |
|----|-------|-----------|
| 8256 | 25 itens — CJ×2 e KIT×4, 1 item toalha (NCM mudado p/ 61112000) | APROVADA |
| 8258 | 24 itens — todos KIT 4 peças | APROVADA |
| 8259 | 23 itens — KIT 4 peças + 4 itens 2817 (macacão individual, uCom=UN já correto) | APROVADA |

**Atenção NF 8259:** produto 2896 KIT regata TAM 3 (cProd 25181) estava cadastrado com uCom=UN no sistema, mas era KIT 4 peças igual às outras TAMs. Corrigido para KIT antes de gerar XML.

**Como diferenciar item individual de KIT:** se a descrição contém "KIT X PEÇAS/PCS" mas uCom=UN, verificar com o cliente se é cadastro errado. Se os outros tamanhos do mesmo produto usam KIT, é cadastro errado — corrigir no sistema.

## cBenef SP070050
- Aplica para NCM 61xx com CFOP 6501 (vestuário bebê/infantil de SP para outros estados)
- NÃO aplica para NCM 63xx (toalhas)

## Validação vProd
SEFAZ exige: `vProd = qTrib × vUnTrib` (arredondado). Se qTrib ou vUnTrib estiver zerado, dá erro "Valor do Produto difere".

**Why:** Sistema RAM usa uCom como uTrib por padrão, mas SEFAZ rejeita CJ/KIT em operações interestadual/exportação. Fix manual necessário.
**How to apply:** ao depurar rejeições de NF-e com CFOP 6501, verificar uTrib de cada item contra NCM.
