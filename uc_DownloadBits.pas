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
  jobId: TGUID;
  r: HRESULT;

  // Status Zeug
  p: BG_JOB_PROGRESS;
  s: BG_JOB_STATE;
  
  // Timer Zeug
  hTimer: THandle;
  DueTime: TLargeInteger;
  c: boolean;
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

  DueTime:=-10000000;
  hTimer:=CreateWaitableTimer(nil, false, 'EinTimer');
  SetWaitableTimer(hTimer, DueTime, 1000, nil, nil, false);
  while True do
  begin
    Job.GetState(s);

    if s in [BG_JOB_STATE_TRANSFERRING, BG_JOB_STATE_TRANSFERRED] then
    begin
      Job.GetProgress(p);
      DownloadFeedback(nil, p.BytesTransferred, p.BytesTotal, dsDownloadingData, '', c);
      if c then
        break;
    end;

    if s in [BG_JOB_STATE_TRANSFERRED,
      BG_JOB_STATE_ERROR,
      BG_JOB_STATE_TRANSIENT_ERROR] then
        break;

    WaitForSingleObject(hTimer, INFINITE);
  end;
  CancelWaitableTimer(hTimer);
  CloseHandle(hTimer);
  if s=BG_JOB_STATE_TRANSFERRED then
    job.Complete();

  job:=nil;
  bi:=nil;
end;

end.
