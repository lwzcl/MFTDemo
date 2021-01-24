program Mft…®√Ë≥Ã–Ú;

uses
  Vcl.Forms,
  UMain in 'UMain.pas' {Form1},
  uNTFS in 'uNTFS.pas',
  UMy_Disk in 'UMy_Disk.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
