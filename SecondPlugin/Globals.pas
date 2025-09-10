unit Globals;

interface

uses System.SysUtils, System.IOUtils, PluginHostApi;

type

  TArchiveParams = record
  private
    const CommandExe = 'tar.exe';
    function GetCommandLine: string;
  public
    TargetFileName: string;
    SourcePath: string;
    DetailedReport: Boolean;
    property CommandLine: string read GetCommandLine;
    function IsValid (out ErrorMessage: string): Boolean;
  end;

  TGlobals = class
  public
    class var Host: IHost;
    class var Plugin: IPlugin;
  end;

implementation

{ TArchiveParams }

function TArchiveParams.GetCommandLine: string;
begin
  Result := CommandExe;
  if FileExists(TargetFileName) then
    Result := Result + ' -r'
  else
    Result := Result + ' -c';
  if DetailedReport then
    Result := Result + ' -v';
  Result := Result + ' -f';
  Result := Result + ' ' + AnsiQuotedStr(TargetFileName, '"');
  Result := Result + ' ' + AnsiQuotedStr(SourcePath, '"');
end;

function TArchiveParams.IsValid(out ErrorMessage: string): Boolean;
begin
  ErrorMessage := '';
  if Trim(TargetFileName) = '' then
  begin
    ErrorMessage := 'Не указано имя архива';
    Exit (False);
  end;
  if not TPath.HasValidPathChars(TargetFileName, False) then
  begin
    ErrorMessage := 'Неверное имя архива';
    Exit (False);
  end;

  if Trim(SourcePath) = '' then
  begin
    ErrorMessage := 'Не указан файл или папка для архивирования';
    Exit (False);
  end;
  if not TPath.HasValidPathChars(SourcePath, True) then
  begin
    ErrorMessage := 'Неверное имя файла или папки для архивирования';
    Exit (False);
  end;

  Result := True;
end;

end.
