unit uc_downloadactionloadurl;

interface

uses
  ExtActns;

type
  TDownloadActionLoadUrl = class
  public
    class procedure Download(ziel, downloadurl: string; DownloadFeedback:TDownloadProgressEvent);
  end;

implementation


{ TDownload1 }

class procedure TDownloadActionLoadUrl.Download(ziel, downloadurl: string; DownloadFeedback:TDownloadProgressEvent);
begin
  with TDownLoadURL.Create(nil) do
  try
    URL:=downloadurl;
    Filename:=ziel;
    OnDownloadProgress:=DownloadFeedback;
    Execute();
  finally
    free;
  end;
end;

end.
