unit uc_updatecheck;

interface

const
  c_updateurl = 'https://github.com/codingbott/OnlineUpdatesDelphi/server/serverinfo.xml';

type
  TUpdateInfo = record
    version, url, text: string;
  end;

  TUpdateCheck = class
  public
    class function checkForUpdate():TUpdateInfo;
  end;

implementation

uses
  Variants,
  SysUtils,
  MSXML2_TLB;

{ TUpdateCheck }

class function TUpdateCheck.checkForUpdate(): TUpdateInfo;
var
  req : IXMLHTTPRequest;
  i: IDispatch;
  xi: IXMLDOMDocument;
  xel: IXMLDOMNodeList;
begin
  req := CoXMLHTTP40.Create;
  try
    req.Open('GET', c_updateurl, False, EmptyParam, EmptyParam);

    req.send(EmptyParam);
    if req.status<>200 then
      raise Exception.Create('Pr�fung fehlgeschlagen');

    i:=req.Get_responseXML();
    if i.QueryInterface(IXMLDOMDocument, xi) = S_OK then
    begin
      xel:=xi.getElementsByTagName('currentversion');
      result.version:=xel.item[0].text;
      xel:=xi.getElementsByTagName('currentdownloadurl');
      result.url:=xel.item[0].text;
      xel:=xi.getElementsByTagName('currentinfo');
      result.text:=xel.item[0].text;
    end;

  finally
    i:=nil;
    xel:=nil;
    req:=nil;
  end;
end;

end.
