program Load_DB;

uses
  Forms,
  Main in 'Main.pas' {frmMain},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  TStyleManager.TrySetStyle('Glossy');
  Application.Title := 'Database Load';
  if paramcount > 3 then begin
    Application.ShowMainForm:=false;
    Application.MainFormOnTaskbar := true;
  end;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
