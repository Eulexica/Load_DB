unit Main;
{
*********************************************************************************
*********************************************************************************
**                                                                             **
**  BM comments 15/08/2020 outlining run Parameters for when running           **
**  in silent mode                                                             **
**                                                                             **
**  Alex's existing code handles the following params                          **
**  FN (filename) DB (database) /TT (Debug string)                             **
**  I've kept the first 2 for Import Filename and Database to Refresh          **
**  I've replaced the 3rd one with SDP for Sys Db Pword                        **
**  I've added a 4th one, SOP for Schema Owner Pword                           **
**  I've added a 5th (optional) one, DCM for Db Connection Method              **
**  I've kept the original Param code in a condition ParamCount = 3            **
**  I've wrapped my Param code in a condition Paramcount > 3                   **
**                                                                             **
**  User should use the following format for adding params                     **
**  "Load_DB.exe FN[filename] DB[Schema name] SDP[Sys DB pw]                   **
**               SOP[Schema Owner pw] [blank] OR DCM[DB Connection method]"    **
**  Here's a valid user input example(assuming filename = Myfilename etc)...   **
**  "Load_DB.exe FNMyfilename DBMySchemaname SDPMysysdbpw SOPMyschemaownerpw"  **
**  The above can be pasted into command line for testing first 4 params       **
**                                                                             **
*********************************************************************************
*********************************************************************************
}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Registry, Menus,
  StdCtrls, DateUtils, ShellAPI,
  JvDialogs,
  INIFiles, ActnList, ActnMan,
  StrUtils,  XPStyleActnCtrls, System.Actions,
  Data.Bind.ObjectScope, System.IOUtils,
  Vcl.ExtCtrls, Vcl.Buttons,  System.UITypes,
  //cxButtonEdit,
  Vcl.ComCtrls, System.ImageList,
  Vcl.ImgList, Data.DB, Data.Win.ADODB;

const
   RegistryRoot = 'Software\Colateral\Axiom';
   sysPassword = 'password';
   AxiomPassword = 'regdeL99';
   loaddbPassword = 'regdeL99';

type
  TfrmMain = class(TForm)
   // OpenDialog: TJvOpenDialog;
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
    OpenDialog: TJvOpenDialog;
    Con: TADOConnection;
    qryConstraints: TADOQuery;
    qryTables: TADOQuery;
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
    DBconnexMethod: string;
    ownerPW: string;
    dbPW: string;
    bSilentMode: boolean;
    function GetOraHome: string;
    procedure ParseTnsNames;
    procedure CreateParFile(ATmpDir: string);
    procedure CreateBatchFile(ATmpDir: string);
    procedure CreateUserFile(ATmpDir: string);
    function TempDir : string;
    procedure DelFilesFromDir(sDirectory, sFileMask: string);
    function DisableConstraints : string;
    procedure PrepForImport;
    function DropTablesAndConstraints : string;

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
      if (ParamCount = 3) then
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

   bSilentMode := false;
   if (ParamCount > 3) then
   begin
      for j := 1 to ParamCount do
      begin
         if (Pos('FN', ParamStr(j)) > 0)  then
            sImportFile := Copy(ParamStr(j),3, length(ParamStr(j))-2);
         if (Pos('DB', ParamStr(j)) > 0) then
            dbName := Copy(ParamStr(j),3, length(ParamStr(j))-2);
         if (Pos('SDP', ParamStr(j)) > 0) then
            dbPW := Copy(ParamStr(j),4, length(ParamStr(j))-3);
         if (Pos('SOP', ParamStr(j)) > 0) then
            ownerPW := Copy(ParamStr(j),4, length(ParamStr(j))-3);
         if (Pos('DCM', ParamStr(j)) > 0) then
            DBconnexMethod := Copy(ParamStr(j),4, length(ParamStr(j))-3)
         else
            DBconnexMethod := 'Direct';
      end;
  //    showmessage(sImportFile +' - '+ dbName +' - '+ dbPW + ' - ' + ownerPW + ' - ' + DBconnexMethod);
      bSilentMode := true; // not the same as AutoLoad
      actStartExecute(Sender);
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
   if bSilentMode then
     Application.Terminate;    // make sure the app closes if in silent mode
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
   if bSilentMode then
     S := 'fromuser=loaddb'
   else
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
   if bSilentMode then
     begin
       S := '@echo off > NUL';
       WriteLn(F, S);
       S := 'imp loaddb/'+Trim(edSchemaPassword.Text)+'@'+cbDatabase.Text+' parfile=import.txt';
       WriteLn(F, S);
     end
   else
     begin
       S := 'sqlplus "sys/'+Trim(edSYSPassword.Text)+'@'+cbDatabase.Text+' as sysdba" @"'+
          IncludeTrailingPathDelimiter(ATmpDir)+'cr_axiom_user.sql"';
       WriteLn(F, S);
       S := 'imp axiom/'+Trim(edSchemaPassword.Text)+'@'+cbDatabase.Text+' parfile=import.txt';
       WriteLn(F, S);
     end;
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

