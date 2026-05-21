unit URelatorios;

interface

type
  TParamKind = (pkDate, pkInteger, pkString);

  TParamDef = record
    ParamName   : string;
    Caption     : string;
    Kind        : TParamKind;
    DefaultValue: string;   // 'TODAY', 'MONTH_START' ou valor literal
    Optional    : Boolean;
  end;

  TRelatorioDef = record
    Code       : string;
    Name       : string;
    Description: string;
    SQL        : string;
    Params     : array of TParamDef;
  end;

function GetRelatorios: TArray<TRelatorioDef>;

implementation

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function MkParam(const AName, ACaption: string; AKind: TParamKind;
  const ADefault: string = ''; AOptional: Boolean = False): TParamDef;
begin
  Result.ParamName    := AName;
  Result.Caption      := ACaption;
  Result.Kind         := AKind;
  Result.DefaultValue := ADefault;
  Result.Optional     := AOptional;
end;

function MkRel(const ACode, AName, ADesc, ASQL: string;
  const AParams: array of TParamDef): TRelatorioDef;
var
  i: Integer;
begin
  Result.Code        := ACode;
  Result.Name        := AName;
  Result.Description := ADesc;
  Result.SQL         := ASQL;
  SetLength(Result.Params, Length(AParams));
  for i := 0 to High(AParams) do
    Result.Params[i] := AParams[i];
end;

// ---------------------------------------------------------------------------
// SQL Constants
// ---------------------------------------------------------------------------

