# Bug: Caixa — Pedido VÁRIOS com DINHEIRO

## Descrição

Quando um pedido tem `TIPOVENDA='VARIOS'` com DINHEIRO como uma das formas (ex: DINHEIRO=5,00 + DÉBITO=0,99), a tela do caixa exibe:

- **DINHEIRO = TOTALPEDIDO (5,99)** ← errado, deveria ser 5,00
- **DÉBITO = 0,99** ← correto

O fechamento do caixa (`CONTROLECAIXA_ITENS`) também grava errado.

## Causa

O sistema usa `TOTALPEDIDO` para a coluna DINHEIRO de pedidos VÁRIOS que incluem DINHEIRO, em vez de ler a parcela DINHEIRO do split real (MOVIMENT ou TAB_PAGAMENTOS_PEDIDO).

Para pagamento único (DINHEIRO apenas), o bug não aparece porque TOTALPEDIDO = valor DINHEIRO.

## Impacto financeiro

- `CONTROLECAIXA_ITENS.DINHEIRO`: valor 0,99 a mais
- `CONTROLECAIXA_ITENS.DEBITO`: valor 0,99 a menos

## Onde os dados corretos estão

```sql
-- Split correto do pedido
SELECT tipovenda, valor FROM tab_pagamentos_pedido WHERE pedido = <codigo>;

-- Movimentos corretos
SELECT tipovenda, valor, fluxo FROM moviment WHERE codigo = <financeiro>;
```

## Fix nos totais do fechamento

```sql
UPDATE controlecaixa_itens SET valor = <correto>, valor_sistema = <correto>
WHERE codigo = <id_caixa> AND descricao = 'DINHEIRO';

UPDATE controlecaixa_itens SET valor = <correto>, valor_sistema = <correto>
WHERE codigo = <id_caixa> AND descricao = 'DEBITO';
```

## Caso real

- Banco: `CEM_menezes030726.FDB`
- Pedido: 340656 | Caixa: 1752 (GABRIELA) | Data: 13/06/2026
- Split real: DINHEIRO=5,00 + DÉBITO=0,99 | Tela mostrava: DINHEIRO=5,99 + DÉBITO=0,99
