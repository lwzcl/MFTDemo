{******************************************************************************}
{*                                                                            *}
{*             NTFS���ָ̻�����                           *}
{******************************************************************************}

unit uNTFS;

interface

uses Windows;

type
  TDynamicCharArray = array of Char;

type
  TBOOT_SEQUENCE = packed record        // �����������ݽṹ
    _jmpcode : array[1..3] of Byte;
//   	cOEMID: array[1..4] of Char;
    cOEMID: array[1..8] of Byte;
 	  wBytesPerSector: Word;
 	  bSectorsPerCluster: Byte;
    wSectorsReservedAtBegin: Word;
 	  Mbz1: Byte;
 	  Mbz2: Word;
 	  Reserved1: Word;
 	  bMediaDescriptor: Byte;
 	  Mbz3: Word;
 	  wSectorsPerTrack: Word;
 	  wSides: Word;
 	  dwSpecialHiddenSectors: DWord;
 	  Reserved2: DWord;
 	  Reserved3: DWord;
 	  TotalSectors: Int64;
 	  MftStartLcn: Int64;
 	  Mft2StartLcn: Int64;
 	  ClustersPerFileRecord: DWord;
 	  ClustersPerIndexBlock: DWord;
 	  VolumeSerialNumber: Int64;
 	  _loadercode: array[1..430] of Byte;
 	  wSignature: Word;
  end;

type
  TNTFS_RECORD_HEADER = packed record
    Identifier: array[1..4] of Byte; // �̶�ֵ'FILE'
    UsaOffset : Word;                // �������к�ƫ��,�����ϵͳ�й�
    UsaCount : Word;                 // �̶��б���С
    LSN : Int64;                     // ��־�ļ����к�
  end;

type
  TFILE_RECORD = packed record            // MFT�ļ���¼����ͷ�ṹ
    Header: TNTFS_RECORD_HEADER;          // ͷ����
	  SequenceNumber : Word;                // ���к�(���ڼ�¼�ļ�������ʹ�õĴ���)
	  ReferenceCount : Word;                // Ӳ������,��Ŀ¼�е���Ŀ����
	  AttributesOffset : Word;              // ��һ�����Ե�ƫ��
	  Flags : Word;                         // 0=ɾ�� 1=��ͨ�ļ� 2=Ŀ¼��ɾ�� 3=��ͨĿ¼
	  BytesInUse : DWord;                   // �ļ���¼��ʵ�ʴ�С(�ֽ�)
	  BytesAllocated : DWord;               // �ļ���¼����Ĵ�С(�ֽ�)
	  BaseFileRecord : Int64;               // ������¼
	  NextAttributeID : Word;               // ��һ������ID
    Pading : Word;                // Align to 4 Bytes boundary (XP)
    MFTRecordNumber : DWord;      // Number of this MFT Record (XP)
  end;

type
  TRECORD_ATTRIBUTE = packed record    //�������ԵĹ��в���
    AttributeType : DWord;             // ����
    Length : DWord;                    // ����
    NonResident : Byte;                // �ǳ�פ��־(0x00: ��פ����; 0x01: �ǳ�פ����)
    NameLength : Byte;                 // ���Ƴ���
    NameOffset : Word;                 // ����ƫ��
    Flags : Word;                      // ��ʶ
    AttributeNumber : Word;            // ��ʶ
  end;

type
  TRESIDENT_ATTRIBUTE = packed record       // ��פ����
    Attribute : TRECORD_ATTRIBUTE;
    ValueLength : DWord;
    ValueOffset : Word;
    Flags : Word;
  end;

type
  TNONRESIDENT_ATTRIBUTE = packed record    // �ǳ�פ����
    Attribute: TRECORD_ATTRIBUTE;
    LowVCN: Int64;
    HighVCN: Int64;
    RunArrayOffset : Word;
    CompressionUnit : Byte;
    Padding : array[1..5] of Byte;
    AllocatedSize: Int64;
    DataSize: Int64;
    InitializedSize: Int64;
    CompressedSize: Int64;
  end;

