#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
RelatoriosCEM — Relatórios Firebird 2.5 para HTML/PDF
Sistema RAM
"""

import tkinter as tk
from tkinter import ttk, messagebox
import os
import re
import html as htmllib
import tempfile
import webbrowser
from datetime import date, datetime

try:
    import fdb
    FDB_OK = True
except ImportError:
    FDB_OK = False


# =============================================================================
# SQLs
# =============================================================================

SQL001 = """
SELECT c.nomfant   AS CLIENTE,
       c.municipio AS CIDADE,
       COUNT(DISTINCT p.codigo) AS QTD_PEDIDOS,
       SUM(ip.totalitem)        AS VALOR_TOTAL
FROM   pedidos p
INNER  JOIN cadastro c  ON c.codigo  = p.codcli
INNER  JOIN itenspad ip ON ip.codigo = p.codigo AND ip.codemp = p.codemp
WHERE  p.tipo = 'S'
  AND  p.aprovado = 1
  AND  (p.cancelado = 'N\xe3o' OR p.cancelado IS NULL OR p.cancelado = '0')
  AND  p.classpedido = 'Venda'
  AND  p.codemp = :CODEMP
  AND  p.dataemissao >= :DATA_INI
  AND  p.dataemissao <= :DATA_FIM
GROUP  BY c.nomfant, c.municipio
ORDER  BY VALOR_TOTAL DESC
"""

SQL002 = """
SELECT p.codigo, p.descricao, p.unidade, p.disponivel,
       p.codbarra,
       p.est_saldo AS SALDO,
       (SELECT MAX(e.DATA) FROM ESTOQUE e WHERE e.codprod = p.codigo) AS ULTIMA_MOV
FROM   PRODUTOS p
WHERE  p.codemp = :CODEMP
ORDER  BY p.descricao
"""

SQL003 = """
SELECT tp.nome AS CLASSIFICACAO,
       CASE WHEN refs.fluxo = 1 THEN refs.valor ELSE (refs.valor * -1) END AS VALOR_FLUXO,
       m.data_liq, refs.data_venc,
       c.nomfant AS CLIENTE
FROM   refs
INNER  JOIN moviment m  ON m.codigo  = refs.codigo
                       AND m.parcela = refs.parcela
                       AND m.codemp  = refs.codemp
LEFT   JOIN tipoplan tp ON tp.codigo = refs.cod_class
LEFT   JOIN cadastro c  ON c.codigo  = refs.COD_CLI
WHERE  refs.valor > 0
  AND  (refs.cancelado = 'N\xe3o' OR refs.cancelado IS NULL)
  AND  (refs.previsao  = 0 OR refs.previsao IS NULL)
  AND  (refs.agrupado  = 'N\xe3o' OR refs.agrupado IS NULL OR refs.agrupado = '')
  AND  refs.codemp = :CODEMP
  AND  m.data_liq >= :DATA_INI
  AND  m.data_liq <= :DATA_FIM
ORDER  BY m.data_liq DESC
"""

SQL004 = """
SELECT p.descricao, p.unidade,
       p.conta_contabil AS COLABORADOR,
       p.saldominimo,
       (SELECT FIRST 1 e.saldo
        FROM   ESTOQUE e
        WHERE  e.codprod = p.codigo AND e.codemp = :CODEMP
        ORDER  BY e.data DESC, e.tipo DESC, e.ordem DESC) AS SALDO_ATUAL,
       CAST(p.saldominimo -
            COALESCE((SELECT FIRST 1 e.saldo
                      FROM   ESTOQUE e
                      WHERE  e.codprod = p.codigo AND e.codemp = :CODEMP
                      ORDER  BY e.data DESC, e.tipo DESC, e.ordem DESC), 0)
       AS NUMERIC(15,2)) AS QTD_COMPRAR,
       p.precocusto, p.precominimo
FROM   produtos p
WHERE  p.disponivel = 'Sim'
  AND  p.codemp = :CODEMP
  AND  p.saldominimo NOT IN (0)
