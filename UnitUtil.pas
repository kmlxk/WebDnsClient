unit UnitUtil;

{ ************************************************************************* }
{ ��Ԫ����: �����������Ԫ }
{ ��    ��: 1.0 }
{ �޸�����: 2005-06-16 }
{ ************************************************************************* }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ShellApi, ShlObj, ActiveX, Registry, Dialogs;

// �ַ������
function IsInt(const S: string): Boolean;
function IsFloat(const S: string): Boolean;
function IsEmail(const S: string): Boolean;
function PathWithSlash(const Path: string): string;
function PathWithoutSlash(const Path: string): string;
function FileExtWithDot(const FileExt: string): string;
function FileExtWithoutDot(const FileExt: string): string;
function AddNumberComma(Number: Int64): string;
function ExtractFileMainName(const FileName: string): string;
function ExtractUrlFilePath(const Url: string): string;
function ExtractUrlFileName(const Url: string): string;
function ValidateFileName(const FileName: string): string;
function GetSizeString(Bytes: Int64; const Postfix: string = ' KB'): string;
function GetPercentString(Position, Max: Int64;
  const Postfix: string = ' %'): string;
function RestrictStrWidth(const S: WideString; Canvas: TCanvas; Width: Integer)
  : WideString;
function RestrictFileNameWidth(const FileName: string;
  MaxBytes: Integer): string;
function LikeString(Value, Pattern: WideString;
  CaseInsensitive: Boolean): Boolean;
procedure SplitString(S: string; Delimiter: Char; List: TStrings);
function StartWith(const Source: string; const Left: string): Boolean;
function EndWith(const Source: string; const Right: string): Boolean;

// ϵͳ���
function GetComputerName: string;
function GetWinUserName: string;
function GetWindowsDir: string;
function GetWinTempDir: string;
function GetWinTempFile(const PrefixStr: string = ''): string;
function GetFullFileName(const FileName: string): string;
function GetShortFileName(const FileName: string): string;
function GetLongFileName(const FileName: string): string;
function GetSpecialFolder(FolderID: Integer): string;
function GetWorkAreaRect: TRect;
function SelectDir(ParentHWnd: HWND; const Caption: string;
  const Root: WideString; var Path: string): Boolean;
function ExecuteFile(const FileName, Params, DefaultDir: string;
  ShowCmd: Integer): HWND;
function OpenURL(const Url: string): Boolean;
function OpenEmail(const Email: string): Boolean;
procedure SetStayOnTop(Form: TCustomForm; StayOnTop: Boolean);
procedure HideAppFromTaskBar;
function CheckLangChinesePR: Boolean;
function ShutdownWindows: Boolean;

// �ļ����
function GetFileSize(const FileName: string): Int64;
function GetFileDate(const FileName: string): TDateTime;
function SetFileDate(const FileName: string; CreationTime, LastWriteTime,
  LastAccessTime: TFileTime): Boolean;
function CopyFileToFolder(FileName, BackupFolder: string): Boolean;
function AutoRenameFileName(const FullName: string): string;
function GetTempFileAtPath(const Path: string;
  const PrefixStr: string = ''): string;

// ע������
procedure SetAutoRunOnStartup(AutoRun, CurrentUser: Boolean;
  AppTitle: string = ''; AppPara: string = '');
procedure AssociateFile(const FileExt, FileKey, SoftName, FileDescription
  : string; Flush: Boolean = False);
procedure SaveAppPath(const CompanyName, SoftName, Version: string);
function ReadAppPath(const CompanyName, SoftName, Version: string;
  var Path: string): Boolean;

// ����ʱ�����
function FileTimeToLocalSystemTime(FTime: TFileTime): TSystemTime;
function LocalSystemTimeToFileTime(STime: TSystemTime): TFileTime;
function GetDatePart(DateTime: TDateTime): TDate;
function GetTimePart(DateTime: TDateTime): TTime;

// ��������
procedure BeginWait;
procedure EndWait;
function Iif(Value: Boolean; Value1, Value2: Variant): Variant;
function Min(V1, V2: Integer): Integer;
function Max(V1, V2: Integer): Integer;
procedure Swap(var V1, V2: Integer);
function RestrictRectInScr(Rect: TRect; AllVisible: Boolean): TRect;
function GetAppSubPath(const SubFolder: string = ''): string;
function MsgBox(const Msg: string;
  Flags: Integer = MB_OK + MB_ICONINFORMATION): Integer;

implementation

// -----------------------------------------------------------------------------
// ����: �ж��ַ��� S �ǲ���һ����������
// -----------------------------------------------------------------------------
function IsInt(const S: string): Boolean;
var
  E, R: Integer;
begin
  Val(S, R, E);
  Result := E = 0;
  E := R; // avoid hints
end;

// -----------------------------------------------------------------------------
// ����: �ж��ַ��� S �ǲ���һ������������
// -----------------------------------------------------------------------------
function IsFloat(const S: string): Boolean;
var
  V: Extended;
begin
  Result := TextToFloat(PChar(S), V, fvExtended);
end;

// -----------------------------------------------------------------------------
// ����: �ж��ַ��� S �ǲ���һ�� Email ��ַ
// -----------------------------------------------------------------------------
function IsEmail(const S: string): Boolean;
begin
  Result := True;
  if Pos('@', S) = 0 then
    Result := False;
  if Pos('.', S) = 0 then
    Result := False;
end;

