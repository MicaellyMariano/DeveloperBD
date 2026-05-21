unit UMain;

interface

uses
  Winapi.Windows, Winapi.ShellAPI,
  System.SysUtils, System.Classes, System.IOUtils, System.DateUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ComCtrls, Vcl.Grids, Vcl.ExtCtrls,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.IBBase, FireDAC.Phys.FB,
  FireDAC.VCLUI.Wait, FireDAC.Comp.Client,
  System.Generics.Collections,
  URelatorios;

type
  TFrmMain = class(TForm)
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
  private
    // FireDAC
    FDriverLink: TFDPhysFBDriverLink;
    FConnection: TFDConnection;
    FQuery     : TFDQuery;

    // Painel de conexao
    PnlConn  : TPanel;
    LblDB    : TLabel;
    EdtDB    : TEdit;
    LblUser  : TLabel;
    EdtUser  : TEdit;
    LblPass  : TLabel;
    EdtPass  : TEdit;
    BtnConn  : TButton;
    ShpStatus: TShape;
    LblStatus: TLabel;

    // Selecao de relatorio
    PnlSel  : TPanel;
    LblRel  : TLabel;
    CbRel   : TComboBox;
    LblDesc : TLabel;

    // Parametros (scroll)
    SbParams : TScrollBox;

    // Botoes de acao
    PnlActions: TPanel;
    BtnGerar  : TButton;
    BtnHTML   : TButton;
    LblCount  : TLabel;

    // Grid de resultados
    Grid: TStringGrid;

    // Listas de controles dinamicos de parametro
    FLabelList  : TObjectList<TLabel>;
    FInputList  : TObjectList<TWinControl>; // TEdit ou TDateTimePicker
    FParamKinds : TList<TParamKind>;

    FRelatorios: TArray<TRelatorioDef>;

    procedure BuildUI;
    procedure LoadReports;

    procedure CbRelChange(Sender: TObject);
    procedure BtnConnClick(Sender: TObject);
    procedure BtnGerarClick(Sender: TObject);
    procedure BtnHTMLClick(Sender: TObject);

    procedure UpdateParamPanel(const R: TRelatorioDef);
    procedure ClearParamPanel;

    function  GetParamValueStr(Index: Integer): string;
    procedure ApplyQueryParams(const R: TRelatorioDef);

    procedure FillGrid;
    function  GenerateHTML(const R: TRelatorioDef; const ParamDesc: string): string;

    procedure SetStatus(const Msg: string; IsOK: Boolean);
    function  HtmlEnc(const S: string): string;
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.dfm}

const
  DEFAULT_DB   = 'C:\Users\ram\Documents\Bases_clientes_gerador\CEM.FDB';
  DEFAULT_USER = 'SYSDBA';
  DEFAULT_PASS = 'masterkey';
  MAX_GRID_ROWS = 2000;

// ===========================================================================
// CONSTRUTOR / DESTRUTOR
// ===========================================================================

constructor TFrmMain.Create(AOwner: TComponent);
begin
  inherited;
  FLabelList  := TObjectList<TLabel>.Create(False);   // nao gerencia Free
  FInputList  := TObjectList<TWinControl>.Create(False);
  FParamKinds := TList<TParamKind>.Create;
  BuildUI;
  LoadReports;
end;

destructor TFrmMain.Destroy;
begin
  ClearParamPanel;
  FParamKinds.Free;
  FInputList.Free;
  FLabelList.Free;
  FreeAndNil(FQuery);
  FreeAndNil(FConnection);
  FreeAndNil(FDriverLink);
  inherited;
end;

// ===========================================================================
// CONSTRUCAO DA INTERFACE
// ===========================================================================

procedure TFrmMain.BuildUI;
const
  CONN_H    = 68;
  SEL_H     = 68;
  PARAMS_H  = 110;
  ACTION_H  = 42;