ORDER  BY p.conta_contabil, p.descricao
"""

SQL007 = """
SELECT p.codigo, p.descricao, p.unidade,
       p.est_saldo AS SALDO_FISICO,
       COALESCE(reserva.total_prometido, 0) AS RESERVADO,
       p.est_saldo - COALESCE(reserva.total_prometido, 0) AS SALDO_DISPONIVEL,
       p.saldominimo
FROM   produtos p
LEFT   JOIN (
    SELECT ip.codprod, SUM(ip.qtd) AS total_prometido
    FROM   itenspad ip
    INNER  JOIN pedidos pe ON pe.codigo = ip.codigo AND pe.codemp = ip.codemp
    WHERE  COALESCE(pe.cancelado, 'N\xe3o') <> 'Sim'
      AND  pe.status = '2 - EM SEPARA\xc7\xc3O'
    GROUP  BY ip.codprod
) reserva ON reserva.codprod = p.codigo
WHERE  p.disponivel = 'Sim'
  AND  p.codemp = :CODEMP
ORDER  BY p.descricao
"""

SQL011 = """
SELECT
  CASE WHEN EXTRACT(HOUR FROM pedidos.horacriado) < 10 THEN '0' ELSE '' END ||
  CAST(EXTRACT(HOUR FROM pedidos.horacriado) AS VARCHAR(2)) || ':00 - ' ||
  CASE WHEN EXTRACT(HOUR FROM pedidos.horacriado) < 10 THEN '0' ELSE '' END ||
  CAST(EXTRACT(HOUR FROM pedidos.horacriado) AS VARCHAR(2)) || ':59' AS INTERVALO_HORA,
  COUNT(*)                 AS QTD_PEDIDOS,
  SUM(pedidos.totalpedido) AS VALOR_TOTAL
FROM   pedidos
WHERE  pedidos.status = '5 - FINALIZADO'
  AND  (pedidos.cancelado = 'N\xe3o' OR pedidos.cancelado IS NULL)
  AND  pedidos.codemp = :CODEMP
  AND  pedidos.datacriado >= CURRENT_DATE - 60
GROUP  BY EXTRACT(HOUR FROM pedidos.horacriado)
ORDER  BY EXTRACT(HOUR FROM pedidos.horacriado)
"""

SQL012B = """
SELECT
  COALESCE(rem.nomraz,  'NAO IDENTIFICADO')   AS REMETENTE,
  COALESCE(n.municipio_termino_prest, 'NAO INFORMADO') AS CIDADE_ENTREGA,
  COALESCE(dest.nomraz, 'NAO IDENTIFICADO')   AS DESTINATARIO,
  COUNT(n.nf_numero)  AS QTD_ENTREGAS,
  SUM(n.nf_valnota)   AS VALOR_TOTAL,
  LIST(n.nfe, ', ')   AS NUMEROS_CTE
FROM   nota n
LEFT   JOIN cadastro rem  ON rem.codigo  = n.cod_remetente
LEFT   JOIN cadastro dest ON dest.codigo = n.nf_codcli
WHERE  n.nf_numero IS NOT NULL
  AND  n.nf_modelo = 'CTe'
  AND  n.nf_emissao >= :DATA_INI
  AND  n.nf_emissao <= :DATA_FIM
  AND  n.codemp = :CODEMP
  AND  n.motivo = 'Autorizado o uso do CT-e'
  AND  (:CODCLI = 0 OR n.cod_remetente = :CODCLI)
  AND  (COALESCE(CAST(:CIDADE AS VARCHAR(100)), '') = ''
        OR n.municipio_termino_prest CONTAINING CAST(:CIDADE AS VARCHAR(100)))
