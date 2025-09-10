unit fAsyncOperationList;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.DBCGrids, Vcl.ControlList,
  Vcl.ExtCtrls, Vcl.StdCtrls, System.Messaging, Host, PluginHostAPI,
  Vcl.ComCtrls, Data.DB, Vcl.Grids, Vcl.DBGrids;

type
  TfrmAsyncOperationList = class(TForm)
    ControlList: TControlList;
    lblOperationName: TLabel;
    FilterPanel: TPanel;
    lblOperationState: TLabel;
    Filter: TRadioGroup;
    LogPanel: TPanel;
    Splitter1: TSplitter;
    lblDetails: TLabel;
    lblStartMoment: TLabel;
    lblFinishMoment: TLabel;
    lblResult: TLabel;
    btCancel: TControlListButton;
    btShowLog: TControlListButton;
    btShowResult: TControlListButton;
    TabControl: TTabControl;
    grdLog: TDBGrid;
    dsLog: TDataSource;
    grdResultStrings: TDBGrid;
    dsResultStrings: TDataSource;
    lblRowCount: TLabel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure ControlListShowControl(const AIndex: Integer;
      AControl: TControl; var AVisible: Boolean);
    procedure FilterClick(Sender: TObject);
    procedure btCancelClick(Sender: TObject);
    procedure TabControlChange(Sender: TObject);
    procedure btShowLogClick(Sender: TObject);
    procedure btShowResultClick(Sender: TObject);
  private
    FTasks: TTaskList;
    FControlArray: array of TControl;
    FCurrentSourceIndex: NativeInt;
    FLogEventSubscriptionId: Int64;
    FTaskStateSubscriptionId: Int64;
    FTaskResultSubscriptionId: Int64;
    procedure LogEventListener (const Sender: TObject; const M: TMessage);
    procedure TaskStateListener (const Sender: TObject; const M: TMessage);
    procedure TaskResultListener (const Sender: TObject; const M: TMessage);
    procedure ShowFooter;
  public
  end;

var
  frmAsyncOperationList: TfrmAsyncOperationList;

implementation

{$R *.dfm}

procedure TfrmAsyncOperationList.TabControlChange(Sender: TObject);
begin
  ShowFooter;
end;

procedure TfrmAsyncOperationList.TaskResultListener(const Sender: TObject; const M: TMessage);
begin
  if Assigned(MessageAsTask(M)) then
    ControlList.Repaint;
end;

procedure TfrmAsyncOperationList.TaskStateListener(const Sender: TObject; const M: TMessage);
begin
  ControlList.ItemCount := FTasks.Count;
end;

procedure TfrmAsyncOperationList.btCancelClick(Sender: TObject);
begin
  try
    FTasks[ControlList.ItemIndex].Cancel;
  except
    ControlList.ItemCount := FTasks.Count;
  end;
end;

procedure TfrmAsyncOperationList.btShowLogClick(Sender: TObject);
var
  Task: TTask;
begin
  try
    Task := FTasks[ControlList.ItemIndex];
    dsLog.DataSet := Task.Log;
    TabControl.TabIndex := 0;
    ShowFooter;
  except
    ControlList.ItemCount := FTasks.Count;
  end;
end;

procedure TfrmAsyncOperationList.btShowResultClick(Sender: TObject);
var
  Task: TTask;
begin
  try
    Task := FTasks[ControlList.ItemIndex];
    if srStrings in Task.SupportedResults then
    begin
      dsResultStrings.DataSet := Task.StringsResult.Value;
      grdResultStrings.Columns[0].Title.Caption := Task.StringsResult.Name;
    end
    else
    begin
      dsResultStrings.DataSet := nil;
      grdResultStrings.Columns[0].Title.Caption := 'Не поддерживается';
    end;
    TabControl.TabIndex := 1;
    ShowFooter;
  except
    ControlList.ItemCount := FTasks.Count;
  end;
end;

