unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, inifiles, UnitPublic, Shellapi, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.ExtCtrls, UnitAbout, UnitUtil,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  UnitIdHttpThread,
  Vcl.StdCtrls, IdAntiFreezeBase, Vcl.IdAntiFreeze, Vcl.Imaging.pngimage;

type
  TForm1 = class(TForm)
    TrayIcon1: TTrayIcon;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    mmExit: TMenuItem;
    mmShowHide: TMenuItem;
    mmAbout: TMenuItem;
    mmOption: TMenuItem;
    Timer1: TTimer;
    Panel1: TPanel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    edtProxyServer: TEdit;
    edtProxyPort: TEdit;
    edtProxyUsername: TEdit;
    edtProxyPassword: TEdit;
    chkBasicAuthentication: TCheckBox;
    Panel2: TPanel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    edtRedirectUrl: TEdit;
    edtLastUpdate: TEdit;
    edtUpdateCount: TEdit;
    edtFailureCount: TEdit;
    Panel3: TPanel;
    Label1: TLabel;
    Label3: TLabel;
    edtUsername: TEdit;
    edtEntryName: TEdit;
    Label2: TLabel;
    Label4: TLabel;
    edtPassword: TEdit;
    cmbInterval: TComboBox;
    chkAutoRun: TCheckBox;
    chkMinimized: TCheckBox;
    LinkLabel1: TLinkLabel;
    btnSave: TButton;
    Label14: TLabel;
    Image1: TImage;
    timerUpdate: TTimer;
    LinkLabel2: TLinkLabel;
    Label15: TLabel;
    Label16: TLabel;
    procedure TrayIcon1Click(Sender: TObject);
    procedure mmShowHideClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure mmExitClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure mmAboutClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure LinkLabel1LinkClick(Sender: TObject; const Link: string;
      LinkType: TSysLinkType);
    procedure timerUpdateTimer(Sender: TObject);
  private
    { Private declarations }
    _ini: Tinifile;
    _bCloseByUser: bool;
    _serviceUrl: string;
    _version: string;

    _thCheckAppUpdate: TIdHttpThread;
    _thUpdateIp: TIdHttpThread;
    _thDownload: TIdHttpThread;

    procedure CheckAppUpdate;
    procedure OnHttpThreadComplete(thread: TIdHttpThread; msg: string);
    procedure OnHttpThreadError(thread: TIdHttpThread; e: Exception);
    procedure ToggleVisible;
    procedure SaveConfig;
    procedure ApplyConfig;
    procedure UpdateIp;
    procedure LoadConfig;
    procedure ExecuteUpdateApp(url: string);
    function getHttpConnection: TIdHTTP;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.OnHttpThreadComplete(thread: TIdHttpThread; msg: string);
var
  html: string;
  filename: string;
begin
  if SameText(thread.Key, 'app') then
  begin
    // 判断是否是网址
    html := thread.html;
    if not StartWith(html, 'http://') then
      exit;
    filename := getFileNameFromURL(html);
    // 判断是否是zip文件
    if not EndWith(LowerCase(filename), '.zip') then
      exit;

    _thDownload := TIdHttpThread.Create(nil);
    _thDownload.Key := 'download';
    _thDownload.Mode := TIdHttpThreadMode.ihmFile;
    _thDownload.OnComplete := self.OnHttpThreadComplete;
    _thDownload.OnError := self.OnHttpThreadError;
    _thDownload.url := html;
    _thDownload.filename := getFileNameFromURL(html);
    _thDownload.IdHTTP := self.getHttpConnection;
    _thDownload.Start;
  end
  else if SameText(thread.Key, 'ip') then
  begin
    edtLastUpdate.Text := FormatDateTime('yyyy-mm-dd hh:mm:ss', Now);
    edtUpdateCount.Text := IntToStr(StrToInt(edtUpdateCount.Text) + 1);
  end
  else if SameText(thread.Key, 'download') then
  begin
    self.ExecuteUpdateApp(thread.url);
  end;

end;

procedure TForm1.OnHttpThreadError(thread: TIdHttpThread; e: Exception);
begin
  if SameText(thread.Key, 'ip') then
  begin
    edtFailureCount.Text := IntToStr(StrToInt(edtFailureCount.Text) + 1);
  end;