GROUP  BY n.cod_remetente, rem.nomraz, n.municipio_termino_prest, n.nf_codcli, dest.nomraz
ORDER  BY n.municipio_termino_prest, QTD_ENTREGAS DESC
"""

SQL013 = """
SELECT
  CASE WHEN EXTRACT(DAY   FROM CAST(DATACRIADO AS DATE)) < 10 THEN '0' ELSE '' END ||
  CAST(EXTRACT(DAY   FROM CAST(DATACRIADO AS DATE)) AS VARCHAR(2)) || '/' ||
  CASE WHEN EXTRACT(MONTH FROM CAST(DATACRIADO AS DATE)) < 10 THEN '0' ELSE '' END ||
  CAST(EXTRACT(MONTH FROM CAST(DATACRIADO AS DATE)) AS VARCHAR(2)) || '/' ||
  CAST(EXTRACT(YEAR  FROM CAST(DATACRIADO AS DATE)) AS VARCHAR(4)) AS DIA,
  CASE WHEN EXTRACT(HOUR FROM HORACRIADO) < 10 THEN '0' ELSE '' END ||
  CAST(EXTRACT(HOUR FROM HORACRIADO) AS VARCHAR(2)) || ':00 - ' ||
  CASE WHEN EXTRACT(HOUR FROM HORACRIADO) < 10 THEN '0' ELSE '' END ||
  CAST(EXTRACT(HOUR FROM HORACRIADO) AS VARCHAR(2)) || ':59'  AS INTERVALO_HORA,
  CODIGO      AS NUMERO_PEDIDO,
  1           AS TOTAL_PEDIDOS,
  CAST(TOTALPEDIDO AS NUMERIC(15,2)) AS VALOR_TOTAL
FROM   PEDIDOS
WHERE  APROVADO = 1
  AND  CLASSPEDIDO = 'Venda'
  AND  STATUS = 'VENDA'
  AND  EXTRACT(HOUR FROM HORACRIADO) BETWEEN 6 AND 22
  AND  CAST(DATACRIADO AS DATE) >= :DATA_INI
  AND  CAST(DATACRIADO AS DATE) <= :DATA_FIM
ORDER  BY CAST(DATACRIADO AS DATE), EXTRACT(HOUR FROM HORACRIADO), CODIGO
"""

SQL014 = """
SELECT c.codigo, c.nomfant AS CLIENTE, c.status,
       ult.data_ultimo_pedido,
       DATEDIFF(MONTH, ult.data_ultimo_pedido, CURRENT_DATE) AS MESES,
       DATEDIFF(DAY,   ult.data_ultimo_pedido, CURRENT_DATE) AS DIAS
FROM   cadastro c
LEFT   JOIN (
    SELECT p.codcli, MAX(p.dataemissao) AS data_ultimo_pedido
    FROM   pedidos p
    WHERE  p.tipo = 'S' AND p.classpedido = 'Venda' AND p.aprovado = 1
    GROUP  BY p.codcli
) ult ON ult.codcli = c.codigo
WHERE  c.codigo IS NOT NULL
  AND  NOT EXISTS (
      SELECT 1 FROM pedidos p
      WHERE  p.codcli = c.codigo
        AND  p.tipo = 'S' AND p.classpedido = 'Venda' AND p.aprovado = 1
        AND  p.dataemissao >= :DATA_INI
        AND  p.dataemissao <= :DATA_FIM
  )
