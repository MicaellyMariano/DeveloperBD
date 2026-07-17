---
name: technical_replicador_column_unknown
description: "Replicador interno dá \"Column unknown\" = versão desatualizada; solução é atualizar o replicador"
metadata: 
  node_type: memory
  type: project
  originSessionId: a100ae82-53d4-4114-8172-c23e8386b847
---

## Replicador interno — erro "Column unknown"

**Sintoma:** replicador loga erro como:
```
ERROR: [FireDAC][Phys][FB]Dynamic SQL Error
SQL error code = -206
Column unknown
CUSTO_ADD
At line 1, column 3092
```

**Causa:** o banco local tem uma coluna nova (ex: `CUSTO_ADD` na tabela `CADASTRO`) que o banco da nuvem ainda não tem. O replicador gera INSERT/UPDATE com todas as colunas e o Firebird da nuvem rejeita.

**Solução confirmada:** atualizar o **Sistema RAM no servidor app.ramnuvem** para a mesma versão que está rodando no cliente local. O servidor precisa estar sempre na mesma versão do sistema do cliente — a atualização do sistema no servidor é que traz o schema atualizado para a nuvem.

**Diagnóstico manual (se necessário):** rodar no banco local e na nuvem e comparar:
```sql
SELECT rf.RDB$RELATION_NAME, rf.RDB$FIELD_NAME, rf.RDB$FIELD_POSITION
FROM RDB$RELATION_FIELDS rf
JOIN RDB$RELATIONS r ON r.RDB$RELATION_NAME = rf.RDB$RELATION_NAME
WHERE r.RDB$SYSTEM_FLAG = 0
ORDER BY rf.RDB$RELATION_NAME, rf.RDB$FIELD_POSITION
```

**Why:** o banco local recebe atualizações de schema junto com o sistema instalado no cliente; o banco na nuvem (app.ramnuvem) só recebe o schema novo quando o sistema é atualizado no servidor — se o servidor estiver numa versão anterior, as colunas novas não existem lá.

**How to apply:** sempre que aparecer "Column unknown" no log do replicador, verificar se o Sistema RAM no servidor app.ramnuvem está na mesma versão do cliente local. Atualizar o sistema no servidor resolve.
