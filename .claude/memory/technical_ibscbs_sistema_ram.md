---
name: technical-ibscbs-sistema-ram
description: Bugs do Sistema RAM na geração de XML IBS/CBS para Reforma Tributária (NF-e 4.00)
metadata: 
  node_type: memory
  type: project
  originSessionId: a100ae82-53d4-4114-8172-c23e8386b847
---

## Contexto
Sistema RAM v18.0.1.9. A partir de 2026, NF-e exige campos IBS/CBS (Reforma Tributária). O sistema tem bugs na geração desses campos.

## Bug 1 — gRed gerado indevidamente para CST 550

**Erro SEFAZ:** "CST do IBS/CBS informado não permite informação de redução de alíquota Estadual [nItem: X]"

**Causa:** Com CST=550 (não tributada), o sistema gerava bloco `<gRed>` dentro de `<gIBSUF>` e `<gCBS>` quando havia redução cadastrada em "Cadastro de Reduções" com 100%.

**Fix (configuração):** Remover a redução do "Cadastro de Reduções" para o produto/NCM em questão.

## Bug 2 — gTribRegular não gerado (BUG DE CÓDIGO)

**Erro SEFAZ:** "Classificação Tributária do IBS e da CBS informada obriga informação da tributação regular [nItem: X]"

**Causa:** cClassTrib=550001 com CST=550 exige bloco `<gTribRegular>` no XML. O Sistema RAM **não gera esse bloco** — bug de código, não de configuração.

**Estrutura correta esperada pelo SEFAZ:**
```xml
<gIBSCBS>
  <vBC>1059.85</vBC>
  <gTribRegular>
    <pAliqIBSUFReg>0.1000</pAliqIBSUFReg>
    <pAliqIBSMunReg>0.0000</pAliqIBSMunReg>
    <pAliqCBSReg>0.9000</pAliqCBSReg>
  </gTribRegular>
  <gIBSUF><pIBSUF>0.0000</pIBSUF><vIBSUF>0.00</vIBSUF></gIBSUF>
  <gCBS><pCBS>0.0000</pCBS><vCBS>0.00</vCBS></gCBS>
</gIBSCBS>
```

Com CST=550, pIBSUF e pCBS devem ser 0.0000 / vIBSUF e vCBS devem ser 0.00. As alíquotas vão dentro de gTribRegular (alíquotas que seriam cobradas sem o benefício).

**Status:** RESOLVIDO via configuração. Existe um cadastro no sistema onde é possível configurar o gTribRegular — localização exata a confirmar (NF 8252 transmitida com sucesso após configuração).

## Observação adicional
Mesmo após alterar "Cadastro de Reduções", os XMLs gerados continuavam com pIBSUF/pCBS com valor (ex: 0.1000 e 0.9000), indicando que o sistema ignora a configuração ou recalcula independentemente.

**Why:** cliente DOME FLAIBAM NF 8252 com roupões, CFOP 6501, cBenef SP070050.
**How to apply:** ao receber erros de IBS/CBS, verificar se é Bug 1 (gRed) ou Bug 2 (gTribRegular). Bug 1 tem fix de config; Bug 2 não tem fix no v18.0.1.9.

## Bug 3 — IBSCBSTot na posição errada dentro de `<total>` (ERRO 1871)

**Erro SEFAZ:** "Element 'IBSCBSTot': This element is not expected. Expected is one of ( ISSQNtot, retTrib )"

**Causa:** O sistema gerava `<IBSCBSTot>` imediatamente após `<ICMSTot>`, mas o schema da SEFAZ exige que venha depois de `<ISSQNtot>` e `<retTrib>`.

**XML gerado (errado):**
```xml
<total>
  <ICMSTot>...</ICMSTot>
  <IBSCBSTot>...</IBSCBSTot>  ← posição errada
  <vNFTot>...</vNFTot>
</total>
```

**XML correto:**
```xml
<total>
  <ICMSTot>...</ICMSTot>
  <ISSQNtot/>   (opcional)
  <retTrib/>    (opcional)
  <IBSCBSTot>...</IBSCBSTot>  ← depois de retTrib
  <vNFTot>...</vNFTot>
</total>
```

**Fix:** Atualizar arquivos dependentes do Sistema RAM (DLLs/componentes). Não requer atualização do sistema principal nem do servidor. Confirmado resolvido em 17/07/2026 (cliente J.E. MAURANO AMPARO, NF 158478, v18.0.1.12).