procedure TfrmAsyncOperationList.ControlListShowControl(const AIndex: Integer; AControl: TControl; var AVisible: Boolean);
var
  Task: TTask;
begin
  try
    Task := FTasks[AIndex];
    case TArray.IndexOf<TControl>(FControlArray, AControl) of
      0: lblOperationName.Caption := Format ('Задача (id=%d): %s', [Task.TaskId, Task.Name]);
      1: lblOperationState.Caption := 'Статус: ' + Task.State.ToString;
      2: lblStartMoment.Caption := 'Запущено в: ' + FormatDateTime('hh:nn:ss.zzz', Task.StartMoment);
      3: lblFinishMoment.Caption := 'Завершено в: ' + FormatDateTime('hh:nn:ss.zzz', Task.FinishMoment);
      4: lblResult.Caption := Task.ResultToString;
      5: lblDetails.Caption := 'Подробно: ' + Task.Details;
      6: btCancel.Enabled := Task.State.IsCancelable;
      7:;
      8:;
    end;
  except
    ControlList.ItemCount := FTasks.Count;
  end;
end;

procedure TfrmAsyncOperationList.ShowFooter;
begin
  if TabControl.TabIndex = 0 then
  begin
    grdLog.BringToFront;
    if Assigned(grdLog.DataSource.DataSet) then
      lblRowCount.Caption := Format('Строк: %d', [grdLog.DataSource.DataSet.RecordCount])
    else
      lblRowCount.Caption := '';
  end
  else
  begin
    grdResultStrings.BringToFront;
    if Assigned(grdResultStrings.DataSource.DataSet) then
      lblRowCount.Caption := Format('Строк: %d', [grdResultStrings.DataSource.DataSet.RecordCount])
    else
      lblRowCount.Caption := '';
  end;
end;

procedure TfrmAsyncOperationList.FilterClick(Sender: TObject);
begin
  try
    if Filter.ItemIndex = FCurrentSourceIndex then
      Exit;
    ControlList.LockDrawing;
    try
      if Filter.ItemIndex < 0 then
        Filter.ItemIndex := 0;
      FCurrentSourceIndex := Filter.ItemIndex;
      case FCurrentSourceIndex of
        0: FTasks := DefaultHost.ActiveTasks;
        1: FTasks := DefaultHost.FinishedTasks;
      end;
      ControlList.ItemCount := FTasks.Count;
    finally
      ControlList.UnlockDrawing;
    end;
  except on E: Exception do
  end;
end;

procedure TfrmAsyncOperationList.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
  TMessageManager.DefaultManager.Unsubscribe(TMessage <TTaskLogPosted>, FLogEventSubscriptionId);
  TMessageManager.DefaultManager.Unsubscribe(TMessage <TTaskStateChanged>, FTaskStateSubscriptionId);
  TMessageManager.DefaultManager.Unsubscribe(TMessage <TTaskResultChanged>, FTaskResultSubscriptionId);
end;

procedure TfrmAsyncOperationList.FormCreate(Sender: TObject);
begin
  FControlArray := [lblOperationName, lblOperationState, lblStartMoment, lblFinishMoment, lblResult, lblDetails, btCancel, btShowLog, btShowResult];
  with TMessageManager.DefaultManager do
  begin
    FLogEventSubscriptionId := SubscribeToMessage(TMessage <TTaskLogPosted>, Self.LogEventListener);
    FTaskStateSubscriptionId := SubscribeToMessage(TMessage <TTaskStateChanged>, Self.TaskStateListener);
    FTaskResultSubscriptionId := SubscribeToMessage(TMessage<TTaskResultChanged>, Self.TaskResultListener);
  end;
  FCurrentSourceIndex := -1;
  FilterClick(nil);
end;

procedure TfrmAsyncOperationList.LogEventListener(const Sender: TObject; const M: TMessage);
begin
  if Assigned(MessageAsTask(M)) then
    ControlList.Repaint;
end;

end.
