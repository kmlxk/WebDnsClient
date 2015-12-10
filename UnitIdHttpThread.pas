unit UnitIdHttpThread;

interface

uses
  Windows, SysUtils, Variants, Classes, Math, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdHTTP,
  IdAntiFreezeBase, IdAntiFreeze, IdException;

type
  TIdHttpThread = class;
  TOnHttpThreadComplete = procedure(thread: TIdHttpThread; msg: string)
    of object;
  TOnHttpThreadError = procedure(thread: TIdHttpThread; e: Exception) of object;
  TIdHttpThreadMode = (ihmHtml, ihmFile);

  TIdHttpThread = class(TThread)
  private
    _http: TIdHTTP;
    _mode: TIdHttpThreadMode;
    _url: string;
    _html: string;
    _filename: string;
    _key: string;
    _OnComplete: TOnHttpThreadComplete;
    _OnError: TOnHttpThreadError;
  public
    constructor Create(http: TIdHTTP);
    property OnComplete: TOnHttpThreadComplete read _OnComplete
      write _OnComplete;
    property OnError: TOnHttpThreadError read _OnError write _OnError;
    property Url: string read _url write _url;
    property IdHTTP: TIdHTTP read _http write _http;
    // 两种模式，1、直接获取html，2、保存到文件
    property Mode: TIdHttpThreadMode read _mode write _mode;
    // 模式1、直接获取html
    property Html: string read _html write _html;
    // 模式2、保存到文件
    property Filename: string read _filename write _filename;
    property Key: string read _key write _key;
  protected
    procedure Execute; override;
    procedure _download;
    function _getHtml: String;
  end;

implementation

constructor TIdHttpThread.Create(http: TIdHTTP);
begin
  inherited Create(true); // 手动启动线程
  FreeOnTerminate := true;
  _http := http;
end;

procedure TIdHttpThread.Execute;
begin
  if Terminated then
    exit;
  try
    try
      if _mode = TIdHttpThreadMode.ihmHtml then
      begin
        _html := self._getHtml;
        if Assigned(_OnComplete) then
          _OnComplete(self, 'html');
      end
      else if _mode = TIdHttpThreadMode.ihmFile then
      begin
        self._download;
        if Assigned(_OnComplete) then
          _OnComplete(self, 'download');
      end;

    except
      on e: EIdException do
      begin
        if Assigned(_OnError) then
          _OnError(self, e);
      end;
    end
  finally

  end;
end;

function TIdHttpThread._getHtml: String;
var
  RespData: TStringStream;
begin
  RespData := TStringStream.Create('');
  try
    _http.Get(_url, RespData);
    Result := RespData.DataString;
    _http.Disconnect;
  except
    Result := '';
  end;
  freeandnil(RespData);
end;

procedure TIdHttpThread._download;
var
  stream: TFileStream;
begin
  stream := TFileStream.Create(_filename, fmCreate);
  try
    _http.Get(_url, stream);
    _http.Disconnect;
    freeandnil(stream);
  except
    on e: Exception do
    begin
      _http.Disconnect;
      freeandnil(stream);
    end;
  end;

end;

end.
