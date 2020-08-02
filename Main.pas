unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Registry, Menus,
  StdCtrls, DateUtils, ShellAPI,
  JvDialogs, INIFiles, ActnList, ActnMan,
  StrUtils,  XPStyleActnCtrls, System.Actions,
  Data.Bind.ObjectScope, System.IOUtils,
  Vcl.ExtCtrls, Vcl.Buttons, cxButtonEdit, Vcl.ComCtrls, System.ImageList,
  Vcl.ImgList;

const
   RegistryRoot = 'Software\Colateral\Axiom';
   sysPassword = 'password';
   AxiomPassword = 'regdeL99';

type
  TfrmMain = class(TForm)
    OpenDialog: TJvOpenDialog;
    ActionManager1: TActionManager;
    actStart: TAction;
    btnStart: TBitBtn;
    btnCancel: TBitBtn;
    Memo1: TMemo;
    RadioGroup1: TRadioGroup;
    edSYSPassword: TEdit;
    edSchemaPassword: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    cbDatabase: TComboBoxEx;
    Label4: TLabel;
    Label5: TLabel;
    edBackupDir: TButtonedEdit;
    ImageList1: TImageList;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCancelClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure actStartUpdate(Sender: TObject);
    procedure actStartExecute(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
    procedure edBackupDirRightButtonClick(Sender: TObject);
  private
    { Private declarations }
    FINIstartup: TINIFile;
    FOptionsNET: boolean;
    bAutoLoad: boolean;
    sImportFile: string;
    dbName: string;
    Debug: string;
    function GetOraHome: string;
    procedure ParseTnsNames;
    procedure CreateParFile(ATmpDir: string);
    procedure CreateBatchFile(ATmpDir: string);
    procedure CreateUserFile(ATmpDir: string);
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
var
   LRegAxiom: TRegistry;
   j: integer;
begin
   bAutoLoad := False;
   if (ParamCount > 2) then
   begin
      for j := 1 to ParamCount do
      begin
         if (Pos('/FN', ParamStr(j)) > 0)  then
            sImportFile := Copy(ParamStr(j),4, length(ParamStr(j))-3);
         if (Pos('/DB', ParamStr(j)) > 0) then
            dbName := Copy(ParamStr(j),4, length(ParamStr(j))-3);
         if (Pos('/TT', ParamStr(j)) > 0) then
            Debug := Copy(ParamStr(j),4, length(ParamStr(j))-3);
      end;
      edBackupDir.Text := sImportFile;
      cbDatabase.Text := dbName;
      bAutoLoad := True;
   end;

   if bAutoLoad = False then
   begin
      LRegAxiom := TRegistry.Create;
      try
         LRegAxiom.RootKey := HKEY_CURRENT_USER;
         LRegAxiom.OpenKey(RegistryRoot, True);

         edBackupDir.Text := LRegAxiom.ReadString('Import_Dir');
      finally
        LRegAxiom.Free;
      end;
   end;
   btnCancel.Caption := 'Cancel';
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
var
   LRegAxiom: TRegistry;
begin
   if bAutoLoad = False then
   begin
      LRegAxiom := TRegistry.Create;
      try
         LRegAxiom.RootKey := HKEY_CURRENT_USER;
         LRegAxiom.Access := KEY_SET_VALUE;
         LRegAxiom.OpenKey(RegistryRoot, True);

         LRegAxiom.WriteString('Import_Dir',  edBackupDir.Text);
         LRegAxiom.CloseKey;
      finally
         LRegAxiom.free;
      end;
   end;
end;

procedure TfrmMain.CreateParFile(ATmpDir: string);
var
  F: TextFile;
  S: string;
  sf: string;
//  FileHandle: integer;
//  FileName: string;
begin
   DeleteFile(IncludeTrailingPathDelimiter(ATmpDir) +'import.txt');
   sf := IncludeTrailingPathDelimiter(ATmpDir) +'import.txt';
   AssignFile(F, sf);
   if not (FileExists(sf)) then
      Rewrite(F)
   else
   begin
      Reset(F);
   end;
   S := 'BUFFER=1024000';
   WriteLn(F, S);
   S := 'FILE='+ edBackupDir.Text;
   WriteLn(F, S);
   S := 'FULL=N';
   WriteLn(F, S);
   S := 'fromuser=axiom';
   WriteLn(F, S);
   S := 'GRANTS=y';
   WriteLn(F, S);
   S := 'IGNORE=y';
   WriteLn(F, S);
//    S := 'COMPRESS=y';
//    WriteLn(F, S);
   CloseFile(F);
end;

procedure TfrmMain.CreateUserFile(ATmpDir: string);
var
  F: TextFile;
  S: string;
  sf: string;
//  FileHandle: integer;
//  FileName: string;
begin
   DeleteFile(IncludeTrailingPathDelimiter(ATmpDir) +'cr_axiom_user.sql');
   sf := IncludeTrailingPathDelimiter(ATmpDir) +'cr_axiom_user.sql';
   AssignFile(F, sf);
   if not (FileExists(sf)) then
      Rewrite(F)
   else
   begin
      Reset(F);
   end;
//   S := 'drop role axiom_update_role;';
//   WriteLn(F, S);
   S := 'create role axiom_update_role;';
   WriteLn(F, S);
   S := 'DROP USER axiom CASCADE;';
   WriteLn(F, S);
   S := 'CREATE USER axiom';
   WriteLn(F, S);
   S := 'IDENTIFIED BY ' + Trim(edSchemaPassword.Text);
   WriteLn(F, S);
   S := 'DEFAULT TABLESPACE USERS';
   WriteLn(F, S);
   S := 'TEMPORARY TABLESPACE TEMP';
   WriteLn(F, S);
   S := 'PROFILE DEFAULT';
   WriteLn(F, S);
   S := 'ACCOUNT UNLOCK;';
   WriteLn(F, S);
   S := 'GRANT axiom_UPDATE_ROLE TO axiom WITH ADMIN OPTION;';
   WriteLn(F, S);
   S := 'GRANT DBA TO axiom;';
   WriteLn(F, S);
   S := 'GRANT CTXAPP TO AXIOM;';
   WriteLn(F, S);
   S := 'ALTER USER AXIOM DEFAULT ROLE ALL;';
   WriteLn(F, S);
   S := 'GRANT RESOURCE TO axiom;';
   WriteLn(F, S);
   S := 'GRANT CONNECT TO axiom;';
   WriteLn(F, S);
   S := 'ALTER USER axiom DEFAULT ROLE DBA, RESOURCE, axiom_UPDATE_ROLE;';
   WriteLn(F, S);
   S := 'GRANT DROP USER TO axiom;';
   WriteLn(F, S);
   S := 'GRANT CREATE SYNONYM TO axiom;';
   WriteLn(F, S);
   S := 'GRANT ALTER USER TO axiom;';
   WriteLn(F, S);
   S := 'GRANT CREATE DATABASE LINK TO axiom;';
   WriteLn(F, S);
   S := 'GRANT CREATE SEQUENCE TO axiom;';
   WriteLn(F, S);
   S := 'GRANT CREATE PUBLIC SYNONYM TO axiom;';
   WriteLn(F, S);
   S := 'GRANT CREATE TRIGGER TO axiom;';
   WriteLn(F, S);
   S := 'GRANT CREATE PROCEDURE TO axiom;';
   WriteLn(F, S);
   S := 'GRANT CREATE ROLE TO axiom;';
   WriteLn(F, S);
   S := 'GRANT ANALYZE ANY TO axiom;';
   WriteLn(F, S);
   S := 'GRANT UNLIMITED TABLESPACE TO axiom;';
   WriteLn(F, S);
   S := 'GRANT CREATE TABLE TO axiom WITH ADMIN OPTION;';
   WriteLn(F, S);
   S := 'GRANT CREATE TYPE TO axiom;';
   WriteLn(F, S);
   S := 'GRANT CREATE USER TO axiom;';
   WriteLn(F, S);
   S := 'GRANT CREATE MATERIALIZED VIEW TO axiom WITH ADMIN OPTION;';
   WriteLn(F, S);
   S := 'GRANT CREATE VIEW TO axiom WITH ADMIN OPTION;';
   WriteLn(F, S);
   S := 'GRANT DROP ANY MATERIALIZED VIEW TO AXIOM WITH ADMIN OPTION;';
   WriteLn(F, S);
   S := 'GRANT DROP ANY VIEW TO AXIOM WITH ADMIN OPTION;';
   WriteLn(F, S);
   S := 'GRANT CREATE OPERATOR TO axiom;';
   WriteLn(F, S);
   S := 'GRANT CREATE JOB TO axiom;';
   WriteLn(F, S);
   S := 'GRANT CREATE ANY CONTEXT TO axiom;';
   WriteLn(F, S);
   S := 'GRANT CREATE INDEXTYPE TO axiom;';
   WriteLn(F, S);
   S := 'GRANT BECOME USER TO axiom;';
   WriteLn(F, S);
   S := 'GRANT SELECT ON SYS.V_$SESSION TO axiom;';
   WriteLn(F, S);
   S := 'GRANT SELECT ON SYS.v_$INSTANCE TO axiom;';
   WriteLn(F, S);
   S := 'GRANT EXECUTE ON SYS.DBMS_ALERT TO axiom_update_role;';
   WriteLn(F, S);
   S := 'GRANT EXECUTE ON SYS.DBMS_RLS TO axiom;';
   WriteLn(F, S);
   S := 'GRANT EXECUTE ON CTSSYS.CTX_DDL TO axiom;';
   WriteLn(F, S);
   S := 'GRANT EXECUTE ON CTXSYS.CTX_DOC TO axiom;';
   WriteLn(F, S);
   S := 'GRANT CREATE SESSION TO AXIOM WITH ADMIN OPTION;';
   WriteLn(F, S);
   S := 'GRANT SELECT ON SYS.V_$lock TO AXIOM_update_role;';
   WriteLn(F, S);
   S := 'GRANT SELECT ON SYS.V_$SESSION TO AXIOM_update_role;';
   WriteLn(F, S);
   S := 'GRANT SELECT ON SYS.V_$process TO AXIOM_update_role;';
   WriteLn(F, S);
   S := 'GRANT SELECT ON SYS.V_$rollname TO AXIOM_update_role;';
   WriteLn(F, S);
   S := 'GRANT SELECT ON SYS.dba_objects TO AXIOM_update_role;';
   WriteLn(F, S);
   S := 'grant execute on UTL_SMTP to axiom;';
   WriteLn(F, S);
   S := 'EXIT;';
   WriteLn(F, S);

   CloseFile(F);
end;

procedure TfrmMain.CreateBatchFile(ATmpDir: string);
var
  F: TextFile;
  S: string;
  sf: string;
//  FileHandle: integer;
begin
   DeleteFile(IncludeTrailingPathDelimiter(ATmpDir) +'import_db.bat');
   sf := IncludeTrailingPathDelimiter(ATmpDir) +'import_db.bat';

   AssignFile(F, sf);
   if not (FileExists(sf)) then
      Rewrite(F)
   else
   begin
      Reset(F);
   end;
   S := 'sqlplus "sys/'+Trim(edSYSPassword.Text)+'@'+cbDatabase.Text+' as sysdba" @"'+
         IncludeTrailingPathDelimiter(ATmpDir)+'cr_axiom_user.sql"';
   WriteLn(F, S);
   S := 'imp axiom/'+Trim(edSchemaPassword.Text)+'@'+cbDatabase.Text+' parfile=import.txt';
   WriteLn(F, S);
   S := 'exit';
   WriteLn(F, S);
   CloseFile(F);
end;

procedure TfrmMain.btnCancelClick(Sender: TObject);
begin
   Close;
end;

procedure TfrmMain.edBackupDirRightButtonClick(Sender: TObject);
begin
   if OpenDialog.Execute then
   begin
      edBackupDir.Text := OpenDialog.FileName;
   end;
end;

function TfrmMain.GetOraHome: string;
var
   strOracleHome, strLastHome: string;
//   TNSNAMESORAFilePath: string;
   Reg: TRegistry;
begin
   Reg := TRegistry.Create(KEY_READ or KEY_WOW64_64KEY);
   Reg.RootKey := HKEY_LOCAL_MACHINE;
   try
      if Reg.OpenKeyReadOnly('SOFTWARE\ORACLE\ALL_HOMES\') then
      begin
         //Get last_home
         strLastHome := Reg.ReadString('SOFTWARE\ORACLE\ALL_HOMES\LAST_HOME');
         if strLastHome <> '' then
         begin
            Reg.OpenKeyReadOnly('SOFTWARE\ORACLE\HOME\' + strLastHome);
            strOracleHome := Reg.ReadString('SOFTWARE\ORACLE\HOME\ORACLE_HOME');
         end;
      end;
      if strLastHome = '' then
      begin
         if Reg.OpenKeyReadOnly('SOFTWARE\ORACLE\KEY_OraDb10g_home1\') then
              strOracleHome := Reg.ReadString('SOFTWARE\ORACLE\KEY_OraDb10g_home1\ORACLE_HOME');
//            Reg.GetKeyNames();
      end;
      if strOracleHome = '' then
      begin
         if Reg.OpenKeyReadOnly('SOFTWARE\ORACLE\KEY_Home1\') then
              strOracleHome := Reg.ReadString('SOFTWARE\ORACLE\KEY_Home1\ORACLE_HOME');
      end;
      if strOracleHome = '' then
      begin
         if Reg.OpenKeyReadOnly('SOFTWARE\ORACLE\KEY_XE\') then
              strOracleHome := Reg.ReadString('SOFTWARE\ORACLE\KEY_XE\ORACLE_HOME');
      end;
      if strOracleHome = '' then
      begin
         if (Reg.OpenKeyReadOnly('SOFTWARE\ORACLE\KEY_OraDb11g_home1\') = True) then
              strOracleHome := Reg.ReadString('ORACLE_HOME');
      end;
      Result := strOracleHome;
   finally
      Reg.CloseKey;
      Reg.Free;
   end;
end;

procedure TfrmMain.ParseTnsNames;
var
   TNSPath, s: string;
   TNSList: TStringList;
   index: integer;
begin
   TNSPath := GetOraHome + '\NETWORK\ADMIN\TNSNAMES.ORA';
   TNSList := TStringList.Create;
   try
      TNSList.LoadFromFile(TNSPath);
      // remove anything except the server name lines
      for index := Pred(TNSList.Count) downto 0 do
         if (Pos('(', TNSList.Strings[index]) > 0 ) or (Pos(')', TNSList.Strings[index]) > 0 ) or
            (Trim(TNSList.Strings[index]) = '') or (Pos('#', TNSList.Strings[index]) > 0 )then
            TNSList.Delete(index);
         // Show only the server names in the combo.
         for index := 0 to Pred(TNSList.Count) do
         begin
            s:= Copy(TNSList.Strings[Index],1, length(trim(TNSList.Strings[Index]))-1);
            if (Pos('CONNECTION',s) = 0) then
               cbDatabase.Items.Add(Trim(s));
         end;
   finally
      TNSList.Free;
   end;
end;

procedure TfrmMain.RadioGroup1Click(Sender: TObject);
var
   LOptions, i: integer;
   LTmp: string;
begin
   cbDatabase.Text := '';
   Case TRadioGroup(Sender).ItemIndex of
      0: begin
            FOptionsNET := False;
            cbDatabase.Items.Clear;
            ParseTnsNames;
         end;
      1: begin
            FOptionsNET := True;
            FINIstartup := TINIFile.Create(ExtractFilePath(Application.EXEName) + 'Axiom.INI');
            LOptions := StrToInt(FINIstartup.ReadString('Main', 'Options', '0'));

            cbDatabase.Items.Clear;
            for i := 1 to LOptions do
            begin
               LTmp := FINIstartup.ReadString('Option' + IntToStr(i), 'Name', '');
               if LTmp <> '' then
                 cbDatabase.Items.Add(LTmp);
            end;
         end;
   end;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
   RadioGroup1.ItemIndex := 1;
   if (bAutoLoad = True) then
      Self.WindowState := wsMinimized;
end;

procedure TfrmMain.actStartExecute(Sender: TObject);
var
//   FileName: string;
//   LRet: integer;
   SEInfo: TShellExecuteInfo;
   ExitCode: DWORD;
   ExecuteFile{, ParamString, StartInString}: string;
   TmpDir: string;
   bPrompt: integer;
begin
   bPrompt := mrYes;
   if (bAutoLoad = False) then
      bPrompt := MessageDlg('You are about to replace the DATABASE.  This will delete all data and replace it with the import.  Continue?',
                 mtConfirmation, [mbYes, mbNo], 0);

   if (bPrompt = mrYes) then
   begin
      TmpDir := TPath.GetLibraryPath;
//      TmpDir := ExtractFileDir(edBackupDir.Text);

      ExecuteFile := '"'+IncludeTrailingPathDelimiter(TmpDir) +'import_db.bat"';
      CreateUserFile(TmpDir);
      CreateParFile(TmpDir);
      CreateBatchFile(TmpDir);
   //   LRet :=  ShellExecute(Application.MainForm.Handle, nil,
   //            PChar(FileName), PChar(''), PChar(edBackupDir.Text), SW_ShowNormal);

      FillChar(SEInfo, SizeOf(SEInfo), 0) ;
      SEInfo.cbSize := SizeOf(TShellExecuteInfo) ;
      with SEInfo do begin
        fMask := SEE_MASK_NOCLOSEPROCESS;
        Wnd := Application.Handle;
        lpFile := PWideChar(ExecuteFile);
        lpDirectory := PWideChar(ExtractFileDir(edBackupDir.Text));

        nShow := SW_NORMAL;  //SW_SHOWMINIMIZED;  //  SW_SHOWNORMAL;
      end;
      if ShellExecuteEx(@SEInfo) then
      begin
        repeat
          Application.ProcessMessages;
          GetExitCodeProcess(SEInfo.hProcess, ExitCode) ;
        until (ExitCode <> STILL_ACTIVE) or
         Application.Terminated;
         if bAutoLoad = False then
         begin
            ShowMessage('Import Finished.') ;
            btnCancel.Caption := 'Close';
            btnStart.Enabled := False;
         end;
      end;
      DeleteFile('import.txt');
      DeleteFile('"'+IncludeTrailingPathDelimiter(TmpDir) +'cr_axiom_user.sql"');
      DeleteFile('"'+IncludeTrailingPathDelimiter(TmpDir) +'import_db.bat"');
      Self.Close;
   end;
end;

procedure TfrmMain.actStartUpdate(Sender: TObject);
begin
   actStart.Enabled := (edBackupDir.Text <> '') and (cbDatabase.Text <> '') and
                       (edSYSPassword.Text <> '') and (edSchemaPassword.Text <> '') ;
end;

end.