begin
  Caption  := 'Relatorios CEM — Sistema RAM';
  Width    := 1060;
  Height   := 730;
  Position := poScreenCenter;
  Color    := $00F0F0F0;

  // ---- Painel de conexao -------------------------------------------------
  PnlConn        := TPanel.Create(Self);
  PnlConn.Parent := Self;
  PnlConn.Align  := alTop;
  PnlConn.Height := CONN_H;
  PnlConn.Caption:= '';
  PnlConn.BevelOuter := bvNone;
  PnlConn.Color  := $001A5276;

  LblDB         := TLabel.Create(PnlConn);
  LblDB.Parent  := PnlConn;
  LblDB.Caption := 'Banco:';
  LblDB.Left    := 10; LblDB.Top := 12;
  LblDB.Font.Color := clWhite; LblDB.Font.Style := [fsBold];

  EdtDB         := TEdit.Create(PnlConn);
  EdtDB.Parent  := PnlConn;
  EdtDB.Left    := 60; EdtDB.Top := 8; EdtDB.Width := 520;
  EdtDB.Text    := DEFAULT_DB;

  LblUser        := TLabel.Create(PnlConn);
  LblUser.Parent := PnlConn;
  LblUser.Caption:= 'Usuario:';
  LblUser.Left   := 10; LblUser.Top := 42;
  LblUser.Font.Color := clWhite; LblUser.Font.Style := [fsBold];

  EdtUser        := TEdit.Create(PnlConn);
  EdtUser.Parent := PnlConn;
  EdtUser.Left   := 65; EdtUser.Top := 38; EdtUser.Width := 120;
  EdtUser.Text   := DEFAULT_USER;

  LblPass        := TLabel.Create(PnlConn);
  LblPass.Parent := PnlConn;
  LblPass.Caption:= 'Senha:';
  LblPass.Left   := 210; LblPass.Top := 42;
  LblPass.Font.Color := clWhite; LblPass.Font.Style := [fsBold];

  EdtPass        := TEdit.Create(PnlConn);
  EdtPass.Parent := PnlConn;
  EdtPass.Left   := 255; EdtPass.Top := 38; EdtPass.Width := 120;
  EdtPass.Text   := DEFAULT_PASS;
  EdtPass.PasswordChar := '*';

  BtnConn        := TButton.Create(PnlConn);
  BtnConn.Parent := PnlConn;
  BtnConn.Left   := 600; BtnConn.Top := 10;
  BtnConn.Width  := 110; BtnConn.Height := 48;
  BtnConn.Caption:= 'Conectar';
  BtnConn.Font.Size := 10; BtnConn.Font.Style := [fsBold];
  BtnConn.OnClick:= BtnConnClick;

  ShpStatus        := TShape.Create(PnlConn);
  ShpStatus.Parent := PnlConn;
  ShpStatus.Left   := 722; ShpStatus.Top := 22;
  ShpStatus.Width  := 14; ShpStatus.Height := 14;
  ShpStatus.Shape  := stCircle;
  ShpStatus.Brush.Color := clRed;
  ShpStatus.Pen.Color   := clSilver;

  LblStatus        := TLabel.Create(PnlConn);
  LblStatus.Parent := PnlConn;
  LblStatus.Left   := 740; LblStatus.Top := 21;
  LblStatus.Caption:= 'Desconectado';
  LblStatus.Font.Color := clSilver;

  // ---- Painel de selecao de relatorio ------------------------------------
  PnlSel        := TPanel.Create(Self);
  PnlSel.Parent := Self;
  PnlSel.Align  := alTop;
  PnlSel.Height := SEL_H;
  PnlSel.Caption:= '';
  PnlSel.BevelOuter := bvNone;
  PnlSel.Color  := $00EBF5FB;

  LblRel        := TLabel.Create(PnlSel);
  LblRel.Parent := PnlSel;
  LblRel.Caption:= 'Relatorio:';
  LblRel.Left   := 10; LblRel.Top := 12;
  LblRel.Font.Style := [fsBold];

  CbRel         := TComboBox.Create(PnlSel);
  CbRel.Parent  := PnlSel;
  CbRel.Left    := 82; CbRel.Top := 8;
  CbRel.Width   := 420; CbRel.Style := csDropDownList;
  CbRel.OnChange:= CbRelChange;

  LblDesc        := TLabel.Create(PnlSel);
  LblDesc.Parent := PnlSel;
  LblDesc.Left   := 10; LblDesc.Top := 40;
  LblDesc.Width  := 900;
  LblDesc.Caption:= '';
  LblDesc.Font.Color := $005D6D7E;

  // ---- ScrollBox de parametros -------------------------------------------
  SbParams        := TScrollBox.Create(Self);
  SbParams.Parent := Self;
  SbParams.Align  := alTop;
  SbParams.Height := PARAMS_H;
  SbParams.BorderStyle := bsNone;
  SbParams.Color  := $00EBF5FB;
  SbParams.AutoScroll := True;

  // ---- Painel de acoes ---------------------------------------------------
  PnlActions        := TPanel.Create(Self);
  PnlActions.Parent := Self;
  PnlActions.Align  := alTop;
  PnlActions.Height := ACTION_H;
  PnlActions.Caption:= '';
  PnlActions.BevelOuter := bvNone;
  PnlActions.Color  := $00D5EAF5;

  BtnGerar        := TButton.Create(PnlActions);
  BtnGerar.Parent := PnlActions;
  BtnGerar.Left   := 10; BtnGerar.Top := 6;
  BtnGerar.Width  := 150; BtnGerar.Height := 30;
  BtnGerar.Caption:= 'Gerar Relatorio';
  BtnGerar.Font.Style := [fsBold];
  BtnGerar.OnClick:= BtnGerarClick;
  BtnGerar.Enabled:= False;

  BtnHTML        := TButton.Create(PnlActions);
  BtnHTML.Parent := PnlActions;
  BtnHTML.Left   := 170; BtnHTML.Top := 6;
  BtnHTML.Width  := 180; BtnHTML.Height := 30;
  BtnHTML.Caption:= 'Exportar HTML / PDF';
  BtnHTML.OnClick:= BtnHTMLClick;
  BtnHTML.Enabled:= False;

  LblCount        := TLabel.Create(PnlActions);
  LblCount.Parent := PnlActions;
  LblCount.Left   := 370; LblCount.Top := 12;
  LblCount.Caption:= '';
  LblCount.Font.Color := $00154360;

  // ---- Grid de resultados ------------------------------------------------
  Grid        := TStringGrid.Create(Self);
  Grid.Parent := Self;
  Grid.Align  := alClient;
  Grid.RowCount    := 2;
  Grid.ColCount    := 1;
  Grid.FixedRows   := 1;
  Grid.DefaultRowHeight := 20;
  Grid.Options     := Grid.Options + [goRowSizing, goColSizing, goRowSelect,
                                       goThumbTracking];
  Grid.ScrollBars  := ssBoth;
  Grid.Color       := clWhite;
  Grid.FixedColor  := $001A5276;
  Grid.Font.Size   := 9;
