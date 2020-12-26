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
  c_updateurl = 'https://codingbott.github.io/OnlineUpdatesDelphi/serverinfo.xml';

var
  version: tVersionsInformation;
  r: TUpdateInfo;
  x: string;
begin
  try
    version:=TVersionHelpher.gibVersion( ParamStr(0) );
    writeln(
      TVersionHelpher.versionZuString(version)
    );

    r:=TUpdateCheck.checkForUpdate(c_updateurl);

    case TVersionHelpher.vergleicheVersion(version, TVersionHelpher.stringZuVersion(r.version)) of
      1: Writeln('größer');
      0: Writeln('gleich');
      -1: begin
        Writeln('kleiner');
        Writeln('Serverversion: '+r.version);
        Writeln(r.text);

        Writeln('Updaten j?');
        Readln(x);
        if x='j' then
        begin
          // download
          // TDownloadActionLoadUrl.Download('e:\temp\test.txt', r.url, nil);
          TDownloadBits.DownloadForground('e:\temp\test.txt', r.url, nil);
          // installation
        end;
      end;
    end;

    Writeln('-Fertig-');
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
