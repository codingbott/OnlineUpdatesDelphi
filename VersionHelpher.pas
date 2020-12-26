unit VersionHelpher;

interface

uses
  Classes, Windows;

type
  tVersionsInformation = record
    case boolean of
      true:
        (minor,
        major,
        build,
        patch: Word);
      false:
        (dwFileVersionMS,
        dwFileVersionLS: DWord);
    end;

  TVersionHelpher = class
  public
    class function gibVersion(filename: string): tVersionsInformation;
    class function vergleicheVersion(a,b: tVersionsInformation): integer;
    class function stringZuVersion(str_version:string): tVersionsInformation;
    class function versionZuString(version: tVersionsInformation): string;
  end;

implementation

uses
  SysUtils, Math;

{ tVersionsErmittlung }

class function TVersionHelpher.gibVersion(filename: string): tVersionsInformation;
var
  versionHandle, versionSize:  DWord;
  pVersionInfo: pointer;
  itemLen: UInt;
  FixedFileInfo: PVSFixedFileInfo;
  bol_versiongefunden: boolean;
begin
  bol_versiongefunden:=false;
  versionSize:=GetFileVersionInfoSize(PChar(filename), versionHandle);
  pVersionInfo:=AllocMem(versionSize);
  try
    if versionSize>0 then
    begin
      if GetFileVersionInfo(PChar(filename), versionHandle, versionSize, pVersionInfo) then
      begin
        if VerQueryValue(pVersionInfo, '', pointer(FixedFileInfo), itemLen) then
        begin
          result.dwFileVersionMS:=FixedFileInfo.dwFileVersionMS;
          result.dwFileVersionLS:=FixedFileInfo.dwFileVersionLS;
          bol_versiongefunden:=true;
        end;
      end;
    end;
    if not bol_versiongefunden then
      raise Exception.Create('keine Versionsinformation gefunden');
  finally
    freemem(pVersionInfo);
  end;
end;

class function TVersionHelpher.stringZuVersion(
  str_version:string): tVersionsInformation;
var
  sl: TStringlist;
begin
  Result.dwFileVersionMS:=0;
  Result.dwFileVersionLS:=0;

  sl:=TStringList.Create;
  try
    sl.Delimiter:='.';
    sl.DelimitedText:=str_version;

    result.major:=strtoint(sl[0]);
    if sl.Count>1 then
      result.minor:=strtoint(sl[1]);
    if sl.Count>2 then
      result.patch:=strtoint(sl[2]);
    if sl.Count>3 then
      result.build:=strtoint(sl[3]);
  finally
    sl.Free;
  end;

end;

class function TVersionHelpher.vergleicheVersion(a,
  b: tVersionsInformation): integer;
begin
  result:=CompareValue(a.major, b.major);
  if result=0 then
    result:=CompareValue(a.minor, b.minor);
  if result=0 then
    result:=CompareValue(a.patch, b.patch);
  if result=0 then
    result:=CompareValue(a.build, b.build);
end;

class function TVersionHelpher.versionZuString(
  version: tVersionsInformation): string;
begin
  result:=Format('%d.%d.%d.%d', [version.major, version.minor, version.patch, version.build]);
end;

initialization

end.
