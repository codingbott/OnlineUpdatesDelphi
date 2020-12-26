program demo;

{$APPTYPE CONSOLE}

{$R *.res}

{$R 'Version.res' 'Version.rc'}

uses
  System.SysUtils,
  VersionHelpher in 'VersionHelpher.pas',
  MSXML2_TLB in 'MSXML2_TLB.pas',
  uc_downloadactionloadurl in 'uc_downloadactionloadurl.pas',
  uc_DownloadBits in 'uc_DownloadBits.pas',
  uc_updatecheck in 'uc_updatecheck.pas';

const
  c_updateurl = 'https://raw.githubusercontent.com/codingbott/OnlineUpdatesDelphi/main/server/serverinfo.xml';

var
  version: tVersionsInformation;
begin
  try
    version:=TVersionHelpher.gibVersion( ParamStr(0) );
    writeln(
      TVersionHelpher.versionZuString(version)
    );

    case TVersionHelpher.vergleicheVersion(version, TVersionHelpher.stringZuVersion('3.11.12')) of
      1: Writeln('Größer');
      0: Writeln('gleich');
      -1: Writeln('kleiner');
    end;

    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
