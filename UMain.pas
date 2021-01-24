unit UMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Com_drvie: TComboBox;
    TreeView1: TTreeView;
    Button1: TButton;
    Button2: TButton;
    Drive_Background: TShape;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);

  private
    IsSearching: Boolean;
    { Private declarations }
    procedure GetDiskType(DriveList: TComboBox);

   public
    property myIsSearching: Boolean read IsSearching write IsSearching;
    procedure startdemo();
  end;

var
  Form1: TForm1;

implementation
 uses
 UMy_Disk;
{$R *.dfm}

{ TForm1 }
 var
  disk: My_Disk;

procedure TForm1.Button1Click(Sender: TObject);

begin


   TThread.CreateAnonymousThread(startdemo).Start;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
      Com_drvie.ItemIndex := 0;
      disk:= My_Disk.Create;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
     GetDiskType(Com_drvie);
end;

procedure TForm1.GetDiskType(DriveList: TComboBox);
var
  str: string;
  Drivers: Integer;
  driver: char;
  i, temp: integer;
  d1, d2, d3, d4: DWORD;
  ss: string;
begin

  ss := '';
  Drivers := GetLogicalDrives;
  temp := (1 and Drivers);
  for i := 0 to 26 do
  begin
    if temp = 1 then
    begin
      driver := char(i + integer('A'));
      str := driver;
      if (driver <> '') and (getdrivetype(pchar(str)) <> drive_cdrom) and (getdrivetype(pchar(str)) <> DRIVE_REMOVABLE) then  //这里可以修改 获取光盘 可移动磁盘
      begin
        GetDiskFreeSpace(pchar(str), d1, d2, d3, d4);
        DriveList.Items.Add(str + ':');

      end;
    end;
    Drivers := (Drivers shr 1);
    temp := (1 and Drivers);

  end;

end;

procedure TForm1.startdemo;
begin
    disk.myStart;
end;

end.