end;

// ===========================================================================
// CARREGA LISTA DE RELATORIOS
// ===========================================================================

procedure TFrmMain.LoadReports;
var
  R: TRelatorioDef;
begin
  FRelatorios := GetRelatorios;
  CbRel.Items.BeginUpdate;
  try
    for R in FRelatorios do
      CbRel.Items.Add(R.Name);
  finally
    CbRel.Items.EndUpdate;
  end;
  if CbRel.Items.Count > 0 then
  begin
    CbRel.ItemIndex := 0;
    CbRelChange(nil);
  end;
end;

// ===========================================================================
// PAINEL DE PARAMETROS DINAMICO
// ===========================================================================

procedure TFrmMain.ClearParamPanel;
var
  i: Integer;
begin
  for i := 0 to FInputList.Count - 1 do
    FInputList[i].Free;
  FInputList.Clear;
  for i := 0 to FLabelList.Count - 1 do
    FLabelList[i].Free;
  FLabelList.Clear;
  FParamKinds.Clear;
end;

procedure TFrmMain.UpdateParamPanel(const R: TRelatorioDef);
const
  LBL_W = 160;
  INP_W = 145;
  COL_W = LBL_W + INP_W + 20;
  ROW_H = 32;
  PAD   = 8;
var
  i, Col, Row, X, Y: Integer;
  Lbl: TLabel;
  Edt: TEdit;
  Dtp: TDateTimePicker;
begin
  ClearParamPanel;
  Col := 0; Row := 0;
  for i := 0 to High(R.Params) do
  begin
    FParamKinds.Add(R.Params[i].Kind);
    X := PAD + Col * COL_W;
    Y := PAD + Row * ROW_H;

    Lbl         := TLabel.Create(SbParams);
    Lbl.Parent  := SbParams;
    Lbl.Caption := R.Params[i].Caption + ':';
    Lbl.Left    := X;
    Lbl.Top     := Y + 5;
    Lbl.Width   := LBL_W;
    FLabelList.Add(Lbl);

    case R.Params[i].Kind of
      pkDate:
      begin
        Dtp         := TDateTimePicker.Create(SbParams);
        Dtp.Parent  := SbParams;
        Dtp.Left    := X + LBL_W;
        Dtp.Top     := Y;
        Dtp.Width   := INP_W;
        Dtp.Kind    := dtkDate;
        Dtp.Format  := 'dd/MM/yyyy';
        if R.Params[i].DefaultValue = 'MONTH_START' then
          Dtp.Date := EncodeDate(YearOf(Now), MonthOf(Now), 1)
        else
          Dtp.Date := Today;
        FInputList.Add(Dtp);
      end;
    else
      Edt         := TEdit.Create(SbParams);
      Edt.Parent  := SbParams;
      Edt.Left    := X + LBL_W;
      Edt.Top     := Y;
      Edt.Width   := INP_W;
      Edt.Text    := R.Params[i].DefaultValue;
      FInputList.Add(Edt);
    end;

    Inc(Col);
    if X + COL_W * 2 > SbParams.ClientWidth - PAD then
    begin
      Col := 0;
      Inc(Row);
    end;
  end;