// -----------------------------------------------------------------------------
// ����: ��ȫ·���ַ�������� "\"
// -----------------------------------------------------------------------------
function PathWithSlash(const Path: string): string;
begin
  Result := Trim(Path);
  if Length(Result) > 0 then
    Result := IncludeTrailingPathDelimiter(Result);
end;

// -----------------------------------------------------------------------------
// ����: ȥ��·���ַ�������� "\"
// -----------------------------------------------------------------------------
function PathWithoutSlash(const Path: string): string;
begin
  Result := Trim(Path);
  if Length(Result) > 0 then
    Result := ExcludeTrailingPathDelimiter(Result);
end;

// -----------------------------------------------------------------------------
// ����: ��ȫ�ļ���չ��ǰ��� "."
// -----------------------------------------------------------------------------
function FileExtWithDot(const FileExt: string): string;
begin
  Result := FileExt;
  if Length(Result) > 0 then
    if Copy(Result, 1, 1) <> '.' then
      Result := '.' + Result;
end;

// -----------------------------------------------------------------------------
// ����: ȥ���ļ���չ��ǰ��� "."
// -----------------------------------------------------------------------------
function FileExtWithoutDot(const FileExt: string): string;
begin
  Result := FileExt;
  if Length(Result) > 0 then
    if Copy(Result, 1, 1) = '.' then
      Delete(Result, 1, 1);
end;

// -----------------------------------------------------------------------------
// ����: �����ּ��Ϸָ�����
// ʾ��: 1234567 -> 1,234,567
// -----------------------------------------------------------------------------
function AddNumberComma(Number: Int64): string;
var
  Temp: Double;
begin
  Temp := Number;
  Result := Format('%.0n', [Temp]);
end;

// -----------------------------------------------------------------------------
// ����: ȡ���ļ��������ļ���
// ʾ��: "C:\test.dat" -> "test"
// -----------------------------------------------------------------------------
function ExtractFileMainName(const FileName: string): string;
var
  Ext: string;
begin
  Ext := ExtractFileExt(FileName);
  Result := ExtractFileName(FileName);
  Result := Copy(Result, 1, Length(Result) - Length(Ext));
end;

// -----------------------------------------------------------------------------
// ����: ����URL�е��ļ�·��
// ʾ��:
// ExtractUrlFileName('http://www.download.com/file.zip');
// �˵��ý����� 'http://www.download.com/'.
// -----------------------------------------------------------------------------
function ExtractUrlFilePath(const Url: string): string;
var
  I: Integer;
begin
  I := LastDelimiter('/\:', Url);
  Result := Copy(Url, 1, I);
end;

// -----------------------------------------------------------------------------
// ����: ����URL�е��ļ���
// ʾ��:
// ExtractUrlFileName('http://www.download.com/file.zip');
// �˵��ý����� 'file.zip'.
// -----------------------------------------------------------------------------
function ExtractUrlFileName(const Url: string): string;
var
  I: Integer;
begin
  I := LastDelimiter('/\:', Url);
  Result := Copy(Url, I + 1, MaxInt);
end;