type
  TFILENAME_ATTRIBUTE = packed record       // �ļ�������
	  Attribute: TRESIDENT_ATTRIBUTE;
    DirectoryFileReferenceNumber: Int64;
    CreationTime: Int64;
    ChangeTime: Int64;
    LastWriteTime: Int64;
    LastAccessTime: Int64;
    AllocatedSize: Int64;
    DataSize: Int64;
    FileAttributes: DWord;
    AlignmentOrReserved: DWord;
    NameLength: Byte;
    NameType: Byte;
	  Name: Word;
  end;

type
  TSTANDARD_INFORMATION = packed record      //��׼����
	  Attribute: TRESIDENT_ATTRIBUTE;  //��פ
	  CreationTime: Int64;
	  ChangeTime: Int64;
	  LastWriteTime: Int64;
	  LastAccessTime: Int64;
	  FileAttributes: DWord;
	  Alignment: array[1..3] of DWord;
	  QuotaID: DWord;
	  SecurityID: DWord;
	  QuotaCharge: Int64;
	  USN: Int64;
  end;

type
  TDISK_INFORMATION = packed record
      BytesPerFileRecord: Word;
      BytesPerCluster: Word;
      BytesPerSector: Word;
      SectorsPerCluster: Word;
  end;

const
  // MFT����
  AttributeStandardInformation = $10;
  AttributeAttributeList = $20;
  AttributeFileName = $30;
  AttributeObjectId = $40;
  AttributeSecurityDescriptor = $50;
  AttributeVolumeName	= $60;
  AttributeVolumeInformation = $70;
  AttributeData = $80;
  AttributeIndexRoot = $90;
  AttributeIndexAllocation = $A0;
  AttributeBitmap = $B0;
  AttributeReparsePoint	= $C0;
  AttributeEAInformation = $D0;
  AttributeEA = $E0;
  AttributePropertySet = $F0;
  AttributeLoggedUtilityStream = $100;

function GetVolumeLabel(Drive: Char): string;
function FixupUpdateSequence(var RecordData: TDynamicCharArray; diskInfo: TDISK_INFORMATION):boolean;
function FindAttributeByType(RecordData: TDynamicCharArray; AttributeType: DWord;       //������������
                                      FindSpecificFileNameSpaceValue: boolean=false) : TDynamicCharArray;
//������������


implementation
uses SysUtils;

function GetVolumeLabel(Drive: Char): string;
var
  unused, flags: DWord;
  buffer: array [0..MAX_PATH] of Char;
