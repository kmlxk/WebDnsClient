program WebDnsClient;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  UnitAbout in 'UnitAbout.pas' {FormAbout},
  UnitPublic in 'UnitPublic.pas',
  UnitUtil in 'UnitUtil.pas',
  UnitIdHttpThread in 'UnitIdHttpThread.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TFormAbout, FormAbout);
  Application.Run;
end.
