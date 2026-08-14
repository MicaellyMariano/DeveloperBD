# NF-e — Total PIS/COFINS zerado com cBenef

## Descrição

NF-e rejeitada com: **"Total do PIS difere do somatório dos itens sujeitos ao ICMS"**

Ocorre quando a NF mistura itens com `<cBenef>` (benefício fiscal SP, ex: SP020110 — redução ICMS CST 20) e itens sem cBenef (ex: CFOP 5405 CST 60).

## Sintoma no XML

```xml
<ICMSTot>
  <vPIS>78.00</vPIS>       <!-- só o item SEM cBenef -->
  <vCOFINS>360.00</vCOFINS> <!-- idem -->
</ICMSTot>
```

Enquanto a soma real dos itens é:
- Item 1 (sem cBenef, CST 60): PIS=78 + COFINS=360
- Item 2 (com cBenef, CST 20): PIS=234 + COFINS=1080
- Item 3 (com cBenef, CST 20): PIS=52 + COFINS=240
- **Soma correta: PIS=364, COFINS=1680**

## Causa

Na regra fiscal do produto (Controle Fiscal → aba Impostos), há uma opção **"sem PIS e sem COFINS"** marcada. Com essa flag ativa, o Sistema RAM não inclui PIS/COFINS desses itens no total da NF-e.

## Como identificar na tela

Controle Fiscal → aba **Impostos** → colunas Aliq PIS e Valor PIS zeradas nos itens afetados, mesmo tendo Cód. PIS preenchido.

## Fix

1. Acessar o cadastro fiscal do produto → regra fiscal
2. Desmarcar a opção **"sem PIS e sem COFINS"**
3. Regravar a nota e retransmitir

## Caso real

- Empresa: LIQUIDAKI OUTLET + (CNPJ 08533867000114)
- NF-e: 413, série 2 — 30/07/2026
- Produtos afetados: 526 (TV 32 AOC HD ROKU) e 735 (TV 32 AOC ROKU HD) com cBenef SP020110
- Produto correto: 11355 (PELICULA) sem cBenef, PIS/COFINS ok