function TfrmMain.TempDir : string;
var
  s : string;
begin
  Result := '';
  s := TPath.GetLibraryPath + '\conflicts\aaazzz';
  if CreateDir(s) then
    Result := s;
end;

procedure TfrmMain.PrepForImport;
var
  DB :  string;
begin
  exit;
  Con.ConnectionString := 'Provider=MSDAORA.1;Password=' + loaddbpassword + ';User ID=loaddb;Data Source=Insight;Persist Security Info=True';
  Con.Connected := true;
  //qryConstraints.sql.text := DisableConstraints;
  //qryConstraints.execSQL;
  qryTables.sql.text := DropTablesAndConstraints;
  qryTables.execSQL;
  Con.connected := false;

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
   if (bAutoLoad = False) and (not bSilentMode) then
      bPrompt := MessageDlg('You are about to replace the DATABASE.  This will delete all data and replace it with the import.  Continue?',
                 mtConfirmation, [mbYes, mbNo], 0);

   if (bPrompt = mrYes) then
   begin
      TmpDir := TPath.GetLibraryPath;
      if bSilentMode then
        begin
          TmpDir := TempDir;
          PrepForImport;
        end;
//      TmpDir := ExtractFileDir(edBackupDir.Text);

      ExecuteFile := '"'+IncludeTrailingPathDelimiter(TmpDir) +'import_db.bat"';
      if not bSilentMode then
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

        nShow := SW_SHOWMINIMIZED;  //  SW_SHOWNORMAL; SW_NORMAL;  //
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
            if not bSilentMode then
              ShowMessage('Import Finished.') ;
            btnCancel.Caption := 'Close';
            btnStart.Enabled := False;
         end;
      end;
      DeleteFile('import.txt');
      DeleteFile('"'+IncludeTrailingPathDelimiter(TmpDir) +'cr_axiom_user.sql"');
      DeleteFile('"'+IncludeTrailingPathDelimiter(TmpDir) +'import_db.bat"');
      if bSilentMode then
        begin
          DeleteFile(IncludeTrailingPathDelimiter(TmpDir) + 'import.txt');
          DeleteFile(IncludeTrailingPathDelimiter(TmpDir) + 'import_db.bat');
          RemoveDir(tmpDir);
        end;
      Self.Close;
   end;
end;

procedure TfrmMain.DelFilesFromDir(sDirectory, sFileMask: string);
var
  s: string;
  FOS: TSHFileOpStruct;
begin
  FillChar(FOS, SizeOf(FOS), 0);
  FOS.Wnd := Application.MainForm.Handle;
  FOS.wFunc := FO_DELETE;
  s := sDirectory + '\' + sFileMask + #0;
  FOS.pFrom := PChar(s);
 // FOS.fFlags := FOS.fFlags OR FOF_NOCONFIRMATION;
  FOS.fFlags := FOS.fFlags OR FOF_SILENT;
  SHFileOperation(FOS);
end;

procedure TfrmMain.actStartUpdate(Sender: TObject);
begin
   actStart.Enabled := (edBackupDir.Text <> '') and (cbDatabase.Text <> '') and
                       (edSYSPassword.Text <> '') and (edSchemaPassword.Text <> '') ;
end;

function TfrmMain.DisableConstraints : string;
var
  qsR, qsAxiom, qsAlterTable, qsDisableConstraint : string;
begin
  qsR := QuotedStr(' R ');
  qsAxiom := QuotedStr(' AXIOM ');
  qsAlterTable := QuotedStr(' alter table ');
  qsDisableConstraint := QuotedStr(' disable constraint ');

  Result := ' DECLARE '

  +  ' BEGIN '

 +  '  FOR iloop IN (SELECT constraint_name, table_name  '

       + '            FROM all_constraints '

    + '              WHERE constraint_type = ' + qsR + ' AND owner = ' + qsAxiom

 + '  LOOP      '

     + ' BEGIN   '

       + '  EXECUTE IMMEDIATE (  ' +  qsAlterTable

         + '                   || iloop.table_name   '

          + '                  || ' +  qsDisableConstraint

          + '                  || iloop.constraint_name    '

       + '                    );     '

    + '  EXCEPTION      '

      + '   WHEN OTHERS    '

    + '     THEN        '

   + '         NULL;     '

   + '   END;      '

  + ' END LOOP;  '

  + ' END;'

   + ' / '

  + ' Exit ';

end;

function TfrmMain.DropTablesAndConstraints : string;
var
  qsDropTable, qsCascadeConstraints : string;
begin
  qsDropTable := QuotedStr(' drop table ');
  qsCascadeConstraints := QuotedStr(' cascade constraints ');

  Result := ' begin  ' +
        ' for i in (select * from tabs) loop ' +
        ' execute immediate ('+ qsDropTable + ' || i.table_name || ' + qsCascadeConstraints + '); ' +
        ' end loop; ' +
        ' end;  ';

end;

end.

