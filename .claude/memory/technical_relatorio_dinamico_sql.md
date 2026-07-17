---
name: technical_relatorio_dinamico_sql
description: "Relatório Dinâmico - SQL do Sistema RAM fica no servidor app.ramnuvem, não no banco do cliente"
metadata: 
  node_type: memory
  type: technical
  originSessionId: a100ae82-53d4-4114-8172-c23e8386b847
---

## Relatório Dinâmico - SQL — onde fica armazenado

**Feature:** Menu RELATÓRIOS > Relatório Dinâmico - SQL no Sistema RAM v18.

**Como funciona:**
- A equipe RAM ativa relatórios para um cliente via site interno, informando: código de usuário, código de licença do cliente e o SELECT.
- O SQL **não é gravado no banco local do cliente** (.FDB).
- O sistema busca os relatórios do servidor RAM (`app.ramnuvem`) na hora em que o cliente abre a tela.

**O que existe no FDB do cliente (mas vazio):**
- `USER_RELAT_COMERCIAL` — cols: CODIGO, CODUSER, CODEMP, NOME
- `USER_RELAT_FINANCEIRO` — cols: CODIGO, CODUSER, CODEMP, NOME
- `USER_RELAT_FISCAL` — cols: CODIGO, CODUSER, CODEMP, NOME
- `USER_RELAT_PRODUTOS` — cols: CODIGO, CODUSER, CODEMP, NOME

Essas tabelas ficam com 0 registros mesmo quando o cliente tem relatórios ativos — confirmado em CEM_MOGIANA com relatório "ESTOQUE" ativo.

**Conclusão:** Para listar/executar relatórios dinâmicos de um cliente fora do Sistema RAM, é necessário acesso ao banco/API do servidor `app.ramnuvem`, não ao FDB do cliente.

**Why:** Investigado em 17/07/2026 ao tentar construir ferramenta externa de visualização de relatórios dinâmicos SQL.

**How to apply:** Se precisar acessar relatórios dinâmicos de um cliente programaticamente, não procurar no FDB dele — o dado está no servidor.
