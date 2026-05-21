program RelatoriosCEM;

uses
  Vcl.Forms,
  UMain      in 'UMain.pas'      {FrmMain},
  URelatorios in 'URelatorios.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Relatorios CEM - Sistema RAM';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
