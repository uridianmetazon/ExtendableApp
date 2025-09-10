library FirstPlugin;

uses
  System.SysUtils,
  System.Classes,
  fSearchFilesParams in 'fSearchFilesParams.pas' {frmSearchFilesParams},
  Globals in 'Globals.pas',
  PluginHostApi in '..\API\PluginHostApi.pas',
  PluginBase in '..\Base\PluginBase.pas',
  FirstPluginImpl in 'FirstPluginImpl.pas',
  fSearchSubstringParams in 'fSearchSubstringParams.pas' {frmSearchSubstringParams};

{$R *.res}

function HelloPlugin (aHost: IHost): IPlugin; safecall;
begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF DEBUG}
  TGlobals.Host := aHost;
  TGlobals.Plugin := TSearchPlugin.Create(aHost.NextIdentity);
  Result := TGlobals.Plugin;
end;

procedure GoodbyePlugin; safecall;
begin
  TGlobals.Plugin := nil;
  TGlobals.Host := nil;
end;

exports
  HelloPlugin,
  GoodbyePlugin;
begin

end.
