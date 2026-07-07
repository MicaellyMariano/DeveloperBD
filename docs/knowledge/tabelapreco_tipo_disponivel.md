# Tabela de Preço — Filtro TIPO + DISPONIVEL

## Como funciona a função "colocar todos na tabela de preço"

O Sistema RAM filtra produtos para adicionar na tabela de preço usando:

- Se TIPO preenchido: `TIPO = 'PRODUTO ACABADO' AND DISPONIVEL = 'Sim'`
- Se TIPO vazio em todos: `DISPONIVEL = 'Sim'` (inclui todos os disponíveis)

## Problema comum

A tabela `TIPO_PRODUTO` estava vazia (sem opções cadastradas). Como resultado:
- Produtos antigos tinham `TIPO='PRODUTO ACABADO'` digitado manualmente
- Produtos novos ficavam com `TIPO=NULL` (dropdown sem opções)
- Função pegava só os com TIPO='PRODUTO ACABADO', ignorando os novos

## Diagnóstico

```sql
SELECT tipo, COUNT(*) FROM produtos GROUP BY tipo ORDER BY 2 DESC
```

Se aparecer mistura de 'PRODUTO ACABADO' com NULL/vazio, é esse o filtro causando o problema.

## Fix

Limpar o campo TIPO de todos os produtos (sem perda de dados — campo não utilizado funcionalmente):

```sql
-- Verificar antes:
SELECT tipo, COUNT(*) FROM produtos GROUP BY tipo;

-- Aplicar:
UPDATE produtos SET tipo = NULL WHERE tipo IS NOT NULL AND tipo <> '';
```

Após o UPDATE, rodar a função "colocar todos na tabela de preço" — vai pegar todos com `DISPONIVEL='Sim'`.

## Tabelas relacionadas

- `TABELADEPRECO` — cabeçalho (TIPOPRECO=2, MARKUP=15 para TABELA ATACADO)
- `ITENSTABELAPRECO` — itens (CODIGO=id tabela, CODEMP, CODPROD, PRECO, PRECOBASE)
- `TIPO_PRODUTO` — opções do dropdown TIPO (sem FK com PRODUTOS)

## Caso real

- Banco: `CEM_tiagopetipeta260626.FDB`
- Problema: 252 produtos adicionados em vez de 1.522
- Causa: 868 com TIPO='PRODUTO ACABADO', 3.801 com TIPO='MATERIA PRIMA', restantes NULL
- Fix: UPDATE + rodar função → 1.522 produtos adicionados