const

  // SQL-001 — Pedidos por Cliente
  SQL001 =
    'SELECT c.nomfant AS cliente, c.municipio AS cidade, ' +
    '  COUNT(DISTINCT p.codigo) AS qtd_pedidos, ' +
    '  SUM(ip.totalitem) AS valor_total ' +
    'FROM pedidos p ' +
    'INNER JOIN cadastro c  ON c.codigo = p.codcli ' +
    'INNER JOIN itenspad ip ON ip.codigo = p.codigo AND ip.codemp = p.codemp ' +
    'WHERE p.tipo = ''S'' ' +
    '  AND p.aprovado = 1 ' +
    '  AND (p.cancelado = ''Nao'' OR p.cancelado IS NULL OR p.cancelado = ''0'') ' +
    '  AND p.classpedido = ''Venda'' ' +
    '  AND p.codemp IN (:CODEMP) ' +
    '  AND p.dataemissao >= :DATA_INI ' +
    '  AND p.dataemissao <= :DATA_FIM ' +
    'GROUP BY c.nomfant, c.municipio ' +
    'ORDER BY valor_total DESC';

  // SQL-002 — Lista de Produtos
  SQL002 =
    'SELECT p.codigo, p.descricao, p.unidade, p.disponivel, p.codbarra, ' +
    '  p.est_saldo AS saldo, ' +
    '  (SELECT MAX(e.DATA) FROM ESTOQUE e WHERE e.codprod = p.codigo) AS ultima_mov ' +
    'FROM PRODUTOS p ' +
    'WHERE p.codemp IN (:CODEMP) ' +
    'ORDER BY p.descricao';

  // SQL-003 — Financeiro por Período
  SQL003 =
    'SELECT tp.nome AS classificacao, ' +
    '  CASE WHEN refs.fluxo = 1 THEN refs.valor ELSE (refs.valor * -1) END AS valor_fluxo, ' +
    '  m.data_liq, refs.data_venc, c.nomfant AS cliente ' +
    'FROM refs ' +
    'INNER JOIN moviment m  ON m.codigo  = refs.codigo  AND m.parcela  = refs.parcela ' +
    '                      AND m.codemp  = refs.codemp ' +
    'LEFT  JOIN tipoplan tp ON tp.codigo  = refs.cod_class ' +
    'LEFT  JOIN cadastro c  ON c.codigo   = refs.COD_CLI ' +
    'WHERE refs.valor > 0 ' +
    '  AND (refs.cancelado = ''Nao'' OR refs.cancelado IS NULL) ' +
    '  AND (refs.previsao  = 0 OR refs.previsao IS NULL) ' +
    '  AND (refs.agrupado = ''Nao'' OR refs.agrupado IS NULL OR refs.agrupado = '''') ' +
    '  AND refs.codemp IN (:CODEMP) ' +
    '  AND m.data_liq >= :DATA_INI ' +
    '  AND m.data_liq <= :DATA_FIM ' +
    'ORDER BY m.data_liq DESC';

  // SQL-004 — Compra Estoque por Colaborador (abaixo do mínimo)
  SQL004 =
    'SELECT p.descricao, p.unidade, p.conta_contabil AS colaborador, ' +
    '  p.saldominimo, ' +
    '  (SELECT FIRST 1 e.saldo FROM ESTOQUE e ' +
    '   WHERE e.codprod = p.codigo AND e.codemp = :CODEMP ' +
    '   ORDER BY e.data DESC, e.tipo DESC, e.ordem DESC) AS saldo_atual, ' +
    '  CAST((p.saldominimo - ' +
    '    (SELECT FIRST 1 COALESCE(e.saldo,0) FROM ESTOQUE e ' +
    '     WHERE e.codprod = p.codigo AND e.codemp = :CODEMP ' +
    '     ORDER BY e.data DESC, e.tipo DESC, e.ordem DESC) ' +
    '  ) AS NUMERIC(15,2)) AS qtd_comprar, ' +
    '  p.precocusto, p.precominimo ' +
    'FROM produtos p ' +
    'WHERE p.disponivel = ''Sim'' ' +
    '  AND p.codemp IN (:CODEMP) ' +
    '  AND p.saldominimo NOT IN (0) ' +
    'ORDER BY p.conta_contabil, p.descricao';

  // SQL-007 — Estoque Físico vs Disponível
  SQL007 =
    'SELECT p.codigo, p.descricao, p.unidade, ' +
    '  p.est_saldo AS saldo_fisico, ' +
    '  COALESCE(reserva.total_prometido, 0) AS reservado, ' +
    '  p.est_saldo - COALESCE(reserva.total_prometido, 0) AS saldo_disponivel, ' +
    '  p.saldominimo ' +
    'FROM produtos p ' +
    'LEFT JOIN ( ' +
    '  SELECT ip.codprod, SUM(ip.qtd) AS total_prometido ' +
    '  FROM itenspad ip ' +
    '  INNER JOIN pedidos pe ON pe.codigo = ip.codigo AND pe.codemp = ip.codemp ' +
    '  WHERE COALESCE(pe.cancelado, ''Nao'') <> ''Sim'' ' +
    '    AND pe.status = ''2 - EM SEPARACAO'' ' +
    '  GROUP BY ip.codprod ' +
    ') reserva ON reserva.codprod = p.codigo ' +
    'WHERE p.disponivel = ''Sim'' ' +
    '  AND p.codemp IN (:CODEMP) ' +
    'ORDER BY p.descricao';

  // SQL-011 — Vendas por Horário (últimos 60 dias)
  SQL011 =
    'SELECT ' +
    '  CASE WHEN EXTRACT(HOUR FROM pedidos.horacriado) < 10 THEN ''0'' ELSE '''' END || ' +
    '  CAST(EXTRACT(HOUR FROM pedidos.horacriado) AS VARCHAR(2)) || '':00 - '' || ' +
    '  CASE WHEN EXTRACT(HOUR FROM pedidos.horacriado) < 10 THEN ''0'' ELSE '''' END || ' +
    '  CAST(EXTRACT(HOUR FROM pedidos.horacriado) AS VARCHAR(2)) || '':59'' AS intervalo_hora, ' +
    '  COUNT(*)                    AS qtd_pedidos, ' +
    '  SUM(pedidos.totalpedido)    AS valor_total ' +
    'FROM pedidos ' +
    'WHERE pedidos.status = ''5 - FINALIZADO'' ' +
    '  AND (pedidos.cancelado = ''Nao'' OR pedidos.cancelado IS NULL) ' +
    '  AND pedidos.codemp IN (:CODEMP) ' +
    '  AND pedidos.datacriado >= CURRENT_DATE - 60 ' +
    'GROUP BY EXTRACT(HOUR FROM pedidos.horacriado) ' +
    'ORDER BY EXTRACT(HOUR FROM pedidos.horacriado)';

  // SQL-012b — Entregas CT-e por Destinatário e Cidade
  SQL012B =
    'SELECT ' +
    '  COALESCE(rem.nomraz,  ''NAO IDENTIFICADO'') AS remetente, ' +
    '  COALESCE(n.municipio_termino_prest, ''NAO INFORMADO'') AS cidade_entrega, ' +
    '  COALESCE(dest.nomraz, ''NAO IDENTIFICADO'') AS destinatario, ' +
    '  COUNT(n.nf_numero)    AS qtd_entregas, ' +
    '  SUM(n.nf_valnota)     AS valor_total, ' +
    '  LIST(n.nfe, '', '')   AS numeros_cte ' +
    'FROM nota n ' +
    'LEFT JOIN cadastro rem  ON rem.codigo  = n.cod_remetente ' +
    'LEFT JOIN cadastro dest ON dest.codigo = n.nf_codcli ' +
    'WHERE n.nf_numero IS NOT NULL ' +
    '  AND n.nf_modelo = ''CTe'' ' +
    '  AND n.nf_emissao >= :DATA_INI ' +
    '  AND n.nf_emissao <= :DATA_FIM ' +
    '  AND n.codemp IN (:CODEMP) ' +
    '  AND n.motivo = ''Autorizado o uso do CT-e'' ' +
    '  AND (:CODCLI = 0 OR n.cod_remetente = :CODCLI) ' +
    '  AND (COALESCE(CAST(:CIDADE AS VARCHAR(100)), '''') = '''' ' +
    '    OR n.municipio_termino_prest CONTAINING CAST(:CIDADE AS VARCHAR(100))) ' +
    'GROUP BY n.cod_remetente, rem.nomraz, n.municipio_termino_prest, n.nf_codcli, dest.nomraz ' +
    'ORDER BY n.municipio_termino_prest, qtd_entregas DESC';

  // SQL-013 — Vendas por Dia e Hora com Período
  SQL013 =
    'SELECT ' +
    '  CASE WHEN EXTRACT(DAY   FROM CAST(DATACRIADO AS DATE)) < 10 THEN ''0'' ELSE '''' END || ' +
    '  CAST(EXTRACT(DAY   FROM CAST(DATACRIADO AS DATE)) AS VARCHAR(2)) || ''/'' || ' +
    '  CASE WHEN EXTRACT(MONTH FROM CAST(DATACRIADO AS DATE)) < 10 THEN ''0'' ELSE '''' END || ' +
    '  CAST(EXTRACT(MONTH FROM CAST(DATACRIADO AS DATE)) AS VARCHAR(2)) || ''/'' || ' +
    '  CAST(EXTRACT(YEAR  FROM CAST(DATACRIADO AS DATE)) AS VARCHAR(4))  AS DIA, ' +
    '  CASE WHEN EXTRACT(HOUR FROM HORACRIADO) < 10 THEN ''0'' ELSE '''' END || ' +
    '  CAST(EXTRACT(HOUR FROM HORACRIADO) AS VARCHAR(2)) || '':00 - '' || ' +
    '  CASE WHEN EXTRACT(HOUR FROM HORACRIADO) < 10 THEN ''0'' ELSE '''' END || ' +
    '  CAST(EXTRACT(HOUR FROM HORACRIADO) AS VARCHAR(2)) || '':59''       AS INTERVALO_HORA, ' +
    '  CODIGO AS NUMERO_PEDIDO, ' +
    '  1      AS TOTAL_PEDIDOS, ' +
    '  CAST(TOTALPEDIDO AS NUMERIC(15,2)) AS VALOR_TOTAL ' +
    'FROM PEDIDOS ' +
    'WHERE APROVADO = 1 ' +
    '  AND CLASSPEDIDO = ''Venda'' ' +
    '  AND STATUS = ''VENDA'' ' +
    '  AND EXTRACT(HOUR FROM HORACRIADO) BETWEEN 6 AND 22 ' +
    '  AND CAST(DATACRIADO AS DATE) >= :DATA_INI ' +
    '  AND CAST(DATACRIADO AS DATE) <= :DATA_FIM ' +
    'ORDER BY CAST(DATACRIADO AS DATE), EXTRACT(HOUR FROM HORACRIADO), CODIGO';

  // SQL-014 — Clientes sem Compras no Período
  SQL014 =
    'SELECT c.codigo, c.nomfant AS cliente, c.status, ' +
    '  ult.data_ultimo_pedido, ' +
    '  DATEDIFF(MONTH, ult.data_ultimo_pedido, CURRENT_DATE) AS meses, ' +
    '  DATEDIFF(DAY,   ult.data_ultimo_pedido, CURRENT_DATE) AS dias ' +
    'FROM cadastro c ' +
    'LEFT JOIN ( ' +
    '  SELECT p.codcli, MAX(p.dataemissao) AS data_ultimo_pedido ' +
    '  FROM pedidos p ' +
    '  WHERE p.tipo = ''S'' AND p.classpedido = ''Venda'' AND p.aprovado = 1 ' +
    '  GROUP BY p.codcli ' +
    ') ult ON ult.codcli = c.codigo ' +
    'WHERE c.codigo IS NOT NULL ' +
    '  AND NOT EXISTS ( ' +
    '      SELECT 1 FROM pedidos p ' +
    '      WHERE p.codcli = c.codigo ' +
    '        AND p.tipo = ''S'' AND p.classpedido = ''Venda'' AND p.aprovado = 1 ' +
    '        AND p.dataemissao >= :DATA_INI ' +
    '        AND p.dataemissao <= :DATA_FIM ' +
    '  ) ' +
    'ORDER BY ult.data_ultimo_pedido DESC';

// ---------------------------------------------------------------------------

function GetRelatorios: TArray<TRelatorioDef>;
begin
  SetLength(Result, 8);

  Result[0] := MkRel('SQL001', 'Pedidos por Cliente',
    'Total de pedidos de venda agrupado por cliente no periodo',
    SQL001,
    [MkParam('DATA_INI', 'Data Inicio', pkDate,    'MONTH_START'),
     MkParam('DATA_FIM', 'Data Fim',    pkDate,    'TODAY'),
     MkParam('CODEMP',   'Empresa',     pkInteger, '1')]);

  Result[1] := MkRel('SQL002', 'Lista de Produtos',
    'Todos os produtos com saldo e data da ultima movimentacao',
    SQL002,
    [MkParam('CODEMP', 'Empresa', pkInteger, '1')]);

  Result[2] := MkRel('SQL003', 'Financeiro por Periodo',
    'Movimentacoes financeiras liquidadas no periodo',
    SQL003,
    [MkParam('DATA_INI', 'Data Inicio', pkDate,    'MONTH_START'),
     MkParam('DATA_FIM', 'Data Fim',    pkDate,    'TODAY'),
     MkParam('CODEMP',   'Empresa',     pkInteger, '1')]);

  Result[3] := MkRel('SQL004', 'Compra Estoque (Abaixo do Minimo)',
    'Produtos abaixo do saldo minimo, agrupados por colaborador responsavel',
    SQL004,
    [MkParam('CODEMP', 'Empresa', pkInteger, '1')]);

  Result[4] := MkRel('SQL007', 'Estoque Fisico vs Disponivel',
    'Saldo fisico x saldo disponivel descontando pedidos em separacao',
    SQL007,
    [MkParam('CODEMP', 'Empresa', pkInteger, '1')]);

  Result[5] := MkRel('SQL011', 'Vendas por Horario (60 dias)',
    'Distribuicao de vendas por hora do dia nos ultimos 60 dias',
    SQL011,
    [MkParam('CODEMP', 'Empresa', pkInteger, '1')]);

  Result[6] := MkRel('SQL012B', 'Entregas CT-e por Destinatario',
    'CT-e agrupados por remetente, cidade e destinatario (transportadora)',
    SQL012B,
    [MkParam('DATA_INI', 'Data Inicio',        pkDate,    'MONTH_START'),
     MkParam('DATA_FIM', 'Data Fim',           pkDate,    'TODAY'),
     MkParam('CODEMP',   'Empresa',            pkInteger, '1'),
     MkParam('CODCLI',   'Cod. Remetente (0=todos)', pkInteger, '0'),
     MkParam('CIDADE',   'Cidade (vazio=todas)', pkString, '', True)]);

  Result[7] := MkRel('SQL013', 'Vendas por Dia e Hora',
    'Pedidos de venda detalhados por dia e intervalo de hora no periodo',
    SQL013,
    [MkParam('DATA_INI', 'Data Inicio', pkDate, 'MONTH_START'),
     MkParam('DATA_FIM', 'Data Fim',    pkDate, 'TODAY')]);
end;

end.
