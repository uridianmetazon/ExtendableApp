program ExtendableApp;

uses
  Vcl.Forms,
  Host in 'Host\Host.pas',
  PluginManager in 'Host\PluginManager.pas',
  fAsyncOperationList in 'Forms\fAsyncOperationList.pas' {frmAsyncOperationList},
  fMain in 'Forms\fMain.pas' {frmMain},
  PluginHostApi in '..\API\PluginHostApi.pas';

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF DEBUG}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
