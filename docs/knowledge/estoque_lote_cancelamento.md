# ESTOQUE vs ESTOQUE_LOTE no Cancelamento

## Comportamento no cancelamento de pedido

| Tabela | O que acontece |
|--------|---------------|
| `ESTOQUE` | Deleta a linha do movimento |
| `ESTOQUE_LOTE` | Só limpa se "controlar lote" estiver ativo no status do produto |

## Detalhe

Se o produto não tiver controle de lote ativo, o cancelamento não toca `ESTOQUE_LOTE`. Isso pode deixar registros órfãos se lote foi ativado e depois desativado.