end;

// ===========================================================================
// EVENTO: SELECAO DE RELATORIO
// ===========================================================================

procedure TFrmMain.CbRelChange(Sender: TObject);
begin
  if CbRel.ItemIndex < 0 then Exit;
  LblDesc.Caption := FRelatorios[CbRel.ItemIndex].Description;
  UpdateParamPanel(FRelatorios[CbRel.ItemIndex]);
  LblCount.Caption := '';
  Grid.RowCount := 2;
  Grid.ColCount := 1;
  Grid.Cells[0, 0] := '';
  BtnHTML.Enabled := False;
end;

// ===========================================================================
// CONEXAO COM O BANCO
// ===========================================================================

procedure TFrmMain.BtnConnClick(Sender: TObject);
begin
  if Assigned(FConnection) and FConnection.Connected then
  begin
    FConnection.Connected := False;
    SetStatus('Desconectado', False);
    BtnConn.Caption  := 'Conectar';
    BtnGerar.Enabled := False;
    Exit;
  end;

  FreeAndNil(FQuery);
  FreeAndNil(FConnection);
  FreeAndNil(FDriverLink);

  try
    FDriverLink := TFDPhysFBDriverLink.Create(nil);

    FConnection := TFDConnection.Create(nil);
    FConnection.DriverName := 'FB';
    FConnection.Params.Values['Server']    := 'localhost';
    FConnection.Params.Values['Database']  := EdtDB.Text;
    FConnection.Params.Values['User_Name'] := EdtUser.Text;
    FConnection.Params.Values['Password']  := EdtPass.Text;
    FConnection.Params.Values['Protocol']  := 'TCPIP';
    FConnection.Params.Values['CharacterSet'] := 'WIN1252';
    FConnection.LoginPrompt := False;
    FConnection.Connected   := True;

    FQuery            := TFDQuery.Create(nil);
    FQuery.Connection := FConnection;

    SetStatus('Conectado — ' + ExtractFileName(EdtDB.Text), True);
    BtnConn.Caption  := 'Desconectar';
    BtnGerar.Enabled := True;
  except
    on E: Exception do
    begin
      SetStatus('Erro: ' + E.Message, False);
      FreeAndNil(FQuery);
      FreeAndNil(FConnection);
      FreeAndNil(FDriverLink);
    end;
  end;
end;

procedure TFrmMain.SetStatus(const Msg: string; IsOK: Boolean);
begin
  LblStatus.Caption    := Msg;
  ShpStatus.Brush.Color:= IfThen(IsOK, clGreen, clRed);
end;

// ===========================================================================
// OBTER VALOR DO PARAMETRO (do controle dinamico)
// ===========================================================================

function TFrmMain.GetParamValueStr(Index: Integer): string;
var
  Ctrl: TWinControl;
begin
  Result := '';
  if (Index < 0) or (Index >= FInputList.Count) then Exit;
  Ctrl := FInputList[Index];
  if Ctrl is TDateTimePicker then
    Result := FormatDateTime('dd/mm/yyyy', TDateTimePicker(Ctrl).Date)
  else if Ctrl is TEdit then
    Result := TEdit(Ctrl).Text;
end;

// ===========================================================================
// APLICAR PARAMETROS NA QUERY
// ===========================================================================

procedure TFrmMain.ApplyQueryParams(const R: TRelatorioDef);
var
  i, j: Integer;
  Param: TFDParam;
  Val  : string;