// -----------------------------------------------------------------------------
// ����: ȥ���ļ����в��Ϸ����ַ�
// ʾ��: "tes*t.dat?" -> "test.dat"
// -----------------------------------------------------------------------------
function ValidateFileName(const FileName: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(FileName) do
  begin
    if not(FileName[I] in ['\', '/', ':', '*', '?', '"', '<', '>', '|']) and
      not(Ord(FileName[I]) < 32) then
      Result := Result + FileName[I];
  end;
end;

// -----------------------------------------------------------------------------
// ����: ȡ��һ�����������ֽ������ַ���
// ����:
// Bytes   - �ֽ���
// Postfix - ��λ��׺��ȱʡΪ " KB"
// -----------------------------------------------------------------------------
function GetSizeString(Bytes: Int64; const Postfix: string): string;
var
  Temp: Double;
begin
  if Bytes > 0 then
  begin
    Temp := Bytes div 1024;
    if Bytes mod 1024 <> 0 then
      Temp := Temp + 1;
  end
  else
    Temp := 0;
  Result := Format('%s%s', [Format('%.0n', [Temp]), Postfix]);
end;

// -----------------------------------------------------------------------------
// ����: ȡ��һ�����������ٷֱȵ��ַ���
// ����:
// Position, Max   - ��ǰֵ �� ���ֵ
// Postfix         - ��׺�ַ�����ȱʡΪ " %"
// -----------------------------------------------------------------------------
function GetPercentString(Position, Max: Int64; const Postfix: string): string;
begin
  if Max > 0 then
    Result := IntToStr(Trunc((Position / Max) * 100)) + Postfix
  else
    Result := '100' + Postfix;
end;

// -----------------------------------------------------------------------------
// ����: �����ַ����ĳ�������Ӧ��ʾ���
// ����:
// S       - �����̵��ַ���.
// Canvas  - �ַ������ڵ�Canvas.
// Width   - ������ؿ��
// ����:
// ����֮����ַ���
// -----------------------------------------------------------------------------
function RestrictStrWidth(const S: WideString; Canvas: TCanvas; Width: Integer)
  : WideString;
var
  Src: WideString;
begin
  Src := S;
  Result := S;
  while (Canvas.TextWidth(Result) > Width) and (Length(Result) > 0) do
  begin
    if Length(Src) > 1 then
    begin
      Delete(Src, Length(Src), 1);
      Result := Src + '...';
    end
    else
      Delete(Result, Length(Result), 1);
  end;
end;

// -----------------------------------------------------------------------------
// ����: �����ļ����ĳ�������Ӧ����ֽ�������
// ����:
// FileName - �����̵��ļ���(���԰���·��)
// MaxBytes - ����ֽ���
// ����:
// ����֮����ļ����ַ���
// -----------------------------------------------------------------------------
function RestrictFileNameWidth(const FileName: string;
  MaxBytes: Integer): string;

  function GetBytes(const S: WideString): Integer;
  var
    AnsiStr: string;
  begin
    AnsiStr := S;
    Result := Length(AnsiStr);
  end;

var
  MainName, NewMainName: WideString;
  Ext: string;
  ExtLen: Integer;
begin
  if Length(FileName) <= MaxBytes then
  begin
    Result := FileName;
  end
  else
  begin
    Ext := ExtractFileExt(FileName);
    MainName := Copy(FileName, 1, Length(FileName) - Length(Ext));
    ExtLen := Length(Ext);

    NewMainName := MainName;
    while (GetBytes(NewMainName) + ExtLen > MaxBytes) and
      (Length(NewMainName) > 0) do
    begin
      if Length(MainName) > 1 then
      begin
        Delete(MainName, Length(MainName), 1);
        NewMainName := MainName + '...';
      end
      else
        Delete(NewMainName, Length(NewMainName), 1);
    end;

    Result := NewMainName + Ext;
    if Length(Result) > MaxBytes then
      Result := Copy(Result, 1, MaxBytes);
  end;
end;

// -----------------------------------------------------------------------------
// ����������ͨ������ʽ��֧��ͨ���'*' �� '?'
// ������
// Value            - ĸ��
// Pattern          - �Ӵ�
// CaseInsensitive  - �Ƿ���Դ�Сд
// ���أ�
// True  -  ƥ��
// False -  ��ƥ��
// ʾ����
// LikeString('abcdefg', 'abc*', True);
// -----------------------------------------------------------------------------
function LikeString(Value, Pattern: WideString;
  CaseInsensitive: Boolean): Boolean;
const
  MultiWildChar = '*';
  SingleWildChar = '?';

  function MatchPattern(ValueStart, PatternStart: Integer): Boolean;
  begin
    if (Pattern[PatternStart] = MultiWildChar) and
      (Pattern[PatternStart + 1] = #0) then
      Result := True
    else if (Value[ValueStart] = #0) and (Pattern[PatternStart] <> #0) then
      Result := False
    else if (Value[ValueStart] = #0) then
      Result := True
    else
    begin
      case Pattern[PatternStart] of
        MultiWildChar:
          begin
            if MatchPattern(ValueStart, PatternStart + 1) then
              Result := True
            else
              Result := MatchPattern(ValueStart + 1, PatternStart);
          end;
        SingleWildChar:
          Result := MatchPattern(ValueStart + 1, PatternStart + 1);
      else
        begin
          if not CaseInsensitive and (Value[ValueStart] = Pattern[PatternStart])
            or CaseInsensitive and
            (UpperCase(Value[ValueStart]) = UpperCase(Pattern[PatternStart]))
          then
            Result := MatchPattern(ValueStart + 1, PatternStart + 1)
          else
            Result := False;
        end;
      end;
    end;
  end;

begin
  if Value = '' then
    Value := #0;
  if Pattern = '' then
    Pattern := #0;
  Result := MatchPattern(1, 1);
end;

// -----------------------------------------------------------------------------
// ����: �ָ��ַ���
// -----------------------------------------------------------------------------
procedure SplitString(S: string; Delimiter: Char; List: TStrings);
var
  I: Integer;
begin
  List.Clear;
  while Length(S) > 0 do
  begin
    I := Pos(Delimiter, S);
    if I > 0 then
    begin
      List.Add(Copy(S, 1, I - 1));
      Delete(S, 1, I);
    end
    else
    begin
      List.Add(S);
      Break;
    end;
  end;
end;

// -----------------------------------------------------------------------------
// ����: �ж��ַ��� Source �ǲ����� Left ��ʼ
// -----------------------------------------------------------------------------
function StartWith(const Source: string; const Left: string): Boolean;
var
  Start: string;
  Len: Integer;
begin
  Len := Length(Left);
  if (Source = '') or (Left = '') or (Length(Source) < Len) then
  begin
    Result := False;
  end
  else
  begin
    Start := Copy(Source, 1, Len);
    Result := Start = Left;
  end;
end;

// -----------------------------------------------------------------------------
// ����: �ж��ַ��� Source �ǲ����� Right ����
// -----------------------------------------------------------------------------
function EndWith(const Source: string; const Right: string): Boolean;
var
  EndStr: string;
  RightLen: Integer;
  SourceLen: Integer;
begin
  RightLen := Length(Right);
  SourceLen := Length(Source);

  if (Source = '') or (Right = '') or (SourceLen < RightLen) then
  begin
    Result := False;
  end
  else
  begin
    EndStr := Copy(Source, SourceLen - RightLen + 1, RightLen);
    Result := EndStr = Right;
  end;
end;

// -----------------------------------------------------------------------------
// ����: ȡ�ü������
// -----------------------------------------------------------------------------
function GetComputerName: string;
const
  MaxSize = 256;
var
  Buffer: array [0 .. MaxSize - 1] of Char;
  Size: Cardinal;
begin
  Size := MaxSize;
  Windows.GetComputerName(PChar(@Buffer[0]), Size);
  Result := Buffer;
end;

// -----------------------------------------------------------------------------
// ����: ȡ�õ�ǰϵͳ�û���
// -----------------------------------------------------------------------------
function GetWinUserName: string;
const
  Size = 255;
var
  Buffer: array [0 .. Size] of Char;
  Len: DWord;
begin
  Len := Size;
  GetUserName(Buffer, Len);
  Result := Buffer;
end;

// -----------------------------------------------------------------------------
// ����: ȡ�� Windows Ŀ¼
// -----------------------------------------------------------------------------
function GetWindowsDir: string;
var
  Buffer: array [0 .. MAX_PATH] of Char;
begin
  GetWindowsDirectory(Buffer, MAX_PATH);
  Result := PathWithSlash(Buffer);
end;

// -----------------------------------------------------------------------------
// ����: ȡ��ϵͳ��ʱ�ļ�Ŀ¼
// -----------------------------------------------------------------------------
function GetWinTempDir: string;
const
  Size = 1024;
var
  Buffer: array [0 .. Size] of Char;
  LongName: string;
begin
  GetTempPath(Size, Buffer);
  Result := PathWithSlash(Buffer);
  LongName := GetLongFileName(Result);
  if Length(LongName) >= Length(Result) then
    Result := LongName;
end;

// -----------------------------------------------------------------------------
// ����: ȡ��һ����ʱ�ļ���(·��Ϊϵͳ��ʱĿ¼)
// ����:
// PrefixStr - �ļ���ǰ׺��ǰ�����ַ���Ч
// -----------------------------------------------------------------------------
function GetWinTempFile(const PrefixStr: string): string;
var
  FileName: array [0 .. MAX_PATH] of Char;
  LongName: string;
begin
  Windows.GetTempFileName(PChar(GetWinTempDir), PChar(PrefixStr), 0, FileName);
  Result := FileName;
  LongName := GetLongFileName(Result);
  if Length(LongName) >= Length(Result) then
    Result := LongName;
end;

// -----------------------------------------------------------------------------
// ����: �ļ���ȫ��(����·��)
// ʾ��:
// "test.dat" -> "C:\test.dat"
// "C:\a\..\test.dat" -> "C:\test.dat"
// -----------------------------------------------------------------------------
function GetFullFileName(const FileName: string): string;
const
  Size = 1024;
var
  Buffer: array [0 .. Size] of Char;
  FileNamePtr: PChar;
  Len: DWord;
begin
  Len := Size;
  GetFullPathName(PChar(FileName), Len, Buffer, FileNamePtr);
  Result := Buffer;
end;

// -----------------------------------------------------------------------------
// ����: ���ļ��� -> ���ļ���(8.3)
// ��ע: FileName ������·����Ҳ�������ļ�����
// ʾ��:
// "C:\Program Files" -> "C:\PROGRA~1"
// -----------------------------------------------------------------------------
function GetShortFileName(const FileName: string): string;
const
  Size = 1024;
var
  Buffer: array [0 .. Size] of Char;
begin
  GetShortPathName(PChar(FileName), Buffer, Size);
  Result := Buffer;
end;

// -----------------------------------------------------------------------------
// ����: ���ļ���(8.3) -> ���ļ���
// ��ע: FileName ������·����Ҳ�������ļ�����
// ʾ��:
// "C:\PROGRA~1\COMMON~1\" -> "C:\Program Files\Common Files\"
// -----------------------------------------------------------------------------
function GetLongFileName(const FileName: string): string;
var
  Name, S: string;
  SearchRec: TSearchRec;
begin
  S := ExcludeTrailingPathDelimiter(FileName);
  if (Length(S) < 3) or (ExtractFilePath(S) = S) then
  begin
    Result := FileName;
    Exit;
  end;

  if FindFirst(S, faAnyFile, SearchRec) = 0 then
    Name := SearchRec.Name
  else
    Name := ExtractFileName(S);
  FindClose(SearchRec);

  Result := GetLongFileName(ExtractFilePath(S)) + Name;
  if Length(S) <> Length(FileName) then
    Result := Result + '\';
end;

// -----------------------------------------------------------------------------
// ����: ȡ�������ļ���·��
// ����:
// FolderID -
// CSIDL_DESKTOP
// CSIDL_PROGRAMS
// CSIDL_RECENT
// CSIDL_SENDTO
// CSIDL_STARTMENU
// CSIDL_STARTUP
// CSIDL_TEMPLATES
// CSIDL_APPDATA
// ����:
// ���ɹ������ش����б��(\)��·����
// ��ʧ�ܣ����ؿ��ַ�����
// -----------------------------------------------------------------------------
function GetSpecialFolder(FolderID: Integer): string;
var
  PidL: PItemIDList;
  Handle: THandle;
  LinkDir: string;
begin
  Result := '';
  Handle := Application.Handle;
  if Succeeded(SHGetSpecialFolderLocation(Handle, FolderID, PidL)) then
  begin
    SetLength(LinkDir, MAX_PATH);
    SHGetPathFromIDList(PidL, PChar(LinkDir));
    SetLength(LinkDir, StrLen(PChar(LinkDir)));
    Result := LinkDir + '\';
    if FolderID = CSIDL_APPDATA then
      Result := Result + 'Microsoft\Internet Explorer\Quick Launch\';
  end;
end;

// -----------------------------------------------------------------------------
// ����: ȡ�������ϳ����������������
// -----------------------------------------------------------------------------
function GetWorkAreaRect: TRect;
begin
  SystemParametersInfo(SPI_GETWORKAREA, 0, @Result, 0);
end;

// -----------------------------------------------------------------------------
// ����: ����ļ��У��ɶ�λ�ļ���
// ����:
// ParentHWnd - �����ڵľ��
// Caption    - ����Ի������ʾ����
// Root       - ��Ŀ¼
// Path       - ����û�����ѡ���Ŀ¼
// ����:
// True  - �û�����ȷ��
// False - �û�����ȡ��
// -----------------------------------------------------------------------------
function SelectDir(ParentHWnd: HWND; const Caption: string;
  const Root: WideString; var Path: string): Boolean;
const
{$WRITEABLECONST ON}
  InitPath: string = '';
{$WRITEABLECONST OFF}
var
  WindowList: Pointer;
  BrowseInfo: TBrowseInfo;
  Buffer: PChar;
  RootItemIDList, ItemIDList: PItemIDList;
  ShellMalloc: IMalloc;
  IDesktopFolder: IShellFolder;
  Eaten, Flags: LongWord;

  function BrowseCallbackProc(HWND: HWND; uMsg: UINT; lParam: Cardinal;
    lpData: Cardinal): Integer; stdcall;
  var
    R: TRect;
  begin
    if uMsg = BFFM_INITIALIZED then
    begin
      GetWindowRect(HWND, R);
      MoveWindow(HWND, (Screen.Width - (R.Right - R.Left)) div 2,
        (Screen.Height - (R.Bottom - R.Top)) div 2, R.Right - R.Left,
        R.Bottom - R.Top, True);
      Result := SendMessage(HWND, BFFM_SETSELECTION, Ord(True),
        Longint(PChar(InitPath)))
    end
    else
      Result := 1;
  end;

begin
  Result := False;
  InitPath := Path;
  FillChar(BrowseInfo, SizeOf(BrowseInfo), 0);
  if (ShGetMalloc(ShellMalloc) = S_OK) and (ShellMalloc <> nil) then
  begin
    Buffer := ShellMalloc.Alloc(MAX_PATH);
    try
      RootItemIDList := nil;
      if Root <> '' then
      begin
        SHGetDesktopFolder(IDesktopFolder);
        IDesktopFolder.ParseDisplayName(Application.Handle, nil, POleStr(Root),
          Eaten, RootItemIDList, Flags);
      end;
      with BrowseInfo do
      begin
        hwndOwner := ParentHWnd;
        pidlRoot := RootItemIDList;
        pszDisplayName := Buffer;
        lpszTitle := PChar(Caption);
        ulFlags := BIF_RETURNONLYFSDIRS;
        lpfn := @BrowseCallbackProc;
        lParam := BFFM_INITIALIZED;
      end;
      WindowList := DisableTaskWindows(0);
      try
        ItemIDList := ShBrowseForFolder(BrowseInfo);
      finally
        EnableTaskWindows(WindowList);
      end;
      Result := ItemIDList <> nil;
      if Result then
      begin
        SHGetPathFromIDList(ItemIDList, Buffer);
        ShellMalloc.Free(ItemIDList);
        Path := Buffer;
      end;
    finally
      ShellMalloc.Free(Buffer);
    end;
  end;
end;

// -----------------------------------------------------------------------------
// ����: ��ϵͳ Shell ��������һ���ļ�
// -----------------------------------------------------------------------------
function ExecuteFile(const FileName, Params, DefaultDir: string;
  ShowCmd: Integer): HWND;
begin
  Result := ShellExecute(Application.Handle, nil, PChar(FileName),
    PChar(Params), PChar(DefaultDir), ShowCmd);
end;

// -----------------------------------------------------------------------------
// ����: ��һ�� URL
// ʾ��:
// OpenURL('http://www.abc.com');
// OpenURL('www.abc.com');
// OpenURL('file:///c:\');
// -----------------------------------------------------------------------------
function OpenURL(const Url: string): Boolean;
begin
  Result := ShellExecute(Application.Handle, 'Open', PChar(Trim(Url)), '', '',
    SW_SHOW) > 32;
end;

// -----------------------------------------------------------------------------
// ����: ��һ�� Email ���Ϳͻ���
// -----------------------------------------------------------------------------
function OpenEmail(const Email: string): Boolean;
const
  SPrefix = 'mailto:';
var
  S: string;
begin
  S := Trim(Email);
  if Pos(SPrefix, S) <> 1 then
    S := SPrefix + S;

  Result := OpenURL(S);
end;

// -----------------------------------------------------------------------------
// ����: �ô��ڱ��������ϲ�
// -----------------------------------------------------------------------------
procedure SetStayOnTop(Form: TCustomForm; StayOnTop: Boolean);
begin
  if StayOnTop Then
    SetWindowPos(Form.Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE Or
      SWP_NOSIZE)
  else
    SetWindowPos(Form.Handle, HWND_NOTOPMOST, 0, 0, 0, 0,
      SWP_NOMOVE Or SWP_NOSIZE);
end;

// -----------------------------------------------------------------------------
// ����: ����Ӧ�ó������������ϵ�ѡ��ť
// -----------------------------------------------------------------------------
procedure HideAppFromTaskBar;
var
  ExtendedStyle: Integer;
begin
  ExtendedStyle := GetWindowLong(Application.Handle, GWL_EXSTYLE);
  SetWindowLong(Application.Handle, GWL_EXSTYLE, ExtendedStyle or
    WS_EX_TOOLWINDOW and not WS_EX_APPWINDOW);
end;

// -----------------------------------------------------------------------------
// ����: ��鵱ǰϵͳ�����Ƿ��������
// -----------------------------------------------------------------------------
function CheckLangChinesePR: Boolean;
const
  // LCID Consts
  LangChinesePR = (SUBLANG_CHINESE_SIMPLIFIED shl 10) or LANG_CHINESE;
begin
  Result := SysLocale.DefaultLCID = LangChinesePR;
end;

// -----------------------------------------------------------------------------
// ����: �ػ�
// -----------------------------------------------------------------------------
function ShutdownWindows: Boolean;
const
  SE_SHUTDOWN_NAME = 'SeShutdownPrivilege';
var
  hToken: THandle;
  tkp: TTokenPrivileges;
  tkpo: TTokenPrivileges;
  Zero: DWord;
begin
  Result := True;
  if Win32Platform = VER_PLATFORM_WIN32_NT then
  begin
    Zero := 0;
    if not OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES or
      TOKEN_QUERY, hToken) then
    begin
      Result := False;
      Exit;
    end;
    if not LookupPrivilegeValue(nil, SE_SHUTDOWN_NAME, tkp.Privileges[0].Luid)
    then
    begin
      Result := False;
      Exit;
    end;
    tkp.PrivilegeCount := 1;
    tkp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;

    AdjustTokenPrivileges(hToken, False, tkp, SizeOf(TTokenPrivileges),
      tkpo, Zero);
    if Boolean(GetLastError()) then
    begin
      Result := False;
      Exit;
    end
    else
      ExitWindowsEx(EWX_SHUTDOWN or EWX_POWEROFF, 0);
  end
  else
    ExitWindowsEx(EWX_SHUTDOWN or EWX_POWEROFF, 0);
end;

// -----------------------------------------------------------------------------
// ����: ȡ���ļ���С
// -----------------------------------------------------------------------------
function GetFileSize(const FileName: string): Int64;
var
  FileStream: TFileStream;
begin
  Result := -1;
  if not FileExists(FileName) then
    Exit;

  try
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      Result := FileStream.Size;
    finally
      FileStream.Free;
    end;
  except
    Result := 0;
  end;
end;

// -----------------------------------------------------------------------------
// ����: ȡ���ļ����޸�ʱ��
// -----------------------------------------------------------------------------
function GetFileDate(const FileName: string): TDateTime;
var
  FileHandle: Integer;
begin
  FileHandle := FileOpen(FileName, fmOpenWrite or fmShareDenyNone);
  try
    if FileHandle > 0 then
      Result := FileDateToDateTime(FileGetDate(FileHandle))
    else
      Result := 0;
  finally
    FileClose(FileHandle);
  end;
end;

// -----------------------------------------------------------------------------
// ����: �����ļ���ʱ��
// -----------------------------------------------------------------------------
function SetFileDate(const FileName: string; CreationTime, LastWriteTime,
  LastAccessTime: TFileTime): Boolean;
var
  FileHandle: Integer;
begin
  FileHandle := FileOpen(FileName, fmOpenWrite or fmShareDenyNone);
  try
    if FileHandle > 0 then
    begin
      SetFileTime(FileHandle, @CreationTime, @LastAccessTime, @LastWriteTime);
      Result := True;
    end
    else
      Result := False;
  finally
    FileClose(FileHandle);
  end;
end;

// -----------------------------------------------------------------------------
// ����: �����ļ���һ���ļ���
// -----------------------------------------------------------------------------
function CopyFileToFolder(FileName, BackupFolder: string): Boolean;
var
  MainFileName: string;
begin
  BackupFolder := PathWithSlash(BackupFolder);
  MainFileName := ExtractFileName(FileName);
  ForceDirectories(BackupFolder);
  Result := CopyFile(PChar(FileName),
    PChar(BackupFolder + MainFileName), False);
end;

// -----------------------------------------------------------------------------
// ����: �Զ������ļ�������ֹ�ļ����ظ�
// ����:
// FullName - �ļ���ȫ·����
// ʾ����
// NewName := AutoRenameFileName('C:\Downloads\test.dat');
// ��� "C:\Downloads\" ���Ѿ�����test.dat���������� "C:\Downloads\test(1).dat".
// -----------------------------------------------------------------------------
function AutoRenameFileName(const FullName: string): string;
const
  SLeftSym = '(';
  SRightSym = ')';

  // ��S='test(1)'���򷵻�'(1)'�� ��S='test(a)'���򷵻�''��
  function GetNumberSection(const S: string): string;
  var
    I: Integer;
  begin
    Result := '';
    if Length(S) < 3 then
      Exit;
    if S[Length(S)] = SRightSym then
    begin
      for I := Length(S) - 2 downto 1 do
        if S[I] = SLeftSym then
        begin
          Result := Copy(S, I, MaxInt);
          Break;
        end;
    end;
    if Length(Result) > 0 then
    begin
      if not IsInt(Copy(Result, 2, Length(Result) - 2)) then
        Result := '';
    end;
  end;

var
  Number: Integer;
  Name, Ext, NumSec: string;
begin
  Ext := ExtractFileExt(FullName);
  Result := FullName;
  while FileExists(Result) do
  begin
    Name := Copy(Result, 1, Length(Result) - Length(Ext));
    NumSec := GetNumberSection(Name);
    if Length(NumSec) = 0 then
    begin
      Result := Name + SLeftSym + '1' + SRightSym + Ext;
    end
    else
    begin
      Number := StrToInt(Copy(NumSec, 2, Length(NumSec) - 2));
      Inc(Number);
      Result := Copy(Name, 1, Length(Name) - Length(NumSec)) + SLeftSym +
        IntToStr(Number) + SRightSym + Ext;
    end;
  end;
end;

// -----------------------------------------------------------------------------
// ����: ȡ��һ����ʱ�ļ���
// ����:
// Path      - ��ʱ�ļ�����·��
// PrefixStr - �ļ���ǰ׺��ǰ�����ַ���Ч
// -----------------------------------------------------------------------------
function GetTempFileAtPath(const Path: string; const PrefixStr: string): string;
var
  I: Integer;
begin
  I := 1;
  while True do
  begin
    Result := PathWithSlash(Path) + Copy(PrefixStr, 1, 3) + IntToStr(I)
      + '.tmp';
    if FileExists(Result) then
      Inc(I)
    else
      Break;
  end;
end;

// -----------------------------------------------------------------------------
// ����: ����������
// ����:
// AutoRun     - �Ƿ�������
// CurrentUser - �Ƿ�ֻ�Ե�ǰ�û���Ч
// AppTitle    - Ӧ�ó���ı��⣬�� "MSN"
// AppPara     - �������������в������� "/min"
// -----------------------------------------------------------------------------
procedure SetAutoRunOnStartup(AutoRun, CurrentUser: Boolean;
  AppTitle, AppPara: string);
var
  R: TRegistry;
  Key, Value: string;
begin
  R := TRegistry.Create;
  try
    if CurrentUser then
      R.RootKey := HKEY_CURRENT_USER
    else
      R.RootKey := HKEY_LOCAL_MACHINE;
    Key := '\Software\Microsoft\Windows\CurrentVersion\Run\';

    if AppTitle = '' then
      AppTitle := Application.Title;
    Value := Application.ExeName;
    if AppPara <> '' then
      Value := Value + ' ' + AppPara;

    if R.OpenKey(Key, True) then
    begin
      if AutoRun then
        R.WriteString(AppTitle, Value)
      else
        R.DeleteValue(AppTitle);
    end;
  finally
    R.Free;
  end;
end;

// -----------------------------------------------------------------------------
// ����: �ļ�����
// ����:
// FileExt         - �ļ���չ��
// FileKey         - ���ļ����͵�Ӣ�ķ���
// SoftName        - ��������� (������ʾ����Դ���������Ҽ��˵���)
// FileDescription - �ļ����͵�����
// Flush           - �Ƿ�ˢ��Windows����
// ʾ��:
// AssociateFile('.edf', 'EDiaryFile', 'EDiary', '�����ռǱ��ļ�');
// -----------------------------------------------------------------------------
procedure AssociateFile(const FileExt, FileKey, SoftName, FileDescription
  : string; Flush: Boolean);
var
  R: TRegistry;
begin
  try // Win2000�������û�ִ�д˲������ᱨ��
    R := TRegistry.Create;
    try
      R.RootKey := HKEY_CLASSES_ROOT;
      R.OpenKey('\' + FileExt, True);
      R.WriteString('', FileKey);
      R.OpenKey('\' + FileKey, True);
      R.WriteString('', FileDescription);
      R.OpenKey('\' + FileKey + '\Shell\Open\Command', True);
      R.WriteString('', Application.ExeName + ' "%1"');
      R.OpenKey('\' + FileKey + '\Shell\Open with ' + SoftName +
        '\Command', True);
      R.WriteString('', Application.ExeName + ' "%1"');
      R.OpenKey('\' + FileKey + '\DefaultIcon', True);
      R.WriteString('', Application.ExeName + ',0');
    finally
      R.Free;
    end;
    if Flush then
      SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);
  except
  end;
end;

// -----------------------------------------------------------------------------
// ����: ��ע����м��³���·��
// -----------------------------------------------------------------------------
procedure SaveAppPath(const CompanyName, SoftName, Version: string);
const
  SPathKey = 'Path';
var
  R: TRegistry;
  Key: string;
begin
  R := TRegistry.Create;
  try
    R.RootKey := HKEY_CURRENT_USER;
    Key := '\Software\' + CompanyName + '\' + SoftName + '\' + Version + '\';
    if R.OpenKey(Key, True) then
      R.WriteString(SPathKey, ExtractFilePath(Application.ExeName));
  finally
    R.Free;
  end;
end;

// -----------------------------------------------------------------------------
// ����: ��ע����ж�ȡ����·��
// -----------------------------------------------------------------------------
function ReadAppPath(const CompanyName, SoftName, Version: string;
  var Path: string): Boolean;
const
  SPathKey = 'Path';
var
  R: TRegistry;
  Key: string;
begin
  R := TRegistry.Create;
  try
    R.RootKey := HKEY_CURRENT_USER;
    Key := '\Software\' + CompanyName + '\' + SoftName + '\' + Version + '\';
    Result := R.OpenKey(Key, False);
    if Result then
      Path := R.ReadString(SPathKey);
  finally
    R.Free;
  end;
end;

// -----------------------------------------------------------------------------
// ����: FileTime -> LocalSystemTime
// -----------------------------------------------------------------------------
function FileTimeToLocalSystemTime(FTime: TFileTime): TSystemTime;
var
  STime: TSystemTime;
begin
  FileTimeToLocalFileTime(FTime, FTime);
  FileTimeToSystemTime(FTime, STime);
  Result := STime;
end;

// -----------------------------------------------------------------------------
// ����: LocalSystemTime -> FileTime
// -----------------------------------------------------------------------------
function LocalSystemTimeToFileTime(STime: TSystemTime): TFileTime;
var
  FTime: TFileTime;
begin
  SystemTimeToFileTime(STime, FTime);
  LocalFileTimeToFileTime(FTime, FTime);
  Result := FTime;
end;

// -----------------------------------------------------------------------------
// ����: ���� TDateTime �е����ڲ���
// -----------------------------------------------------------------------------
function GetDatePart(DateTime: TDateTime): TDate;
begin
  Result := Trunc(DateTime);
end;

// -----------------------------------------------------------------------------
// ����: ���� TDateTime �е�ʱ�䲿��
// -----------------------------------------------------------------------------
function GetTimePart(DateTime: TDateTime): TTime;
begin
  Result := DateTime - Trunc(DateTime);
end;

// -----------------------------------------------------------------------------
// ����: ��ʼ�ȴ�
// -----------------------------------------------------------------------------
procedure BeginWait;
begin
  Screen.Cursor := crHourGlass;
end;

// -----------------------------------------------------------------------------
// ����: ֹͣ�ȴ�
// -----------------------------------------------------------------------------
procedure EndWait;
begin
  Screen.Cursor := crDefault;
end;

// -----------------------------------------------------------------------------
// ����: �൱��C�����е� exp ? v1 : v2
// -----------------------------------------------------------------------------
function Iif(Value: Boolean; Value1, Value2: Variant): Variant;
begin
  if Value then
    Result := Value1
  else
    Result := Value2;
end;

// -----------------------------------------------------------------------------
// ����: ȡ V1, V2 �е���Сֵ
// -----------------------------------------------------------------------------
function Min(V1, V2: Integer): Integer;
begin
  if V1 > V2 then
    Result := V2
  else
    Result := V1;
end;

// -----------------------------------------------------------------------------
// ����: ȡ V1, V2 �е����ֵ
// -----------------------------------------------------------------------------
function Max(V1, V2: Integer): Integer;
begin
  if V1 > V2 then
    Result := V1
  else
    Result := V2;
end;

// -----------------------------------------------------------------------------
// ����: ���� V1, V2
// -----------------------------------------------------------------------------
procedure Swap(var V1, V2: Integer);
var
  Temp: Integer;
begin
  Temp := V1;
  V1 := V2;
  V2 := Temp;
end;

// -----------------------------------------------------------------------------
// ����: ���ƾ�������Ҫ������Ļ��Χ
// ����:
// Rect       - �������ľ�������
// AllVisible - ���������ǲ���Ҫȫ���ɼ�
// ����:
// ������ľ������� (���߲���)
// -----------------------------------------------------------------------------
function RestrictRectInScr(Rect: TRect; AllVisible: Boolean): TRect;
const
  Space = 100;
var
  ScrRect: TRect;
  W, H: Integer;
begin
  ScrRect := Screen.WorkAreaRect;
  W := Rect.Right - Rect.Left;
  H := Rect.Bottom - Rect.Top;

  if AllVisible then
  begin
    if W > (ScrRect.Right - ScrRect.Left) then
      W := (ScrRect.Right - ScrRect.Left);
    if H > (ScrRect.Bottom - ScrRect.Top) then
      H := (ScrRect.Bottom - ScrRect.Top);
    if Rect.Right > ScrRect.Right then
      Rect.Left := ScrRect.Right - W;
    if Rect.Bottom > ScrRect.Bottom then
      Rect.Top := ScrRect.Bottom - H;
    if Rect.Left < ScrRect.Left then
      Rect.Left := ScrRect.Left;
    if Rect.Top < ScrRect.Top then
      Rect.Top := ScrRect.Top;
    Rect.Right := Rect.Left + W;
    Rect.Bottom := Rect.Top + H;
  end
  else
  begin
    if Rect.Left >= ScrRect.Right - Space then
      Rect.Left := ScrRect.Right - Space;
    if Rect.Top >= ScrRect.Bottom - Space then
      Rect.Top := ScrRect.Bottom - Space;
    if Rect.Right <= ScrRect.Left + Space then
      Rect.Left := ScrRect.Left - (Rect.Right - Rect.Left) + Space;
    if Rect.Top < ScrRect.Top then
      Rect.Top := ScrRect.Top;
    Rect.Right := Rect.Left + W;
    Rect.Bottom := Rect.Top + H;
  end;
  Result := Rect;
end;

// -----------------------------------------------------------------------------
// ����: ȡ�� Application ����·������Ŀ¼·��
// -----------------------------------------------------------------------------
function GetAppSubPath(const SubFolder: string): string;
begin
  Result := ExtractFilePath(Application.ExeName) + SubFolder;
  Result := PathWithSlash(Result);
end;

// -----------------------------------------------------------------------------
// ����: ��ʾ��Ϣ��ʾ��
// -----------------------------------------------------------------------------
function MsgBox(const Msg: string; Flags: Integer): Integer;
begin
  Result := Application.MessageBox(PChar(Msg), PChar(Application.Title), Flags);
end;

end.
