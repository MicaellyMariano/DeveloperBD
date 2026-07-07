# Comportamento: Editar Pedido Entrada → Saída

## O que acontece

Quando um pedido é editado de `TIPO='E'` para `TIPO='S'`, o sistema faz **dois** movimentos no ESTOQUE:

1. **Reverte** a entrada anterior (remove o +X do saldo)
2. **Aplica** a saída (-X)

## Exemplo

| Etapa | Operação | Saldo |
|-------|---------|-------|
| Antes do pedido | baseline | 55 |
| Pedido como entrada (+2) | +2 | 57 |
| Editado para saída (-2) | -2 (reverte) -2 (saída) | 53 |

Do ponto de vista do usuário parece que saíram 4 (57→53), mas é correto — o saldo final é 55-2=53.

## Não é bug

É o comportamento esperado. O sistema garante consistência revertendo o efeito anterior antes de aplicar o novo.

## QTDATUAL zerado (campo desatualizado)

Em alguns bancos, `PRODUTOS.QTDATUAL` fica zerado se o trigger de atualização estiver ausente.  
**Mas a tela do sistema lê `ESTOQUE.SALDO`** — o campo `QTDATUAL` é ignorado na exibição.

Verificar: se `QTDATUAL=0` mas a tela mostra saldo correto → o sistema usa ESTOQUE, sem impacto para o usuário.

Query para detectar discrepância:
```sql
SELECT p.codigo, p.descricao, p.qtdatual,
       (SELECT FIRST 1 e.saldo FROM estoque e WHERE e.codprod = p.codigo ORDER BY e.codigo DESC) AS saldo_estoque
FROM produtos p
WHERE p.qtdatual = 0
  AND EXISTS (SELECT 1 FROM estoque e WHERE e.codprod = p.codigo AND e.saldo > 0
              AND e.codigo = (SELECT MAX(e2.codigo) FROM estoque e2 WHERE e2.codprod = p.codigo))
ORDER BY p.descricao
```

## Caso real

- Banco: `CEM_beto_070726.FDB`
- Produto: 126 (GOIABADA FORNEAVEL BARRA 7 KG)
- Pedido 260362 editado de entrada para saída — saldo foi de 57 para 53 (correto)