begin
  buffer[0] := #$00;
  if GetVolumeInformation(PChar(Drive + ':\'), buffer, DWord(sizeof(buffer)),nil,unused,flags,nil,0) then
     SetString(result, buffer, StrLen(buffer))
  else
     result := '';
end;
 /// <code>
 /// ������������
 /// </code>
function FindAttributeByType(RecordData: TDynamicCharArray; AttributeType: DWord;
                                      FindSpecificFileNameSpaceValue: boolean=false) : TDynamicCharArray;
var
  pFileRecord: ^TFILE_RECORD;
  pRecordAttribute: ^TRECORD_ATTRIBUTE;
  NextAttributeOffset: Word;
  TmpRecordData: TDynamicCharArray;
  TotalBytes: Word;
begin
  New(pFileRecord);
  ZeroMemory(pFileRecord, SizeOf(TFILE_RECORD));
  CopyMemory(pFileRecord, RecordData, SizeOf(TFILE_RECORD));
  if  (pFileRecord.Header.Identifier[1] = $46)and ( pFileRecord.Header.Identifier[2]=$49)
     and (pFileRecord.Header.Identifier[3]=$4C) and ( pFileRecord.Header.Identifier[4]=$45) then begin
    NextAttributeOffset := 0;
  end else begin
    NextAttributeOffset := pFileRecord^.AttributesOffset;
  end;

  TotalBytes := Length(RecordData);
  Dispose(pFileRecord);

  New(pRecordAttribute);
  ZeroMemory(pRecordAttribute, SizeOf(TRECORD_ATTRIBUTE));

  SetLength(TmpRecordData,TotalBytes-(NextAttributeOffset-1));
  TmpRecordData := Copy(RecordData,NextAttributeOffset,TotalBytes-(NextAttributeOffset-1));
  CopyMemory(pRecordAttribute, TmpRecordData, SizeOf(TRECORD_ATTRIBUTE));

  while (pRecordAttribute^.AttributeType <> $FFFFFFFF) and
        (pRecordAttribute^.AttributeType <> AttributeType) do begin
    NextAttributeOffset := NextAttributeOffset + pRecordAttribute^.Length;
    SetLength(TmpRecordData,TotalBytes-(NextAttributeOffset-1));
    TmpRecordData := Copy(RecordData,NextAttributeOffset,TotalBytes-(NextAttributeOffset-1));
    CopyMemory(pRecordAttribute, TmpRecordData, SizeOf(TRECORD_ATTRIBUTE));
  end;

  if pRecordAttribute^.AttributeType = AttributeType then begin

    if (FindSpecificFileNameSpaceValue) and (AttributeType=AttributeFileName)  then begin
      if (TmpRecordData[$59]=Char($0)) {POSIX} or (TmpRecordData[$59]=Char($1)) {Win32}
         or (TmpRecordData[$59]=Char($3)) {Win32&DOS} then begin
        SetLength(result,pRecordAttribute^.Length);
        result := Copy(TmpRecordData,0,pRecordAttribute^.Length);
      end else begin
        NextAttributeOffset := NextAttributeOffset + pRecordAttribute^.Length;
        SetLength(TmpRecordData,TotalBytes-(NextAttributeOffset-1));
        TmpRecordData := Copy(RecordData,NextAttributeOffset,TotalBytes-(NextAttributeOffset-1));
        result := FindAttributeByType(TmpRecordData,AttributeType,true);
      end;

    end else begin
      SetLength(result,pRecordAttribute^.Length);
      result := Copy(TmpRecordData,0,pRecordAttribute^.Length);
    end;

  end else begin
    result := nil;
  end;
  Dispose(pRecordAttribute);
end;

/// <code>
///    //������������
/// </code>
function FixupUpdateSequence(var RecordData: TDynamicCharArray; diskInfo: TDISK_INFORMATION):boolean;
var
  pFileRecord: ^TFILE_RECORD;
  UpdateSequenceOffset, UpdateSequenceCount: Word;
  UpdateSequenceNumber: array[1..2] of Char;
  i: integer;
  tmp:integer;
begin
  result := false;
  New(pFileRecord);
  ZeroMemory(pFileRecord, SizeOf(TFILE_RECORD));
  CopyMemory(pFileRecord, RecordData, SizeOf(TFILE_RECORD));

  with pFileRecord^.Header do
  begin
    if (Identifier[1] <> $46)and (Identifier[2] <> $49) and (Identifier[3] <> $4C)and (Identifier[4]<> $45)  then
    begin
      Dispose(pFileRecord);
      exit;
    end;
  end;

  UpdateSequenceOffset := pFileRecord^.Header.UsaOffset;
  UpdateSequenceCount := pFileRecord^.Header.UsaCount;
  Dispose(pFileRecord);
  UpdateSequenceNumber[1] := RecordData[UpdateSequenceOffset];
  UpdateSequenceNumber[2] := RecordData[UpdateSequenceOffset+1];
  tmp:=  UpdateSequenceCount;

  for  I:= 1 to tmp -1 do
  begin
    if (RecordData[i * diskInfo.BytesPerSector-2] = UpdateSequenceNumber[1]) and (RecordData[i * diskInfo.BytesPerSector-1] = UpdateSequenceNumber[2]) then
    begin
       exit;
    end;
    RecordData[i * diskInfo.BytesPerSector-2] := RecordData[UpdateSequenceOffset+2*i];
    RecordData[i * diskInfo.BytesPerSector-1] := RecordData[UpdateSequenceOffset+1+2*i];

  end;
  result := true;
end;


end.