program XmlReader;

uses
  Forms,
  Main in 'Main.pas' {FrmMain};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'XML Reader';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
