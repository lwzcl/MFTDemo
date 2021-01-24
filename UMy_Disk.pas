unit UMy_Disk;

interface

uses
  System.Classes, Winapi.Windows, Vcl.StdCtrls, System.SysUtils, uNTFS;

type
  time_t = Int64;

type
  My_Disk = class
  private { Private declarations }
    function CheckNTFS(aDrive: string): string;
  public
    procedure myStart();
  end;

implementation

{ My_Disk }

function My_Disk.CheckNTFS(aDrive: string): string;
var
  hDevice: THandle;
  PBootSequence: ^TBOOT_SEQUENCE;
  dwRead: Cardinal;
begin
  result := '';
  hDevice := CreateFile(PChar('\\.\' + aDrive), GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if (hDevice = INVALID_HANDLE_VALUE) then
  begin
    CloseHandle(hDevice);
    exit;
  end;
  New(PBootSequence);
  ZeroMemory(PBootSequence, SizeOf(TBOOT_SEQUENCE));
  SetFilePointer(hDevice, 0, nil, FILE_BEGIN);
  ReadFile(hDevice, PBootSequence^, 512, dwRead, nil);
  with PBootSequence^ do
  begin
    //result := cOEMID[1]+cOEMID[2]+cOEMID[3]+cOEMID[4];
    if (cOEMID[1] = $4E) and (cOEMID[2] = $54) and (cOEMID[3] = $46) and (cOEMID[4] = $53) then
    begin
      Result := 'NTFS';
    end;

    Dispose(PBootSequence);
    Closehandle(hDevice);

  end;

end;

procedure My_Disk.myStart;
begin

end;

end.

