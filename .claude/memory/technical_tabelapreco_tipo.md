---
name: technical-tabelapreco-tipo
description: "Função \"colocar todos na tabela de preço\" filtra por TIPO='PRODUTO ACABADO' AND DISPONIVEL='Sim' — se TIPO vazio, usa só DISPONIVEL"
metadata: 
  node_type: memory
  type: project
  originSessionId: a100ae82-53d4-4114-8172-c23e8386b847
---

## Tabela de preço — filtro TIPO + DISPONIVEL

A função "colocar todos os produtos na tabela de preço" no Sistema RAM filtra:
- `TIPO = 'PRODUTO ACABADO'` AND `DISPONIVEL = 'Sim'` → se TIPO preenchido

Se TIPO estiver vazio em todos os produtos, filtra só por:
- `DISPONIVEL = 'Sim'` → inclui todos os disponíveis

**Problema encontrado:** banco CEM_tiagopetipeta260626.FDB tinha 252 produtos com TIPO='PRODUTO ACABADO' + DISPONIVEL='Sim', mas 1.522 com DISPONIVEL='Sim'. A tabela TIPO_PRODUTO estava vazia (sem opções cadastradas), então novos produtos ficavam com TIPO=NULL.

**Fix aplicado em produção:**
```sql
UPDATE produtos SET tipo = NULL WHERE tipo IS NOT NULL AND tipo <> '';
```
Após isso, a função adicionou todos os 1.522 produtos disponíveis.

**Why:** TIPO_PRODUTO vazia = dropdown sem opções = novos produtos sem TIPO. Limpar TIPO resolve sem perda de dados (campo não é utilizado).

**How to apply:** Ao reclamar que tabela de preço não pega todos os produtos, verificar: `SELECT tipo, COUNT(*) FROM produtos GROUP BY tipo` — se tiver 'PRODUTO ACABADO' misturado com NULL, é esse o filtro.

## Tabelas relacionadas
- `TABELADEPRECO` — cabeçalho (TIPOPRECO=2, MARKUP=15 para ATACADO)
- `ITENSTABELAPRECO` — itens (CODIGO=tabela, CODEMP, CODPROD, PRECO, PRECOBASE)
- `TIPO_PRODUTO` — define opções do dropdown TIPO em PRODUTOS (sem FK)
