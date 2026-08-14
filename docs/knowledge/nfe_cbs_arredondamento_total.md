# NF-e — Total CBS difere da soma dos itens (arredondamento)

## Descrição

NF-e rejeitada com: **"Total de CBS difere da soma dos itens"**

Ocorre quando o Sistema RAM calcula `<vCBS>` no `<IBSCBSTot>` usando `base_total × alíquota` (arredondado uma vez), enquanto a SEFAZ exige que o total seja a **soma exata dos valores individuais por item** (cada um já arredondado).

## Exemplo

- 24 itens × vCBS=1.91 = 45.84
- 24 itens × vCBS=1.19 = 28.56
- **Soma dos itens = 74.40**
- Sistema gravou no total: `<vCBS>74.39</vCBS>` ← 0,01 a menos

## Campos a corrigir no XML

```xml
<!-- Em <IBSCBSTot><gCBS> -->
<vCBS>74.39</vCBS>  →  <vCBS>74.40</vCBS>

<!-- Em <total><ICMSTot> ou equivalente -->
<vNFTot>9879.35</vNFTot>  →  <vNFTot>9879.36</vNFTot>
```

`vNFTot = vNF + vIBS + vCBS`

## Fix no sistema

Corrigir no Sistema RAM: **aba Impostos → controle fiscal** → ajustar o valor de CBS total para igualar a soma dos itens.

O correto é: `vCBS_total = SUM(vCBS_por_item)`, nunca recalcular do total da base.

## Caso real

- Empresa: DOME FLAIBAM IND COM IMP E EXP DE CONF LTDA (SP)
- NF-e: 8502
- Todos itens NCM 61112000, CST IBS/CBS = 000, pCBS=0.9000%
- Diferença: R$ 0,01
