---
name: technical_classcomercial_arvore
description: CLASSCOMERCIAL.ARVORE é hierarquia em árvore; PRODUTOS.TIPO é o melhor filtro de categoria
metadata: 
  node_type: memory
  type: technical
  originSessionId: a100ae82-53d4-4114-8172-c23e8386b847
---

## CLASSCOMERCIAL — campo ARVORE e PRODUTOS.TIPO

### CLASSCOMERCIAL.ARVORE
Campo que armazena a hierarquia de categorias no formato `.0.PAI..FILHO.`.

Exemplo real (CEM_MOGIANA):
```
cod=0   CATEGORIAS        arvore=.0
cod=19  PRODUCÃO          arvore=.0.19.
cod=6   QUEIJOS           arvore=.0.19..6.
cod=10  PAINA             arvore=.0.19..6..10.
cod=11  BENTO             arvore=.0.19..6..11.
cod=12  BASTIÃO           arvore=.0.19..6..12.
cod=9   CAXANGA           arvore=.0.19..6..9.
```

**Para pegar todos os filhos de QUEIJOS (cod=6):**
```sql
WHERE cc.ARVORE LIKE '.0.19..6.%'
```

### PRODUTOS.TIPO
Campo VARCHAR que agrupa produtos por tipo funcional. Melhor que lista fixa de nomes de CLASSCOMERCIAL.

Valores encontrados em CEM_MOGIANA:
- `'QUEIJOS'`
- `'MATERIA PRIMA'`
- `'FERMENTOS'`
- `'COALHO'`
- `'SAL MARINHO REFINADO'`
- `'PRODUTOS PARA ESCRITÓRIO'`
- `NULL` (maioria)

**Filtro correto para queijos:**
```sql
WHERE p.TIPO = 'QUEIJOS'
```

**Vantagem sobre lista de nomes:** Se cadastrar nova subcategoria (ex: MINAS) com TIPO='QUEIJOS', entra automaticamente — sem precisar atualizar código.

**Why:** Descoberto ao construir relatório de estoque por lote para CEM_MOGIANA (17/07/2026). Lista fixa `IN ('BASTIAO','CAXANGA',...)` não pegaria tipos novos futuros.

**How to apply:** Sempre que precisar filtrar produtos por categoria genérica (queijos, matéria-prima, etc.), usar `PRODUTOS.TIPO` em vez de hardcode de nomes de CLASSCOMERCIAL.
