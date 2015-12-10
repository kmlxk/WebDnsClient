unit UnitPublic;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Forms, IniFiles, Registry,
  VCLUnZip;

procedure InitializeApplication(app: TApplication);
procedure setAutoRun(app: TApplication; key: string; enabled: Boolean;
  parameter: String)overload;
procedure setAutoRun(app: TApplication; key: string; enabled: Boolean)overload;
function isAutoRun(app: TApplication; key: string): Boolean;
// 得到计算机名称
function fnGetComputerName(): String;
function getFileNameFromURL(url: string): string;
function UnZipDir(sFile, sDir: string): Boolean;

var
  gSysDir: String;
  gAppName: String;
  gServerUrl: String;

implementation

// -----------------------------------------------------------------
// 得到计算机名称
// add by jzh 2002-04-15
// -----------------------------------------------------------------
function fnGetComputerName(): String;
var
  szComputerName: array [0 .. 255] of char;
  nSize: Cardinal;
begin
  nSize := 256;
  FillChar(szComputerName, sizeof(szComputerName), 0);
  GetComputerName(szComputerName, nSize);
  if StrPas(szComputerName) = '' then
    Result := ''
  else
    Result := StrPas(szComputerName);
end;

procedure InitializeApplication(app: TApplication);
var
  MyIniFile: TIniFile;
begin
  gSysDir := ExtractFilePath(app.ExeName);;
  MyIniFile := TIniFile.Create(gSysDir + 'config.ini');
  try
    with MyIniFile do
    begin
      gAppName := ReadString('Config', 'AppName', 'WebDNS');
    end;
  finally
    MyIniFile.Free;
  end;
end;

procedure setAutoRun(app: TApplication; key: string; enabled: Boolean);
begin
  setAutoRun(app, key, enabled, '');
end;

procedure setAutoRun(app: TApplication; key: string; enabled: Boolean;
  parameter: String);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_LOCAL_MACHINE;
  Reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Run', true);
  if length(key) = 0 then
    key := ExtractFileName(app.ExeName);
  if enabled then
  begin
    Reg.WriteString(key, '"' + app.ExeName + '" ' + parameter);
  end
  else
  begin
    Reg.DeleteValue(key);
  end;
  Reg.CloseKey;
end;

function isAutoRun(app: TApplication; key: string): Boolean;
var
  Reg: TRegistry;
  enabled: Boolean;
  value: String;
begin
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_LOCAL_MACHINE;
  Reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Run', true);
  if length(key) = 0 then
    key := ExtractFileName(app.ExeName);
  value := Reg.ReadString(key);
  enabled := (Length(value) > 0);
  Reg.CloseKey;
  Result := enabled;
end;

function getFileNameFromURL(url: string): string;
var
  ts: TStrings;
begin
  // 从url取得文件名
  ts := TStringList.Create;
  try
    ts.Delimiter := '/';
    ts.DelimitedText := url;
    if ts.Count > 0 then
      Result := ts[ts.Count - 1];
  finally
    ts.Free;
  end;
end;

function UnZipDir(sFile, sDir: string): Boolean;
var
  unzip: TVCLUnZip;
begin
  Result := true;
  unzip := TVCLUnZip.Create(nil);
  with unzip do
  begin
    ZipName := sFile;
    ReadZip;
    Destdir := sDir;
    RecreateDirs := true;
    FilesList.Add('*.*');
    DoAll := true;
    OverwriteMode := Always;
  end;
  try
    unzip.unzip;
  except
    Result := False;
  end;
  unzip.Free;
end;

end.
