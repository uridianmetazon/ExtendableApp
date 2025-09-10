library SecondPlugin;

uses
  System.SysUtils,
  System.Classes,
  PluginHostApi in '..\API\PluginHostApi.pas',
  PluginBase in '..\Base\PluginBase.pas',
  SecondPluginImpl in 'SecondPluginImpl.pas',
  Globals in 'Globals.pas',
  fArchiveParams in 'fArchiveParams.pas' {frmArchiveParams};

{$R *.res}

function HelloPlugin (aHost: IHost): IPlugin; safecall;
begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF DEBUG}
  TGlobals.Host := aHost;
  TGlobals.Plugin := TCommandLinePlugin.Create(aHost.NextIdentity);
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
