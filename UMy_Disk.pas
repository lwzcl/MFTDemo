unit UMy_Disk;

interface

uses
  System.Classes, Winapi.Windows, Vcl.StdCtrls, System.SysUtils, uNTFS;

type
  time_t = Int64;

type
  My_Disk = class
  private { Private declarations }
    diskInfo: TDISK_INFORMATION;
    function CheckNTFS(aDrive: string): string;
  public
    procedure myStart();
  end;
var
 MFT_Location : int64;
 IsSearching : boolean;
implementation

uses
  UMain;
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
var
  hDevice, hDest: THandle;
  BootData: array[1..512] of Char;
  pBootSequence: ^TBOOT_SEQUENCE;
  dwread: LongWord;
  tmp:string;
  MFTData: TDynamicCharArray;
begin
   tmp := '123';
  hDevice := CreateFile(PChar('\\.\' + Form1.Com_drvie.Text), GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if (hDevice = INVALID_HANDLE_VALUE) then
  begin
    CloseHandle(hDevice);

    exit;
  end;

  New(pBootSequence);
  ZeroMemory(pBootSequence, SizeOf(TBOOT_SEQUENCE));
  SetFilePointer(hDevice, 0, nil, FILE_BEGIN);
  ReadFile(hDevice, pBootSequence^, 512, dwread, nil);
  diskInfo.BytesPerSector := PBootSequence^.wBytesPerSector;
  diskInfo.SectorsPerCluster := PBootSequence^.bSectorsPerCluster;
  diskInfo.BytesPerCluster := diskInfo.BytesPerSector *diskInfo.SectorsPerCluster;
   if (PBootSequence^.ClustersPerFileRecord < $80) then
      diskInfo.BytesPerFileRecord := PBootSequence^.ClustersPerFileRecord *
                                     diskInfo.BytesPerCluster
  else
      diskInfo.BytesPerFileRecord := 1 shl ($100 - PBootSequence^.ClustersPerFileRecord);
  MFT_Location := PBootSequence^.MftStartLcn * PBootSequence^.wBytesPerSector
                                * PBootSequence^.bSectorsPerCluster;



  SetLength(MFTData,diskInfo.BytesPerFileRecord);
  SetFilePointer(hDevice, Int64Rec(MFT_Location).Lo,
                 @Int64Rec(MFT_Location).Hi, FILE_BEGIN);
  Readfile(hDevice, PChar(MFTData)^, diskInfo.BytesPerFileRecord, dwread, nil);

  //**** 获取主记录 ************************************************************
  if not FixupUpdateSequence(MFTData,diskInfo) then
  begin
    Closehandle(hDevice);
    Dispose(PBootSequence);
    IsSearching := false;
    exit;
  end;
end;

end.