begin
  // Percorre TODOS os parametros do FQuery (pode haver duplicatas de nome)
  for i := 0 to FQuery.Params.Count - 1 do
  begin
    Param := FQuery.Params[i];
    for j := 0 to High(R.Params) do
    begin
      if SameText(Param.Name, R.Params[j].ParamName) then
      begin
        Val := GetParamValueStr(j);
        case R.Params[j].Kind of
          pkDate:
            Param.AsDate := StrToDateFmt('dd/mm/yyyy', Val);
          pkInteger:
            Param.AsInteger := StrToIntDef(Val, 0);
          pkString:
            if Val = '' then
              Param.Clear
            else
              Param.AsString := Val;
        end;
        Break;
      end;
    end;
  end;
end;

// ===========================================================================
// GERAR RELATORIO (executa query + preenche grid)
// ===========================================================================

procedure TFrmMain.BtnGerarClick(Sender: TObject);
begin
  if CbRel.ItemIndex < 0 then Exit;
  if not FConnection.Connected then
  begin
    ShowMessage('Conecte ao banco primeiro.');
    Exit;
  end;
  BtnGerar.Enabled := False;
  BtnHTML.Enabled  := False;
  LblCount.Caption := 'Executando...';
  Screen.Cursor    := crHourGlass;
  try
    FQuery.Close;
    FQuery.SQL.Text := FRelatorios[CbRel.ItemIndex].SQL;
    FQuery.Prepare;
    ApplyQueryParams(FRelatorios[CbRel.ItemIndex]);
    FQuery.Open;
    FillGrid;
    LblCount.Caption := Format('%d registro(s)', [FQuery.RecordCount]);
    BtnHTML.Enabled  := True;
  except
    on E: Exception do
    begin
      LblCount.Caption := 'Erro!';
      ShowMessage('Erro ao executar query:'#13#10 + E.Message);
    end;
  end;
  Screen.Cursor    := crDefault;
  BtnGerar.Enabled := True;
end;

procedure TFrmMain.FillGrid;
var
  Col, Row: Integer;
begin
  if FQuery.IsEmpty then
  begin
    Grid.RowCount := 2;
    Grid.ColCount := 1;
    Grid.Cells[0, 0] := '(sem dados)';
    Exit;
  end;

  Grid.ColCount := FQuery.FieldCount;
  Grid.RowCount := 1;

  // Cabecalho
  for Col := 0 to FQuery.FieldCount - 1 do
  begin
    Grid.Cells[Col, 0] := UpperCase(FQuery.Fields[Col].FieldName);
    Grid.ColWidths[Col]:= 120;
  end;

  // Dados (limite MAX_GRID_ROWS para performance)
  Row := 1;
  FQuery.First;
  while not FQuery.Eof and (Row <= MAX_GRID_ROWS) do
  begin
    Grid.RowCount := Row + 1;
    for Col := 0 to FQuery.FieldCount - 1 do
      Grid.Cells[Col, Row] := FQuery.Fields[Col].AsString;
    Inc(Row);
    FQuery.Next;
  end;

  if Row > MAX_GRID_ROWS then
    LblCount.Caption := LblCount.Caption + ' (exibindo primeiros ' +
                        IntToStr(MAX_GRID_ROWS) + ' — use Exportar para ver todos)';
end;

// ===========================================================================
// EXPORTAR HTML / PDF
// ===========================================================================

procedure TFrmMain.BtnHTMLClick(Sender: TObject);
var
  R       : TRelatorioDef;
  Desc    : string;
  i       : Integer;
  HTMLText: string;
  TmpFile : string;
begin
  if CbRel.ItemIndex < 0 then Exit;
  R := FRelatorios[CbRel.ItemIndex];

  // Monta descricao dos parametros usados
  Desc := '';
  for i := 0 to High(R.Params) do
  begin
    if i > 0 then Desc := Desc + ' | ';
    Desc := Desc + R.Params[i].Caption + ': ' + GetParamValueStr(i);
  end;

  Screen.Cursor := crHourGlass;
  try
    HTMLText := GenerateHTML(R, Desc);
    TmpFile  := TPath.GetTempPath + 'relatorio_cem_' +
                FormatDateTime('yyyymmdd_hhnnss', Now) + '.html';
    TFile.WriteAllText(TmpFile, HTMLText, TEncoding.UTF8);
    ShellExecute(0, 'open', PChar(TmpFile), nil, nil, SW_SHOW);
  finally
    Screen.Cursor := crDefault;
  end;
end;

function TFrmMain.HtmlEnc(const S: string): string;
begin
  Result := S
    .Replace('&', '&amp;')
    .Replace('<', '&lt;')
    .Replace('>', '&gt;')
    .Replace('"', '&quot;');
end;

function TFrmMain.GenerateHTML(const R: TRelatorioDef; const ParamDesc: string): string;
const
  CSS =
    '* { box-sizing: border-box; }' +
    'body { font-family: ''Segoe UI'', Arial, sans-serif; margin: 0; padding: 20px; color: #2c3e50; }' +
    '.topo { border-bottom: 3px solid #1a5276; padding-bottom: 10px; margin-bottom: 14px; }' +
    '.topo h1 { margin: 0; color: #1a5276; font-size: 20px; }' +
    '.topo p  { margin: 4px 0 0; color: #5d6d7e; font-size: 13px; }' +
    '.params  { background: #eaf0fb; border-left: 4px solid #1a5276; padding: 8px 12px;' +
               'margin-bottom: 14px; font-size: 13px; color: #1a5276; }' +
    'table { width: 100%; border-collapse: collapse; font-size: 13px; }' +
    'thead th { background: #1a5276; color: #fff; padding: 8px 10px; text-align: left;' +
               '-webkit-print-color-adjust: exact; print-color-adjust: exact; }' +
    'tbody tr:nth-child(even) { background: #eaf0fb; }' +
    'tbody tr:hover { background: #d4e6f1; }' +
    'tbody td { padding: 6px 10px; border-bottom: 1px solid #d5dbdb; }' +
    '.rodape { margin-top: 18px; font-size: 11px; color: #aaa; text-align: right;' +
              'border-top: 1px solid #ddd; padding-top: 8px; }' +
    '.btn-print { display: block; margin: 16px auto; padding: 10px 30px;' +
                 'background: #1a5276; color: #fff; border: none; border-radius: 4px;' +
                 'font-size: 14px; cursor: pointer; }' +
    '@media print { .btn-print { display: none; } body { padding: 5mm; } }';

var
  SB     : TStringBuilder;
  Col, Row: Integer;
  CellVal: string;
  IsNum  : Boolean;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('<!DOCTYPE html>');
    SB.AppendLine('<html lang="pt-BR"><head>');
    SB.AppendLine('<meta charset="UTF-8">');
    SB.AppendLine('<title>Sistema RAM — ' + HtmlEnc(R.Name) + '</title>');
    SB.AppendLine('<style>' + CSS + '</style>');
    SB.AppendLine('</head><body>');

    // Cabecalho
    SB.AppendLine('<div class="topo">');
    SB.AppendLine('<h1>Sistema RAM &mdash; ' + HtmlEnc(R.Name) + '</h1>');
    SB.AppendLine('<p>' + HtmlEnc(R.Description) + '</p>');
    SB.AppendLine('</div>');

    // Parametros
    SB.AppendLine('<div class="params"><strong>Par&acirc;metros:</strong> ' +
                  HtmlEnc(ParamDesc) + '</div>');

    // Tabela
    SB.AppendLine('<table>');
    SB.Append('<thead><tr>');
    for Col := 0 to Grid.ColCount - 1 do
      SB.Append('<th>' + HtmlEnc(Grid.Cells[Col, 0]) + '</th>');
    SB.AppendLine('</tr></thead>');
    SB.AppendLine('<tbody>');

    for Row := 1 to Grid.RowCount - 1 do
    begin
      if Trim(Grid.Cells[0, Row]) = '' then Continue;
      SB.Append('<tr>');
      for Col := 0 to Grid.ColCount - 1 do
      begin
        CellVal := Grid.Cells[Col, Row];
        // Alinha a direita se o campo parece numerico
        IsNum := (Length(CellVal) > 0) and
                 ((CellVal[1] in ['0'..'9', '-']) or
                  (Pos(',', CellVal) > 0) or (Pos('.', CellVal) > 0));
        if IsNum then
          SB.Append('<td style="text-align:right">' + HtmlEnc(CellVal) + '</td>')
        else
          SB.Append('<td>' + HtmlEnc(CellVal) + '</td>');
      end;
      SB.AppendLine('</tr>');
    end;

    SB.AppendLine('</tbody></table>');

    // Rodape
    SB.AppendLine('<div class="rodape">Gerado em ' +
                  FormatDateTime('dd/mm/yyyy hh:nn:ss', Now) +
                  ' &mdash; ' + IntToStr(Grid.RowCount - 1) + ' registro(s)</div>');

    // Botao imprimir
    SB.AppendLine('<button class="btn-print" onclick="window.print()">' +
                  '&#128438; Imprimir / Salvar como PDF</button>');
    SB.AppendLine('</body></html>');
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

end.
