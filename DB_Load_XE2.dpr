program DB_Load_XE2;

uses
  Forms,
  Main in 'Main.pas' {frmMain},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  TStyleManager.TrySetStyle('Iceberg Classico');
  Application.Title := 'Database Load';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