end;

// 应用配置，生效
procedure TForm1.ApplyConfig;
var
  intervalMap: array [0 .. 2] of Integer;
begin
  intervalMap[0] := 10 * 60;
  intervalMap[1] := 60 * 60;
  intervalMap[2] := 24 * 60 * 60;
  Timer1.Interval := intervalMap[cmbInterval.ItemIndex] * 1000;

  edtRedirectUrl.Text := _serviceUrl + '?action=redirect&u=' + edtUsername.Text
    + '&n=' + edtEntryName.Text;

  if chkAutoRun.Checked then
  begin
    UnitPublic.setAutoRun(Application, gAppName, true);
  end
  else
  begin
    UnitPublic.setAutoRun(Application, gAppName, false);
  end;
end;

// 加载配置
procedure TForm1.LoadConfig;
var
  intervalIndex: Integer;
  bAutoRun: bool;
  bStartMini: bool;
begin
  // 基本配置
  _serviceUrl := _ini.Readstring('WebDns', 'ServiceUrl',
    'http://www.dev91.ml/sv/');
  bAutoRun := _ini.ReadBool('WebDns', 'AutoRun', true);
  bStartMini := _ini.ReadBool('WebDns', 'StartMini', true);
  if bStartMini then
  begin
    Application.ShowMainForm := false;
  end;
  chkAutoRun.Checked := bAutoRun;
  chkMinimized.Checked := bStartMini;

  // 连接信息
  edtUsername.Text := _ini.Readstring('WebDns', 'Username', 'public');
  edtPassword.Text := _ini.Readstring('WebDns', 'Password', 'public');
  edtEntryName.Text := _ini.Readstring('WebDns', 'EntryName',
    fnGetComputerName);
  cmbInterval.ItemIndex := _ini.ReadInteger('WebDns', 'IntervalIndex', 0);

  // 代理服务器
  edtProxyServer.Text := _ini.Readstring('WebDns', 'proxyServer', '');
  edtProxyPort.Text := _ini.Readstring('WebDns', 'proxyPort', '');
  edtProxyUsername.Text := _ini.Readstring('WebDns', 'proxyUsername', '');
  edtProxyPassword.Text := _ini.Readstring('WebDns', 'proxyPassword', '');
  chkBasicAuthentication.Checked := _ini.ReadBool('WebDns',
    'BasicAuthentication', true);
end;

// 保存配置
procedure TForm1.SaveConfig;
begin
  _ini.WriteString('WebDns', 'Username', edtUsername.Text);
  _ini.WriteString('WebDns', 'Password', edtPassword.Text);
  _ini.WriteString('WebDns', 'EntryName', edtEntryName.Text);
  _ini.WriteInteger('WebDns', 'IntervalIndex', cmbInterval.ItemIndex);
  _ini.WriteBool('WebDns', 'AutoRun', chkAutoRun.Checked);
  _ini.WriteBool('WebDns', 'StartMini', chkMinimized.Checked);

  // 代理服务器
  _ini.WriteString('WebDns', 'proxyServer', edtProxyServer.Text);
  _ini.WriteString('WebDns', 'proxyPort', edtProxyPort.Text);
  _ini.WriteString('WebDns', 'proxyUsername', edtProxyUsername.Text);
  _ini.WriteString('WebDns', 'proxyPassword', edtProxyPassword.Text);
  _ini.WriteBool('WebDns', 'BasicAuthentication',
    chkBasicAuthentication.Checked);

end;

procedure TForm1.btnSaveClick(Sender: TObject);
begin
  self.SaveConfig;
  self.ApplyConfig;
  self.Hide;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if _bCloseByUser then
  begin
    CanClose := true;
  end
  else
  begin
    self.ToggleVisible;
    CanClose := false;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  filename: string;
begin
  UnitPublic.InitializeApplication(Application);
  _version := '1.1';
  _bCloseByUser := false;
  self.Caption := self.Caption + ' v' + _version;

  filename := ExtractFilePath(Paramstr(0)) + 'webdns.ini';
  _ini := Tinifile.Create(filename);

  self.LoadConfig;
  self.ApplyConfig;
  self.UpdateIp;
