---
name: project-developerbd
description: Contexto do projeto DeveloperBD — relatórios Python + Firebird para Sistema RAM
metadata: 
  node_type: memory
  type: project
  originSessionId: 12e19c05-6df5-492b-9375-21ff480f39c8
---

## Projeto DeveloperBD

Repositório GitHub: `github.com/MicaellyMariano/DeveloperBD`

### RelatoriosCEM (delphi-relatorios/)
App Python/tkinter que conecta ao Firebird 2.5 e exibe 8 relatórios SQL em tabela visual.

**Arquivo principal:** `delphi-relatorios/relatorios_cem.py`

**Fix crítico implementado:** `named_to_positional()` — fdb no Python 3.14 não converte `:name` → `?` antes de enviar ao Firebird. Fix:
```python
import re
def named_to_positional(sql: str, params: dict):
    values = []
    def replacer(match):
        name = match.group(1)
        values.append(params.get(name))
        return '?'
    new_sql = re.sub(r':([A-Za-z_]\w*)', replacer, sql)
    return new_sql, values
```

**Visual fix:** Treeview foreground `#1a1a1a` (texto escuro legível)

**Compilar EXE:** `python -m PyInstaller` (não `pyinstaller` diretamente — não está no PATH)
- Bat files precisam de `cd /d "%~dp0"` no topo
- Usar apenas ASCII em echo (sem caracteres especiais — causa erro no CMD)

**Why:** evitar necessidade do Delphi; gerar `.exe` standalone para a Micaelly distribuir

### Bancos dos clientes
- CEM.FDB = CONFESPAN (empresa 1) + RITCHS PAN (empresa 2) — charset WIN1252, SYSDBA/masterkey
- CEM_nalinindutstria.FDB = Nali Indústria
- ~20 arquivos .FDB em `C:\Users\ram-0003\Desktop\Bases\` e similares

### Estrutura do banco (CONFESPAN/CEM.FDB)
- ESTOQUE = log de movimentações (não saldo único); saldo atual = FIRST 1 ORDER BY data DESC
- PRODUTOS: campo `DISPONIVEL` = 'Sim'/'Não'; campo `NUMCATALOGO` = número de catálogo
- Multi-empresa: CODEMP 1 = CONFESPAN, CODEMP 2 = RITCHS PAN
- Status pedido que movimenta estoque: apenas "PEDIDO CONFERIDO" (não "PEDIDO" sozinho)

**How to apply:** ao consultar bancos Firebird do sistema RAM, lembrar dessas convenções de campos e comportamento do ESTOQUE.
