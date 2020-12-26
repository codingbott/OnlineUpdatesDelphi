unit uc_DownloadBits;

interface

uses
  ExtActns;

type
  TDownloadBits = class
  public
    class procedure DownloadForground(ziel, downloadurl: WideString; DownloadFeedback:TDownloadProgressEvent);
    class procedure DownloadBackground(ziel, downloadurl, ExeName, Params: WideString);
    class procedure CompleteJob(JobId: WideString);
  end;

implementation

uses
  ComObj, ActiveX, SysUtils,
  JwaBits, JwaBits1_5, Windows;

{ TDownloadBits }

class procedure TDownloadBits.CompleteJob(JobId: WideString);
var
  bi: IBackgroundCopyManager;
  job: IBackgroundCopyJob;
  g: TGuid;
begin
  bi:=CreateComObject(CLSID_BackgroundCopyManager) as IBackgroundCopyManager;
  g:=StringToGUID(jobid);
  bi.GetJob(g,job);
  job.Complete();
end;

class procedure TDownloadBits.DownloadBackground(ziel, downloadurl,
  ExeName, Params: WideString);

var
  bi: IBackgroundCopyManager;
  job: IBackgroundCopyJob;
  job2: IBackgroundCopyJob2;
  jobId: TGUID;
  r: HRESULT;

begin
  bi:=CreateComObject(CLSID_BackgroundCopyManager) as IBackgroundCopyManager;
  r:=bi.CreateJob('Updatedownload', BG_JOB_TYPE_DOWNLOAD, JobId, job);
  if not Succeeded(r) then
    raise Exception.Create('Create Job Failed');
  r:=Job.AddFile(PWideChar(downloadurl), PWideChar(ziel));
  if not Succeeded(r) then
    raise Exception.Create('Add File Failed');
  // Download starten
  Job.Resume();  

  Params:=Params+' '+GUIDToString(jobId);

  Job2 := Job as IBackgroundCopyJob2;
  Job2.SetNotifyCmdLine(pWideChar(ExeName), PWideChar(Params));
  Job.SetNotifyFlags(BG_NOTIFY_JOB_TRANSFERRED);
end;

class procedure TDownloadBits.DownloadForground(ziel, downloadurl: widestring; DownloadFeedback:TDownloadProgressEvent);
var
  bi: IBackgroundCopyManager;
  job: IBackgroundCopyJob;
  er: IBackgroundCopyError;
  jobId: TGUID;
  r: HRESULT;

  // Status Zeug
  p: BG_JOB_PROGRESS;
  statusCode: BG_JOB_STATE;

  // Timer Zeug
  hTimer: THandle;
  DueTime: TLargeInteger;
  c: boolean;
  errorContextDescription,
  errorDescription: LPWSTR;
begin
  bi:=CreateComObject(CLSID_BackgroundCopyManager) as IBackgroundCopyManager;
  r:=bi.CreateJob('Updatedownload', BG_JOB_TYPE_DOWNLOAD, JobId, job);
  if not Succeeded(r) then
    raise Exception.Create('Create Job Failed');
  r:=job.AddFile(PWideChar(downloadurl), PWideChar(ziel));
  if not Succeeded(r) then
    raise Exception.Create('Add File Failed');

  job.SetMinimumRetryDelay(1);
  job.SetPriority(BG_JOB_PRIORITY_FOREGROUND);
  job.SetNoProgressTimeout(1);

  // Download starten
  job.Resume();

  DueTime:=-10000000;
  hTimer:=CreateWaitableTimer(nil, false, 'EinTimer');
  try
    SetWaitableTimer(hTimer, DueTime, 1000, nil, nil, false);
    while True do
    begin
      job.GetState(statusCode);

      if statusCode in [BG_JOB_STATE_TRANSFERRING, BG_JOB_STATE_TRANSFERRED] then
      begin
        job.GetProgress(p);
        if assigned(DownloadFeedback) then
        begin
          DownloadFeedback(nil, p.BytesTransferred, p.BytesTotal, dsDownloadingData, '', c);
          if c then
            break;
          end;
      end;

      if statusCode in [BG_JOB_STATE_TRANSFERRED,
        BG_JOB_STATE_ERROR,
        BG_JOB_STATE_TRANSIENT_ERROR] then
          break;

      WaitForSingleObject(hTimer, INFINITE);
    end;
  finally
    CancelWaitableTimer(hTimer);
    CloseHandle(hTimer);
  end;

  case statusCode of
    BG_JOB_STATE_QUEUED: ;
    BG_JOB_STATE_CONNECTING: ;
    BG_JOB_STATE_TRANSFERRING: ;
    BG_JOB_STATE_SUSPENDED: ;

    BG_JOB_STATE_ERROR,
    BG_JOB_STATE_TRANSIENT_ERROR:
      if Succeeded(Job.GetError(er)) then
      begin
        try
          er.GetErrorContextDescription(LANGIDFROMLCID(GetThreadLocale()), errorContextDescription);
          er.GetErrorDescription(LANGIDFROMLCID(GetThreadLocale()), errorDescription);
          job.Cancel;
          raise Exception.Create(errorDescription+#13#10+errorContextDescription);
        finally
          CoTaskMemFree(errorContextDescription);
          CoTaskMemFree(errorDescription);
        end;
      end;
    BG_JOB_STATE_TRANSFERRED: job.Complete();
    BG_JOB_STATE_ACKNOWLEDGED: ;
    BG_JOB_STATE_CANCELLED: ;
  end;

  job:=nil;
  bi:=nil;
end;

end.
