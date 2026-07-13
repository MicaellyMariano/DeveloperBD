---
name: technical-caixa-varios-bug
description: Bug no caixa do Sistema RAM para pedidos VÁRIOS com DINHEIRO — tela e fechamento usam TOTALPEDIDO em vez do split real
metadata: 
  node_type: memory
  type: project
  originSessionId: a100ae82-53d4-4114-8172-c23e8386b847
---

## Bug: Pedido VÁRIOS com DINHEIRO na tela do caixa

Quando um pedido tem `TIPOVENDA='VARIOS'` com DINHEIRO como uma das formas (ex: DINHEIRO=5,00 + DÉBITO=0,99), a tela do caixa exibe:
- **DINHEIRO = TOTALPEDIDO (5,99)** — errado, deveria ser 5,00
- **DÉBITO = 0,99** — correto

O fechamento do caixa (`CONTROLECAIXA_ITENS`) também grava errado: soma TOTALPEDIDO no DINHEIRO em vez do split real.

**Por que:** O sistema usa TOTALPEDIDO para a coluna DINHEIRO de pedidos VÁRIOS que incluem DINHEIRO, em vez de ler a parcela DINHEIRO do split (MOVIMENT ou TAB_PAGAMENTOS_PEDIDO).

**Impacto:** CONTROLECAIXA_ITENS.DINHEIRO fica 0,99 a mais; CONTROLECAIXA_ITENS.DEBITO fica 0,99 a menos.

**Fix no banco (após confirmar valores):**
```sql
UPDATE controlecaixa_itens SET valor = <correto>, valor_sistema = <correto>
WHERE codigo = <id_caixa> AND descricao = 'DINHEIRO';

UPDATE controlecaixa_itens SET valor = <correto>, valor_sistema = <correto>
WHERE codigo = <id_caixa> AND descricao = 'DEBITO';
```

**Dados corretos estão em:** MOVIMENT (tipovenda, valor por parcela) e TAB_PAGAMENTOS_PEDIDO.

**Why:** Encontrado no banco CEM_menezes030726.FDB, pedido 340656, caixa 1752 (GABRIELA), 13/06/2026.

**How to apply:** Ao investigar diferença de caixa em pedido VÁRIOS com DINHEIRO, verificar primeiro se CONTROLECAIXA_ITENS.DINHEIRO = TROCO + soma_vendas_dinheiro + 0,99_extra.