ORDER  BY ult.data_ultimo_pedido DESC
"""

# =============================================================================
# Definição dos relatórios
# =============================================================================

RELATORIOS = [
    {
        'code': 'SQL001', 'name': 'Pedidos por Cliente',
        'desc': 'Total de pedidos de venda agrupado por cliente no período',
        'sql': SQL001,
        'params': [
            {'n': 'DATA_INI', 'lbl': 'Data Início',  'tp': 'date', 'def': 'MONTH_START'},
            {'n': 'DATA_FIM', 'lbl': 'Data Fim',     'tp': 'date', 'def': 'TODAY'},
            {'n': 'CODEMP',   'lbl': 'Empresa',      'tp': 'int',  'def': '1'},
        ],
    },
    {
        'code': 'SQL002', 'name': 'Lista de Produtos',
        'desc': 'Todos os produtos com saldo e data da última movimentação',
        'sql': SQL002,
        'params': [
            {'n': 'CODEMP', 'lbl': 'Empresa', 'tp': 'int', 'def': '1'},
        ],
    },
    {
        'code': 'SQL003', 'name': 'Financeiro por Período',
        'desc': 'Movimentações financeiras liquidadas no período',
        'sql': SQL003,
        'params': [
            {'n': 'DATA_INI', 'lbl': 'Data Início', 'tp': 'date', 'def': 'MONTH_START'},
            {'n': 'DATA_FIM', 'lbl': 'Data Fim',    'tp': 'date', 'def': 'TODAY'},
            {'n': 'CODEMP',   'lbl': 'Empresa',     'tp': 'int',  'def': '1'},
        ],
    },
    {
        'code': 'SQL004', 'name': 'Compra Estoque (Abaixo do Mínimo)',
        'desc': 'Produtos abaixo do saldo mínimo agrupados por colaborador responsável',
        'sql': SQL004,
        'params': [
            {'n': 'CODEMP', 'lbl': 'Empresa', 'tp': 'int', 'def': '1'},
        ],
    },
    {
        'code': 'SQL007', 'name': 'Estoque Físico vs Disponível',
        'desc': 'Saldo físico x disponível descontando pedidos em separação',
        'sql': SQL007,
        'params': [
            {'n': 'CODEMP', 'lbl': 'Empresa', 'tp': 'int', 'def': '1'},
        ],
    },
    {
        'code': 'SQL011', 'name': 'Vendas por Horário (60 dias)',
        'desc': 'Distribuição de vendas por hora do dia nos últimos 60 dias',
        'sql': SQL011,
        'params': [
            {'n': 'CODEMP', 'lbl': 'Empresa', 'tp': 'int', 'def': '1'},
        ],
    },
    {
        'code': 'SQL012B', 'name': 'Entregas CT-e por Destinatário',
        'desc': 'CT-e agrupados por remetente, cidade e destinatário (transportadora)',
        'sql': SQL012B,
        'params': [
            {'n': 'DATA_INI', 'lbl': 'Data Início',           'tp': 'date', 'def': 'MONTH_START'},
            {'n': 'DATA_FIM', 'lbl': 'Data Fim',              'tp': 'date', 'def': 'TODAY'},
            {'n': 'CODEMP',   'lbl': 'Empresa',               'tp': 'int',  'def': '1'},
            {'n': 'CODCLI',   'lbl': 'Cód. Remetente (0=todos)', 'tp': 'int', 'def': '0'},
            {'n': 'CIDADE',   'lbl': 'Cidade (vazio=todas)',  'tp': 'str',  'def': ''},
        ],
    },
    {
        'code': 'SQL013', 'name': 'Vendas por Dia e Hora',
        'desc': 'Pedidos de venda detalhados por dia e intervalo de hora no período',
        'sql': SQL013,
        'params': [
            {'n': 'DATA_INI', 'lbl': 'Data Início', 'tp': 'date', 'def': 'MONTH_START'},
            {'n': 'DATA_FIM', 'lbl': 'Data Fim',    'tp': 'date', 'def': 'TODAY'},
        ],
    },
]

# =============================================================================
# Utilitários
# =============================================================================

def named_to_positional(sql: str, params: dict):
    """
    Converte SQL com :nome para ? posicional e retorna (sql, lista_de_valores).
    Necessário porque fdb no Python 3.14 não faz essa conversão automaticamente.
    Parâmetros duplicados (ex: :CODEMP aparece 3x) são adicionados à lista 3x.
    """
    values = []

    def replacer(match):
        name = match.group(1)
        values.append(params.get(name))
        return '?'

    new_sql = re.sub(r':([A-Za-z_]\w*)', replacer, sql)
    return new_sql, values


AZUL        = '#1a5276'
AZUL_CLARO  = '#eaf0fb'
AZUL_MEDIO  = '#d5eaf5'
BRANCO      = '#ffffff'

def default_date(key: str) -> str:
    """Retorna data padrão no formato DD/MM/AAAA."""
    today = date.today()
    if key == 'MONTH_START':
        return date(today.year, today.month, 1).strftime('%d/%m/%Y')
    return today.strftime('%d/%m/%Y')


def parse_date(s: str) -> date:
    try:
        return datetime.strptime(s.strip(), '%d/%m/%Y').date()
    except ValueError:
        raise ValueError(f'Data inválida: "{s}"\nFormato esperado: DD/MM/AAAA')


def fmt_value(v) -> str:
    if v is None:
        return ''
    if isinstance(v, date):
        return v.strftime('%d/%m/%Y')
    return str(v)


CSS = """
* { box-sizing: border-box; }
body { font-family: 'Segoe UI', Arial, sans-serif; margin: 0; padding: 20px; color: #2c3e50; }
.topo { border-bottom: 3px solid #1a5276; padding-bottom: 10px; margin-bottom: 14px; }
.topo h1 { margin: 0; color: #1a5276; font-size: 20px; }
.topo p  { margin: 4px 0 0; color: #5d6d7e; font-size: 13px; }
.params  { background: #eaf0fb; border-left: 4px solid #1a5276; padding: 8px 12px; margin-bottom: 14px; font-size: 13px; color: #1a5276; }
table { width: 100%; border-collapse: collapse; font-size: 13px; }
thead th { background: #1a5276; color: #fff; padding: 8px 10px; text-align: left;
           -webkit-print-color-adjust: exact; print-color-adjust: exact; }
tbody tr:nth-child(even) { background: #eaf0fb; }
tbody tr:hover { background: #d4e6f1; }
tbody td { padding: 6px 10px; border-bottom: 1px solid #d5dbdb; }
.rodape { margin-top: 18px; font-size: 11px; color: #aaa; text-align: right;
          border-top: 1px solid #ddd; padding-top: 8px; }
.btn-print { display: block; margin: 16px auto; padding: 10px 30px;
             background: #1a5276; color: #fff; border: none; border-radius: 4px;
             font-size: 14px; cursor: pointer; }
@media print { .btn-print { display: none; } body { padding: 5mm; } }
"""


def build_html(report_name: str, desc: str, param_str: str,
               columns: list, rows: list) -> str:
    def td(v):
        s = fmt_value(v)
        try:
            float(s.replace(',', '.').replace(' ', ''))
            return f'<td style="text-align:right">{htmllib.escape(s)}</td>'
        except ValueError:
            return f'<td>{htmllib.escape(s)}</td>'

    headers = ''.join(f'<th>{htmllib.escape(c)}</th>' for c in columns)
    body_rows = '\n'.join(
        '<tr>' + ''.join(td(c) for c in row) + '</tr>' for row in rows
    )

    return f"""<!DOCTYPE html>
<html lang="pt-BR"><head>
<meta charset="UTF-8">
<title>Sistema RAM — {htmllib.escape(report_name)}</title>
<style>{CSS}</style>
</head><body>
<div class="topo">
  <h1>Sistema RAM &mdash; {htmllib.escape(report_name)}</h1>
  <p>{htmllib.escape(desc)}</p>
</div>
<div class="params"><strong>Parâmetros:</strong> {htmllib.escape(param_str)}</div>
<table>
  <thead><tr>{headers}</tr></thead>
  <tbody>{body_rows}</tbody>
</table>
<div class="rodape">
  Gerado em {datetime.now().strftime('%d/%m/%Y %H:%M:%S')} &mdash; {len(rows)} registro(s)
</div>
<button class="btn-print" onclick="window.print()">&#128438; Imprimir / Salvar como PDF</button>
</body></html>"""


# =============================================================================
# Aplicação principal
# =============================================================================

class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title('Relatórios CEM — Sistema RAM')
        self.geometry('1120x760')
        self.minsize(900, 600)
        self.resizable(True, True)
        self.configure(bg=AZUL_CLARO)

        self._con = None
        self._cols = []
        self._rows = []
        self._param_entries: list[tk.StringVar] = []
        self._current_report = None

        self._build_ui()
        self._load_reports()

        if not FDB_OK:
            messagebox.showwarning(
                'fdb não encontrado',
                'A biblioteca "fdb" não está instalada.\n\n'
                'Execute INSTALAR_E_CRIAR_EXE.bat para instalar e compilar,\n'
                'ou abra um terminal e rode:\n\n    pip install fdb'
            )

    # ── Construção da interface ──────────────────────────────────────────────

    def _build_ui(self):
        # Cabeçalho de conexão
        fr_conn = tk.Frame(self, bg=AZUL, pady=6, padx=10)
        fr_conn.pack(fill='x')

        tk.Label(fr_conn, text='Banco:', bg=AZUL, fg='white',
                 font=('Segoe UI', 9, 'bold')).grid(row=0, column=0, sticky='w', padx=(0, 4))
        self.e_db = tk.Entry(fr_conn, width=58, font=('Segoe UI', 9))
        self.e_db.insert(0, r'C:\Users\ram\Documents\Bases_clientes_gerador\CEM.FDB')
        self.e_db.grid(row=0, column=1, padx=(0, 12))

        tk.Label(fr_conn, text='Usuário:', bg=AZUL, fg='white',
                 font=('Segoe UI', 9, 'bold')).grid(row=0, column=2, sticky='w', padx=(0, 4))
        self.e_user = tk.Entry(fr_conn, width=10, font=('Segoe UI', 9))
        self.e_user.insert(0, 'SYSDBA')
        self.e_user.grid(row=0, column=3, padx=(0, 12))

        tk.Label(fr_conn, text='Senha:', bg=AZUL, fg='white',
                 font=('Segoe UI', 9, 'bold')).grid(row=0, column=4, sticky='w', padx=(0, 4))
        self.e_pass = tk.Entry(fr_conn, width=12, show='*', font=('Segoe UI', 9))
        self.e_pass.insert(0, 'masterkey')
        self.e_pass.grid(row=0, column=5, padx=(0, 14))

        self.btn_conn = tk.Button(fr_conn, text='Conectar', width=12,
                                  bg='white', fg=AZUL, font=('Segoe UI', 9, 'bold'),
                                  relief='flat', cursor='hand2',
                                  command=self._toggle_connect)
        self.btn_conn.grid(row=0, column=6, padx=(0, 10))

        self.lbl_status = tk.Label(fr_conn, text='● Desconectado', bg=AZUL,
                                   fg='#e74c3c', font=('Segoe UI', 9, 'bold'))
        self.lbl_status.grid(row=0, column=7, sticky='w')

        # Seleção de relatório
        fr_sel = tk.Frame(self, bg=AZUL_CLARO, pady=6, padx=10)
        fr_sel.pack(fill='x')

        tk.Label(fr_sel, text='Relatório:', bg=AZUL_CLARO,
                 font=('Segoe UI', 10, 'bold')).pack(side='left', padx=(0, 6))

        self.cb_rel = ttk.Combobox(fr_sel, state='readonly', width=50,
                                   font=('Segoe UI', 10))
        self.cb_rel.pack(side='left')
        self.cb_rel.bind('<<ComboboxSelected>>', self._on_rel_change)

        self.lbl_desc = tk.Label(fr_sel, text='', bg=AZUL_CLARO,
                                 fg='#5d6d7e', font=('Segoe UI', 9))
        self.lbl_desc.pack(side='left', padx=14)

        # Painel de parâmetros
        self.fr_params = tk.Frame(self, bg=AZUL_CLARO, padx=10, pady=6)
        self.fr_params.pack(fill='x')

        # Botões de ação
        fr_act = tk.Frame(self, bg=AZUL_MEDIO, padx=10, pady=6)
        fr_act.pack(fill='x')

        self.btn_gerar = tk.Button(fr_act, text='▶  Gerar Relatório', width=20,
                                   bg=AZUL, fg='white', font=('Segoe UI', 10, 'bold'),
                                   relief='flat', cursor='hand2',
                                   state='disabled', command=self._gerar)
        self.btn_gerar.pack(side='left', padx=(0, 8))

        self.btn_html = tk.Button(fr_act, text='⬇  Exportar HTML / PDF', width=22,
                                  bg='#1f8049', fg='white', font=('Segoe UI', 10, 'bold'),
                                  relief='flat', cursor='hand2',
                                  state='disabled', command=self._exportar_html)
        self.btn_html.pack(side='left', padx=(0, 16))

        self.lbl_count = tk.Label(fr_act, text='', bg=AZUL_MEDIO,
                                  fg=AZUL, font=('Segoe UI', 9, 'bold'))
        self.lbl_count.pack(side='left')

        # Grade de resultados (Treeview com scrollbars)
        fr_tree = tk.Frame(self, bg=BRANCO)
        fr_tree.pack(fill='both', expand=True, padx=4, pady=4)

        style = ttk.Style()
        style.configure('Custom.Treeview.Heading',
                         background=AZUL, foreground='white',
                         font=('Segoe UI', 9, 'bold'))
        style.configure('Custom.Treeview',
                         font=('Segoe UI', 9), rowheight=22,
                         foreground='#1a1a1a', background='white',
                         fieldbackground='white')
        style.map('Custom.Treeview',
                  background=[('selected', AZUL_MEDIO)],
                  foreground=[('selected', '#1a1a1a')])

        vsb = ttk.Scrollbar(fr_tree, orient='vertical')
        hsb = ttk.Scrollbar(fr_tree, orient='horizontal')
        self.tree = ttk.Treeview(fr_tree, style='Custom.Treeview',
                                  yscrollcommand=vsb.set,
                                  xscrollcommand=hsb.set,
                                  selectmode='browse')
        vsb.configure(command=self.tree.yview)
        hsb.configure(command=self.tree.xview)

        vsb.pack(side='right', fill='y')
        hsb.pack(side='bottom', fill='x')
        self.tree.pack(fill='both', expand=True)

        self.tree.tag_configure('odd',  background='#f4f6f8', foreground='#1a1a1a')
        self.tree.tag_configure('even', background='#ffffff', foreground='#1a1a1a')

    # ── Carregar lista de relatórios ─────────────────────────────────────────

    def _load_reports(self):
        self.cb_rel['values'] = [r['name'] for r in RELATORIOS]
        if RELATORIOS:
            self.cb_rel.current(0)
            self._on_rel_change(None)

    # ── Mudança de relatório selecionado ─────────────────────────────────────

    def _on_rel_change(self, _event):
        idx = self.cb_rel.current()
        if idx < 0:
            return
        r = RELATORIOS[idx]
        self._current_report = r
        self.lbl_desc.config(text=r['desc'])
        self._build_params(r)
        self.lbl_count.config(text='')
        self.btn_html.config(state='disabled')
        self._clear_tree()

    def _build_params(self, report):
        for w in self.fr_params.winfo_children():
            w.destroy()
        self._param_entries = []

        COL_W = 300
        per_row = max(1, (self.winfo_width() - 20) // COL_W) or 3
        row = col = 0

        for p in report['params']:
            var = tk.StringVar()
            if p['tp'] == 'date':
                var.set(default_date(p['def']))
            else:
                var.set(p['def'])
            self._param_entries.append(var)

            tk.Label(self.fr_params, text=p['lbl'] + ':', bg=AZUL_CLARO,
                     font=('Segoe UI', 9, 'bold'), anchor='w', width=22
                     ).grid(row=row, column=col * 2,     sticky='w', padx=(0, 2), pady=2)
            tk.Entry(self.fr_params, textvariable=var, width=18,
                     font=('Segoe UI', 9)
                     ).grid(row=row, column=col * 2 + 1, sticky='w', padx=(0, 20), pady=2)
            col += 1
            if col >= per_row:
                col = 0
                row += 1

    # ── Conexão com Firebird ─────────────────────────────────────────────────

    def _toggle_connect(self):
        if self._con is not None:
            try:
                self._con.close()
            except Exception:
                pass
            self._con = None
            self._set_status(False)
            self.btn_conn.config(text='Conectar')
            self.btn_gerar.config(state='disabled')
            return

        if not FDB_OK:
            messagebox.showerror('fdb não instalado',
                                 'Execute INSTALAR_E_CRIAR_EXE.bat primeiro.')
            return

        try:
            self._con = fdb.connect(
                host='localhost',
                database=self.e_db.get().strip(),
                user=self.e_user.get().strip(),
                password=self.e_pass.get().strip(),
                charset='WIN1252',
            )
            self._set_status(True)
            self.btn_conn.config(text='Desconectar')
            self.btn_gerar.config(state='normal')
        except Exception as ex:
            messagebox.showerror('Erro de conexão', str(ex))
            self._con = None
            self._set_status(False)

    def _set_status(self, ok: bool):
        if ok:
            self.lbl_status.config(text='● Conectado', fg='#27ae60')
        else:
            self.lbl_status.config(text='● Desconectado', fg='#e74c3c')

    # ── Gerar relatório ──────────────────────────────────────────────────────

    def _gerar(self):
        r = self._current_report
        if r is None or self._con is None:
            return

        try:
            params = self._build_params_dict(r)
        except ValueError as ex:
            messagebox.showerror('Parâmetro inválido', str(ex))
            return

        self.lbl_count.config(text='Executando...')
        self.update_idletasks()
        try:
            cur = self._con.cursor()
            sql_q, vals = named_to_positional(r['sql'], params)
            cur.execute(sql_q, vals)
            self._cols = [d[0] for d in cur.description]
            self._rows = cur.fetchall()
            cur.close()
        except Exception as ex:
            messagebox.showerror('Erro na consulta', str(ex))
            self.lbl_count.config(text='Erro!')
            return

        self._fill_tree()
        self.lbl_count.config(
            text=f'{len(self._rows)} registro(s)'
                 + (' — role a tabela para ver todos' if len(self._rows) >= 5000 else '')
        )
        self.btn_html.config(state='normal')

    def _build_params_dict(self, report) -> dict:
        params = {}
        for i, p in enumerate(report['params']):
            val = self._param_entries[i].get().strip()
            if p['tp'] == 'date':
                params[p['n']] = parse_date(val)
            elif p['tp'] == 'int':
                params[p['n']] = int(val) if val else 0
            else:
                params[p['n']] = val
        return params

    # ── Preencher Treeview ───────────────────────────────────────────────────

    def _clear_tree(self):
        self.tree.delete(*self.tree.get_children())
        self.tree['columns'] = ()
        self.tree['show'] = 'headings'

    def _fill_tree(self):
        self._clear_tree()
        if not self._cols:
            return

        self.tree['columns'] = self._cols
        self.tree['show'] = 'headings'

        for c in self._cols:
            self.tree.heading(c, text=c)
            self.tree.column(c, width=130, anchor='center', stretch=True)

        for i, row in enumerate(self._rows):
            tag = 'even' if i % 2 == 0 else 'odd'
            self.tree.insert('', 'end',
                             values=[fmt_value(v) for v in row],
                             tags=(tag,))

    # ── Exportar HTML / PDF ──────────────────────────────────────────────────

    def _exportar_html(self):
        r = self._current_report
        if r is None or not self._rows:
            return

        param_str = ' | '.join(
            f"{p['lbl']}: {self._param_entries[i].get()}"
            for i, p in enumerate(r['params'])
        )

        html_content = build_html(r['name'], r['desc'], param_str,
                                  self._cols, self._rows)

        tmp = tempfile.NamedTemporaryFile(
            mode='w', suffix='.html', encoding='utf-8',
            prefix='relatorio_cem_', delete=False
        )
        tmp.write(html_content)
        tmp.close()

        webbrowser.open(f'file:///{tmp.name.replace(chr(92), "/")}')


# =============================================================================
# Entry point
# =============================================================================

if __name__ == '__main__':
    app = App()
    app.mainloop()
