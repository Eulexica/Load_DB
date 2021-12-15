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
  Data.Bind.ObjectScope,
  Vcl.ExtCtrls, Vcl.Buttons,  System.UITypes,
  //cxButtonEdit,
  Vcl.ComCtrls, System.ImageList,
  Vcl.ImgList, Data.DB, Data.Win.ADODB, DAScript, OraScript, OraCall, DBAccess,
  Ora, OraClasses, DosCommand, MemDS, stringz;

const
   RegistryRoot = 'Software\Colateral\Axiom';
   sysPassword = 'regdeL99';
   AxiomPassword = 'regdeL99';
   loaddbPassword = 'regdeL99';

   AltsysPassword = 'axiom';
   AltAxiomPassword = 'axiom';
   AltloaddbPassword = 'axiom';

type
  TfrmMain = class(TForm)
   // OpenDialog: TJvOpenDialog;
    ActionManager1: TActionManager;
    actStart: TAction;
    btnStart: TBitBtn;
    btnCancel: TBitBtn;
    Memo1: TMemo;
    RadioGroup1: TRadioGroup;
    Label3: TLabel;
    cbDatabase: TComboBoxEx;
    Label4: TLabel;
    Label5: TLabel;
    edBackupDir: TButtonedEdit;
    ImageList1: TImageList;
    OpenDialog: TJvOpenDialog;
    OraSession: TOraSession;
    OraScript: TOraScript;
    DosCommand1: TDosCommand;
    Label6: TLabel;
    qryCheckAxiomUser: TOraQuery;
    strUserSettings: TStringz;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCancelClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure actStartUpdate(Sender: TObject);
    procedure actStartExecute(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
    procedure edBackupDirRightButtonClick(Sender: TObject);
    procedure OraScriptError(Sender: TObject; E: Exception; SQL: string;
      var Action: TErrorAction);
    procedure DosCommand1Terminated(Sender: TObject);
    procedure OraSessionError(Sender: TObject; E: EDAError; var Fail: Boolean);
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
    slParFile: TStringList;
    slBatchFile: TStringList;
    slCreateUser: TStringList;
    FImpPassword: string;

    property AImpPassword: string read FImpPassword write FImpPassword;

    function GetOraHome: string;
    procedure ParseTnsNames;
    procedure CreateBatchFile();
    procedure CreateUserFile(ATmpDir: TStringList);
    procedure EnumSubKeys(RootKey: HKEY; const Key: string);

  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses
System.IOUtils;

procedure TfrmMain.FormCreate(Sender: TObject);
var
   LRegAxiom: TRegistry;
   j: integer;
begin
   slParFile      := TStringList.Create;
   slBatchFile    := TStringList.Create;
   slCreateUser   := TStringList.Create;
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
   slParFile.Free ;
   slBatchFile.Free;
   slCreateUser.Free;

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

procedure TfrmMain.CreateUserFile(ATmpDir: TStringList);
var
  S: string;
begin
   S := 'create role axiom_update_role;';
   ATmpDir.Add(S);
   S := 'DROP USER axiom CASCADE;';
   ATmpDir.Add(S);
   S := 'CREATE USER axiom';
   S := S + ' IDENTIFIED BY ' + Trim(AImpPassword);
   S := S + ' DEFAULT TABLESPACE USERS';
   S := S + ' TEMPORARY TABLESPACE TEMP';
   S := S + ' PROFILE DEFAULT';
   S := S + ' ACCOUNT UNLOCK;';
   ATmpDir.Add(S);

   S := 'GRANT axiom_UPDATE_ROLE TO axiom WITH ADMIN OPTION;';
   ATmpDir.Add(S);
   S := 'GRANT DBA TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT CTXAPP TO AXIOM;';
   ATmpDir.Add(S);
//   S := 'ALTER USER AXIOM DEFAULT ROLE ALL;';
//   ATmpDir.Add(S);
   S := 'GRANT RESOURCE TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT CONNECT TO axiom;';
   ATmpDir.Add(S);
   S := 'ALTER USER axiom DEFAULT ROLE DBA, RESOURCE, axiom_UPDATE_ROLE;';
   ATmpDir.Add(S);

{   S := 'GRANT DROP USER TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT CREATE SYNONYM TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT ALTER USER TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT CREATE DATABASE LINK TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT CREATE SEQUENCE TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT CREATE PUBLIC SYNONYM TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT CREATE TRIGGER TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT CREATE PROCEDURE TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT CREATE ROLE TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT ANALYZE ANY TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT UNLIMITED TABLESPACE TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT CREATE TABLE TO axiom WITH ADMIN OPTION;';
   ATmpDir.Add(S);
   S := 'GRANT CREATE TYPE TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT CREATE USER TO axiom with admin option;';
   ATmpDir.Add(S);
   S := 'GRANT CREATE MATERIALIZED VIEW TO axiom WITH ADMIN OPTION;';
   ATmpDir.Add(S);
   S := 'GRANT CREATE ANY VIEW TO axiom WITH ADMIN OPTION;';
   ATmpDir.Add(S);
   S := 'GRANT DROP ANY MATERIALIZED VIEW TO AXIOM WITH ADMIN OPTION;';
   ATmpDir.Add(S);
   S := 'GRANT DROP ANY VIEW TO AXIOM WITH ADMIN OPTION;';
   ATmpDir.Add(S);
   S := 'GRANT CREATE OPERATOR TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT CREATE JOB TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT CREATE ANY CONTEXT TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT CREATE INDEXTYPE TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT BECOME USER TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT SELECT ON SYS.V_$SESSION TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT SELECT ON SYS.v_$INSTANCE TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT EXECUTE ON SYS.DBMS_ALERT TO axiom_update_role;';
   ATmpDir.Add(S);
   S := 'GRANT EXECUTE ON SYS.DBMS_RLS TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT EXECUTE ON CTSSYS.CTX_DDL TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT EXECUTE ON CTXSYS.CTX_DOC TO axiom;';
   ATmpDir.Add(S);
   S := 'GRANT CREATE SESSION TO AXIOM WITH ADMIN OPTION;';
   ATmpDir.Add(S);
   S := 'GRANT SELECT ON SYS.V_$lock TO AXIOM_update_role;';
   ATmpDir.Add(S);
   S := 'GRANT SELECT ON SYS.V_$SESSION TO AXIOM_update_role;';
   ATmpDir.Add(S);
   S := 'GRANT SELECT ON SYS.V_$process TO AXIOM_update_role;';
   ATmpDir.Add(S);
   S := 'GRANT SELECT ON SYS.V_$rollname TO AXIOM_update_role;';
   ATmpDir.Add(S);
   S := 'GRANT SELECT ON SYS.dba_objects TO AXIOM_update_role;';
   ATmpDir.Add(S);
   S := 'grant execute on UTL_SMTP to axiom;';
   ATmpDir.Add(S);
   S := 'GRANT alter any MATERIALIZED VIEW TO axiom_update_role;';
   ATmpDir.Add(S);   }
end;

procedure TfrmMain.CreateBatchFile;
var
  S: string;
  sf: string;
  UserFound: boolean;
begin
   OraSession.Disconnect;
   if bSilentMode then
   begin
//       S := '@echo off > NUL';
//       WriteLn(F, S);
//       S := 'imp axiom/'+Trim(edSchemaPassword.Text)+'@'+cbDatabase.Text+' parfile=import.txt';
//       WriteLn(F, S);
   end
   else
   begin
      try
         case RadioGroup1.ItemIndex of
            0: begin
                  OraSession.Options.Direct := False;
                  OraSession.Server      := cbDatabase.Text;
            end;
            1: begin
                  OraSession.Options.Direct := True;
                  OraSession.Server := FINIstartup.ReadString('Option' + IntToStr(cbDatabase.ItemIndex + 1), 'ServerName', '');;
            end;
         end;

         OraSession.Username    := 'sys';
         OraSession.Password    := AltsysPassword;   //sysPassword;
         OraSession.ConnectMode := cmSysDBA;
         AImpPassword := AltsysPassword;
         try
          OraSession.Connect;
         except
            OraSession.Username    := 'sys';
            OraSession.Password    := sysPassword;   //sysPassword;
            OraSession.ConnectMode := cmSysDBA;
            AImpPassword := sysPassword;
            OraSession.Connect;
         end;

         if OraSession.Connected then
         begin
            try
               CreateUserFile(slCreateUser);
               qryCheckAxiomUser.Open;
               UserFound := not qryCheckAxiomUser.eof;
               qryCheckAxiomUser.Close;

               if UserFound = True then
                  MessageDlg('Axiom user is connected to datbase. Database import cannot continue.', mtInformation, [mbOk], 0)
               else
               begin
                  btnCancel.Enabled := False;
                  btnStart.Enabled := False;
                  Label6.Caption := 'Creating user....';
                  Application.ProcessMessages;
//                  try
                     OraScript.SQL.AddStrings(slCreateUser);
                     OraScript.Execute;

                     OraScript.SQL.Clear;
                     OraScript.SQL.SetStrings(strUserSettings.Strings);
                     OraScript.Execute;
//                  finally
//
//                  end;
               end;
            finally
               OraSession.Disconnect;
            end;
         end;

      finally
         if UserFound = False then
         begin
            Label6.Caption := 'User Created.';

            S := '';
            S := 'imp axiom/'+Trim(AImpPassword)+'@'+cbDatabase.Text;
            S := S + ' BUFFER=1024000';
            S := S + ' FILE='+ edBackupDir.Text;
            S := S + ' FULL=N';
            S := S + ' fromuser=axiom';
            S := S + ' GRANTS=Y';
            S := S + ' IGNORE=Y';

//         S := 'imp axiom/'+Trim(edSchemaPassword.Text)+'@'+cbDatabase.Text+' parfile=import.txt';
            Label6.Caption := 'Import Started...';
//            Application.ProcessMessages;
            DosCommand1.CommandLine := S;
            DosCommand1.Execute;
         end;
      end;

     end;
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
      EnumSubKeys(HKEY_LOCAL_MACHINE, 'Software\Oracle');

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

procedure TfrmMain.OraScriptError(Sender: TObject; E: Exception; SQL: string;
  var Action: TErrorAction);
begin
   Action := eaContinue;
   Application.ProcessMessages;
end;

procedure TfrmMain.OraSessionError(Sender: TObject; E: EDAError;
  var Fail: Boolean);
begin
   case E.ErrorCode of
      12154:  begin
               raise EDAError.Create(12154,'Cannot connect to database.  Check TNSnames is set up correctly.');
      end;
//      1921: begin
//               Fail := False;
//               raise EDAError.Create(1921, 'Role already exists.');
//      end;
      4042: begin
               Fail := false;
//               raise EDAError.Create(4042, e.Message);
      end
   else
      ShowMessage('Oracle Error:'#13#10 + e.Message);
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
   bPrompt: integer;
begin
   bPrompt := mrYes;
   if (bAutoLoad = False) and (not bSilentMode) then
      bPrompt := MessageDlg('You are about to replace the DATABASE.  This will delete all data and replace it with the import.  Continue?',
                 mtConfirmation, [mbYes, mbNo], 0);

   slCreateUser.Clear;
   if (bPrompt = mrYes) then
   begin
      if bSilentMode then
      begin
//         PrepForImport;
      end;
//      TmpDir := ExtractFileDir(edBackupDir.Text);

//      ExecuteFile := '"'+IncludeTrailingPathDelimiter(TmpDir) +'import_db.bat"';
//      if not bSilentMode then

      CreateBatchFile();
   end;
end;

procedure TfrmMain.actStartUpdate(Sender: TObject);
begin
   actStart.Enabled := (edBackupDir.Text <> '') and (cbDatabase.Text <> '');
end;

procedure TfrmMain.DosCommand1Terminated(Sender: TObject);
begin
   Label6.Caption := 'Import Complete';
//   MessageDlg('Import complete', mtInformation, [mbOK], 0);
   btnCancel.Caption := 'Close';
   btnCancel.Enabled := True;
end;

procedure TfrmMain.EnumSubKeys(RootKey: HKEY; const Key: string);
var
   Registry: TRegistry;
   SubKeyNames: TStringList;
   Name: string;
begin
   Registry := TRegistry.Create;
   Try
      Registry.RootKey := RootKey;
      Registry.OpenKeyReadOnly(Key);
      SubKeyNames := TStringList.Create;
      Try
         Registry.GetKeyNames(SubKeyNames);
         for Name in SubKeyNames do
         begin
            if Name = 'TNS_NAMES' then
               Writeln(Name);
         end;
      Finally
         SubKeyNames.Free;
      End;
   Finally
      Registry.Free;
   End;
end;

end.

