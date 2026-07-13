---
name: technical-estoque-entrada-saida
description: "Comportamento do Sistema RAM ao editar pedido de entrada para saída — reverte e reaaplica, saldo parece dobrar mas está correto"
metadata: 
  node_type: memory
  type: project
  originSessionId: a100ae82-53d4-4114-8172-c23e8386b847
---

## Edição de pedido: entrada → saída no Sistema RAM

Quando um pedido é editado de TIPO='E' para TIPO='S', o sistema faz **dois** movimentos no ESTOQUE:
1. **Reverte** a entrada anterior (remove o +X do saldo)
2. **Aplica** a saída (-X)

**Exemplo:** saldo base=55, pedido entra com 2 → saldo=57. Edita para saída: 57-2 (reverte entrada) -2 (aplica saída) = 53.

Do ponto de vista do usuário parece que saíram 4 (57→53), mas é correto — o saldo líquido final é 53 = 55 - 2 (saída).

**Não é bug.** É o comportamento esperado.

**Why:** Investigado no banco CEM_beto_070726.FDB, produto 126 (GOIABADA 7KG), pedido 260362.

**How to apply:** Quando cliente reportar "estoque descontou o dobro", verificar se editou pedido de entrada para saída. Explicar que é reversão + aplicação.

## QTDATUAL vs ESTOQUE.SALDO

Em alguns bancos, `PRODUTOS.QTDATUAL` fica zerado (trigger ausente), mas a **tela do sistema lê de `ESTOQUE.SALDO`** — o campo `QTDATUAL` é ignorado para exibição. Não é bug visível ao usuário.

Verificar: se `QTDATUAL=0` mas a tela mostra saldo correto → o sistema usa ESTOQUE, `QTDATUAL` desatualizado é inofensivo nesse banco.