end;

procedure TForm1.LinkLabel1LinkClick(Sender: TObject; const Link: string;
  LinkType: TSysLinkType);
begin
  ShellExecute(0, nil, PChar(Link), nil, nil, 1);
end;

procedure TForm1.mmAboutClick(Sender: TObject);
var
  formAbout: UnitAbout.TFormAbout;
begin
  formAbout := UnitAbout.TFormAbout.Create(self);
  formAbout.ShowModal;
end;

procedure TForm1.mmExitClick(Sender: TObject);
begin
  _bCloseByUser := true;
  self.Close;
end;

procedure TForm1.mmShowHideClick(Sender: TObject);
begin
  self.ToggleVisible;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  self.UpdateIp;
end;

procedure TForm1.CheckAppUpdate;
begin
  // 创建IdHTTP线程
  _thCheckAppUpdate := TIdHttpThread.Create(nil);
  _thCheckAppUpdate.Key := 'app';
  _thCheckAppUpdate.Mode := TIdHttpThreadMode.ihmHtml;
  _thCheckAppUpdate.OnComplete := self.OnHttpThreadComplete;
  _thCheckAppUpdate.OnError := self.OnHttpThreadError;

  _thCheckAppUpdate.IdHTTP := self.getHttpConnection;
  _thCheckAppUpdate.url := _serviceUrl + 'index.php?action=checkupdate&version='
    + _version;
  _thCheckAppUpdate.Start;
end;

procedure TForm1.timerUpdateTimer(Sender: TObject);
begin
  self.CheckAppUpdate;
end;

procedure TForm1.ToggleVisible;
begin
  if not self.Visible then
  begin
    self.Show;
  end
  else
  begin
    self.Hide;
  end;

end;

procedure TForm1.TrayIcon1Click(Sender: TObject);
begin
  self.ToggleVisible;
end;

// 解压并执行更新脚本
procedure TForm1.ExecuteUpdateApp(url: string);
var
  filename: string;
  cmdfile: String;
begin
  filename := getFileNameFromURL(url);
  // 删除自动脚本
  cmdfile := gSysDir + '\autorun.cmd';
  DeleteFile(cmdfile);
  // 解压到当前文件夹
  UnZipDir(gSysDir + filename, gSysDir);
  // 执行自动更新脚本
  if FileExists(cmdfile) then
  begin
    ShellExecute(HWND(nil), nil, PWideChar(cmdfile), nil, nil, SW_HIDE);
  end;
end;

// 获取HTTP连接，初始化代理
function TForm1.getHttpConnection: TIdHTTP;
var
  http: TIdHTTP;
begin
  if (_serviceUrl = '') or (edtUsername.Text = '') then
  begin
    exit;
  end;
  http := TIdHTTP.Create(nil);
  http.HandleRedirects := true;
  if not(edtProxyServer.Text = '') then
  begin
    http.ProxyParams.proxyServer := edtProxyServer.Text;
    http.ProxyParams.proxyPort := StrToInt(edtProxyPort.Text);
    http.ProxyParams.proxyUsername := edtProxyUsername.Text;
    http.ProxyParams.proxyPassword := edtProxyPassword.Text;
    http.ProxyParams.BasicAuthentication := true;
  end;
  Result := http;
end;

procedure TForm1.UpdateIp;
var
  url: string;
begin
  if (_serviceUrl = '') or (edtUsername.Text = '') then
  begin
    exit;
  end;
  _thUpdateIp := TIdHttpThread.Create(nil);
  _thUpdateIp.Key := 'ip';
  _thUpdateIp.Mode := TIdHttpThreadMode.ihmHtml;
  _thUpdateIp.OnComplete := self.OnHttpThreadComplete;
  _thUpdateIp.OnError := self.OnHttpThreadError;

  url := _serviceUrl + 'index.php?action=updateip&u=' + edtUsername.Text + '&p='
    + edtPassword.Text + '&name=' + edtEntryName.Text;
  _thUpdateIp.IdHTTP := self.getHttpConnection;
  _thUpdateIp.url := url;
  _thUpdateIp.Start;

end;

end.
