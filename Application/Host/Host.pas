unit Host;

interface

uses System.SysUtils, System.Classes, System.Generics.Collections, Data.DB, FireDAC.Comp.Client,
    System.Diagnostics, System.SyncObjs, Winapi.Windows, System.Messaging,
    PluginManager, PluginHostApi;

type
  TSupportedResult = (srInteger, srStrings);
  TSupportedResults = set of TSupportedResult;

  TSomeResult = class
    FName: string;
  public
    property Name: string read FName;
    procedure Retrieve; virtual; abstract;
  end;

  TIntegerResult = class (TSomeResult)
  private
    FExternalResult: IIntegerResult;
    FValue: Integer;
  public
    constructor Create (ExternalResult: IIntegerResult); reintroduce;
    procedure Retrieve; override;
    property Value: Integer read FValue;
  end;

  TStringsResult = class (TSomeResult)
  private
    FExternalResult: IStringsResult;
    FValue: TDataSet;
    FQueueSize: Integer;
  public
    constructor Create (ExternalResult: IStringsResult); reintroduce;
    destructor Destroy; override;
    procedure Retrieve; override;
    property Value: TDataSet read FValue;
    property QueueSize: Integer read FQueueSize write FQueueSize;
    procedure IncQueueSize;
    procedure DecQueueSize;
  end;

  TLogItemInternal = record
    Moment: TDateTime;
    Text: string;
    constructor Create ([ref] const ALogItem: TLogItem);
  end;

  TTask = class;

  TReceiver = class (TInterfacedObject, IInterface)
  private
    FOwner: TTask;
  public
    constructor Create (AOwner: TTask); reintroduce;
  end;

  TResultChangesReceiver = class (TReceiver, IResultChangesReceiver)
    procedure NotifyResultChanged (const TaskId: TIdentity); safecall;
  end;

  TLogReceiver = class (TReceiver, ILogReceiver)
    procedure PostLogItem ([ref] const Item: TLogItem); safecall;
  end;

  TTask = class
  private
    const MinThreadQueueIntervalTicks = 100000;
  private
    FExternalTask: ITask;
    FTaskId: TIdentity;
    FSessionId: TIdentity;
    FName: string;
    FState: TTaskState;
    FStartMoment: TDateTime;
    FFinishMoment: TDateTime;
    FDetails: string;
    FSupportedResults: TSupportedResults;
    FIntegerResult: TIntegerResult;
    FStringsResult: TStringsResult;
    FLog: TDataSet;
    //FLastMainThreadQueueTick: Int64;
    FLogBuffer: TList<TLogItemInternal>;
    FResultChangesReceiver: IResultChangesReceiver;
    FLogReceiver: ILogReceiver;
    FLastLogMessage: string;
    FLogQueueSize: Integer;
    procedure SetState (const NewState: TTaskState);
    procedure CreateLog;
    procedure DefineSupportedResults;
  public
    constructor Create (AExternalTask: ITask; ASessionId: TIdentity); reintroduce;
    destructor Destroy; override;
    procedure Execute;
    procedure Cancel;
    function RetrieveResults (Immediate: Boolean = False): Boolean;
    procedure ReleaseExternalLinks;
    function AddLogItem ([ref] const ALogItem: TLogItem): Boolean;
    procedure ProcessLogBuffer;
    procedure NotityStateChanged;
    function ResultToString: string;
    property TaskId: TIdentity read FTaskId write FTaskId;
    property SessionId: TIdentity read FSessionId write FSessionId;
    property Name: string read FName write FName;
    property State: TTaskState read FState write SetState;
    property StartMoment: TDateTime read FStartMoment write FStartMoment;
    property FinishMoment: TDateTime read FFinishMoment write FFinishMoment;
    property Details: string read FDetails write FDetails;
    property SupportedResults: TSupportedResults read FSupportedResults write FSupportedResults;
    property Log: TDataSet read FLog;
    property LastLogMessage: string read FLastLogMessage;
    property StringsResult: TStringsResult read FStringsResult;
  end;

  TTaskStateChanged = type TTask;
  TTaskResultChanged = type TTask;
  TTaskLogPosted = type TTask;

  TTaskList = class (TObjectList<TTask>)
  public
    function FindByTaskId(const ATaskId: TIdentity): TTask;
  end;

  IHostInternal = interface (IHost)
    procedure SetMainWindowHandle (const Value: HWND);
    function GetTasks: TTaskList;
    function GetActiveTasks: TTaskList;
    function GetFinishedTasks: TTaskList;
    property MainWindowHandle: HWND read GetMainWindowHandle write SetMainWindowHandle;
    property Tasks: TTaskList read GetTasks;
    property ActiveTasks: TTaskList read GetActiveTasks;
    property FinishedTasks: TTaskList read GetFinishedTasks;
    procedure RegisterAndLaunchNewTask (const NewTask: TTask);
    procedure DetachSession (const ASessionId: TIdentity);
  end;

  TAutoincFunction = reference to function: TIdentity;

  THost = class (TInterfacedObject, IHost, IHostInternal, IStateChangesReceiver)
  private
    FAutoinc: TAutoincFunction;
    FMainWindowHandle: HWND;
    FTasks: TTaskList;
    FActiveTasks: TTaskList;
    FFinishedTasks: TTaskList;
    function GetMainWindowHandle: HWND; safecall;
    procedure SetMainWindowHandle (const Value: HWND);
    function GetTasks: TTaskList;
    function GetActiveTasks: TTaskList;
    function GetFinishedTasks: TTaskList;
    procedure OnPluginNotify (Sender: TObject; const Item: TPlugin; Action: TCollectionNotification);
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
    function NextIdentity: TIdentity; safecall;
    property MainWindowHandle: HWND read GetMainWindowHandle write SetMainWindowHandle;
    property Tasks: TTaskList read GetTasks;
    property ActiveTasks: TTaskList read GetActiveTasks;
    property FinishedTasks: TTaskList read GetFinishedTasks;
    procedure RegisterAndLaunchNewTask (const NewTask: TTask);
    procedure DetachSession (const ASessionId: TIdentity);
    procedure NotifyStateChanged (const TaskId: TIdentity); safecall;
  end;

function DefaultHost: IHostInternal;
function MessageAsTask (const AMessage: TMessage): TTask;


implementation

var
  g_HostSingleton: IHostInternal;

function DefaultHost: IHostInternal;
begin
  if not Assigned(g_HostSingleton) then
    g_HostSingleton := THost.Create;
  Result := g_HostSingleton;
end;

function MessageAsTask (const AMessage: TMessage): TTask;
begin
  if AMessage is TMessage<TTaskStateChanged> then
    Result := TTask((AMessage as TMessage<TTaskStateChanged>).Value)
  else
  if AMessage is TMessage<TTaskResultChanged> then
    Result := TTask((AMessage as TMessage<TTaskResultChanged>).Value)
  else
  if AMessage is TMessage<TTaskLogPosted> then
    Result := TTask((AMessage as TMessage<TTaskLogPosted>).Value)
  else
    Result := nil;
end;

{ TTask }

constructor TTask.Create(AExternalTask: ITask; ASessionId: TIdentity);
begin
  FExternalTask := AExternalTask;
  FSessionId := ASessionId;
  FTaskId := FExternalTask.TaskId;
  FName := FExternalTask.Name;
  FState := FExternalTask.State;
  FStartMoment := FExternalTask.StartMoment;
  FFinishMoment := FExternalTask.FinishMoment;
  FDetails := FExternalTask.Details;
  DefineSupportedResults;
  CreateLog;
  FLogBuffer := TList<TLogItemInternal>.Create;
  FResultChangesReceiver := TResultChangesReceiver.Create(Self);
  FExternalTask.ResultChangesReceiver := FResultChangesReceiver;
  FLogReceiver := TLogReceiver.Create(Self);
  FExternalTask.LogReceiver := FLogReceiver;
  FLogQueueSize := 0;
end;

procedure TTask.CreateLog;
begin
  FLog := TFDMemTable.Create(nil);
  with FLog do
  begin
    with FieldDefs.AddFieldDef do
    begin
      Name := 'Moment';
      DataType := ftDateTime;
    end;
    with FieldDefs.AddFieldDef do
    begin
      Name := 'Text';
      DataType := ftString;
      Size := 2000;
    end;
    Open;
    (Fields[0] as TDateTimeField).DisplayFormat := 'yyyy-mm-dd hh:nn:ss.zzz';
  end;
end;

procedure TTask.DefineSupportedResults;
var
  I: IIntegerResult;
  S: IStringsResult;
begin
  if Supports (FExternalTask.Result, IIntegerResult, I) then
  begin
    Include (FSupportedResults, srInteger);
    FIntegerResult := TIntegerResult.Create(I);
  end;
  if Supports (FExternalTask.Result, IStringsResult, S) then
  begin
    Include (FSupportedResults, srStrings);
    FStringsResult := TStringsResult.Create(S);
  end;
end;

destructor TTask.Destroy;
begin
  ReleaseExternalLinks;
  FreeAndNil(FLog);
  FreeAndNil(FIntegerResult);
  FreeAndNil(FStringsResult);
  FreeAndNil(FLogBuffer);
  inherited;
end;

procedure TTask.Execute;
begin
  var ExTask := FExternalTask;
  if Assigned(ExTask) and ExTask.State.IsStartable then
    ExTask.Execute;
end;

procedure TTask.NotityStateChanged;
begin
  State := FExternalTask.State;
end;

procedure TTask.ProcessLogBuffer;
begin
  TInterlocked.Decrement(FLogQueueSize);
  if FLogBuffer.Count <= 0 then
    Exit;
  TMonitor.Enter(FLogBuffer);
  try
    FLog.DisableControls;
    try
      for var Item in FLogBuffer do
        FLog.AppendRecord([Item.Moment, Item.Text]);
      if FLog.RecordCount > 0 then
        FLastLogMessage := FLog.FieldByName('Text').AsString;
    finally
      FLog.EnableControls;
    end;
    FLogBuffer.Clear;
  finally
    TMonitor.Exit(FLogBuffer);
  end;
end;

procedure TTask.ReleaseExternalLinks;
begin
  var ExTask := FExternalTask;
  if Assigned(ExTask) then
  begin
    Cancel;
    if not State.IsFinal then
      Sleep(1);
    FExternalTask := nil;
    if Assigned(FIntegerResult) then
      FIntegerResult.FExternalResult := nil;
    if Assigned(FStringsResult) then
      FStringsResult.FExternalResult := nil;
  end;
end;

function TTask.ResultToString: string;
begin
  if srInteger in FSupportedResults then
    Result := Format ('%s: %d', [FIntegerResult.Name, FIntegerResult.Value])
  else
    if Log.RecordCount > 0 then
      Result := LastLogMessage;
end;

function TTask.RetrieveResults(Immediate: Boolean): Boolean;
const
  SomeValue = 500;
begin
  if Assigned(FStringsResult)
    and (FStringsResult.FExternalResult.Value.Count - FStringsResult.Value.RecordCount >= SomeValue) then
      Immediate := True;
  if not Immediate then
    Exit(False);

  if Assigned(FIntegerResult) then
    FIntegerResult.Retrieve;
  TInterlocked.Exchange(Double(FStartMoment), Double(FExternalTask.StartMoment));
  TInterlocked.Exchange(Double(FFinishMoment), Double(FExternalTask.FinishMoment));

  if Assigned(FStringsResult) then
    if State.IsFinal or (FStringsResult.QueueSize > 1) then
    begin
      FStringsResult.IncQueueSize;
      TThread.Synchronize(nil, FStringsResult.Retrieve)
    end
    else
    begin
      FStringsResult.IncQueueSize;
      TThread.Queue(nil, FStringsResult.Retrieve);
    end;
  Result := True;
end;

procedure TTask.SetState(const NewState: TTaskState);
begin
  FState := NewState;
  if NewState.IsFinal then
  begin
    TInterlocked.Increment(FLogQueueSize);
    TThread.Synchronize(nil, ProcessLogBuffer);
    RetrieveResults(True);
    ReleaseExternalLinks;
  end
  else
    FStartMoment := FExternalTask.StartMoment;
end;

function TTask.AddLogItem([ref]const ALogItem: TLogItem): Boolean;
const
  CriticalSize = 1000;
begin
  TMonitor.Enter(FLogBuffer);
  try
    FLogBuffer.Add(TLogItemInternal.Create(ALogItem));
  finally
    TMonitor.Exit(FLogBuffer)
  end;
  if FLogBuffer.Count >= CriticalSize then
  begin
    TInterlocked.Increment(FLogQueueSize);
    TThread.Synchronize(nil, ProcessLogBuffer);
    Exit (True);
  end;
  if (FLogQueueSize < 2) then
  begin
    TInterlocked.Increment(FLogQueueSize);
    TThread.Queue(nil, ProcessLogBuffer);
    Exit (True);
  end;
  Result := False;
end;

procedure TTask.Cancel;
begin
  var ExTask := FExternalTask;
  if Assigned(ExTask) and ExTask.State.IsCancelable then
    ExTask.Cancel;
end;

{ TIntegerResult }

constructor TIntegerResult.Create(ExternalResult: IIntegerResult);
begin
  FExternalResult := ExternalResult;
  FName := FExternalResult.Name;
  FValue := FExternalResult.Value;
end;

procedure TIntegerResult.Retrieve;
begin
  var Ex := FExternalResult;
  if Assigned (Ex) then
    TInterlocked.Exchange(FValue, Ex.Value);
end;

{ TStringsResult }

constructor TStringsResult.Create(ExternalResult: IStringsResult);
begin
  FExternalResult := ExternalResult;
  FName := FExternalResult.Name;
  FValue := TFDMemTable.Create(nil);
  FValue.FieldDefs.Add('Text', ftString, 2000);
  FValue.Open;
end;

procedure TStringsResult.DecQueueSize;
begin
  TInterlocked.Decrement(FQueueSize);
end;

destructor TStringsResult.Destroy;
begin
  FreeAndNil(FValue);
  inherited;
end;

procedure TStringsResult.IncQueueSize;
begin
  TInterlocked.Increment(FQueueSize);
end;

procedure TStringsResult.Retrieve;
begin
  DecQueueSize;
  var Ex := FExternalResult;
  if Assigned(Ex) then
  try
    FValue.DisableControls;
    for var i := FValue.RecordCount to Ex.Value.Count - 1 do  // считываютс€ только новые строки
      FValue.AppendRecord([Ex.Value[i]]);
  finally
    FValue.EnableControls;
  end;
end;

{ TLogItemInternal }

constructor TLogItemInternal.Create([ref] const ALogItem: TLogItem);
begin
  Self.Moment := ALogItem.Moment;
  Self.Text := ALogItem.Text;
end;

{ TTaskList }

function TTaskList.FindByTaskId(const ATaskId: TIdentity): TTask;
begin
  for Result in Self do
    if Result.TaskId = ATaskId then
      Exit;
  Result := nil;
end;

function CreateAutoinc (Start, Increment: TIdentity): TAutoincFunction;
var
  LastValue: TIdentity;
begin
  LastValue := Start - Increment;
  Result :=
    function: TIdentity
    begin
      Result := AtomicIncrement(LastValue, Increment);
    end;
end;

{ THost }

constructor THost.Create;
begin
  FAutoinc := CreateAutoinc(1, 1);
  FTasks := TTaskList.Create(True);
  FActiveTasks := TTaskList.Create(False);
  FFinishedTasks := TTaskList.Create(False);
  TPluginManager.Default.OnNotify := OnPluginNotify;
end;

destructor THost.Destroy;
begin
  FreeAndNil(FFinishedTasks);
  FreeAndNil(FActiveTasks);
  FreeAndNil(FTasks);
  inherited;
end;

procedure THost.DetachSession(const ASessionId: TIdentity);
begin
  for var Task in FTasks do
    if Task.SessionId = ASessionId then
      Task.ReleaseExternalLinks;
end;

function THost.GetActiveTasks: TTaskList;
begin
  Result := FActiveTasks;
end;

function THost.GetFinishedTasks: TTaskList;
begin
  Result := FFinishedTasks;
end;

function THost.GetMainWindowHandle: HWND;
begin
  Result := FMainWindowHandle;
end;

function THost.GetTasks: TTaskList;
begin
  Result := FTasks;
end;

function THost.NextIdentity: TIdentity;
begin
  Result := FAutoinc();
end;

procedure THost.NotifyStateChanged(const TaskId: TIdentity);
begin
  var Task := FActiveTasks.FindByTaskId(TaskId);
  Assert(Assigned(Task), '“аска не найдена в THost.NotifyStateChanged');
  if not Assigned(Task) then
    Exit;
  Task.NotityStateChanged;
  TThread.Synchronize(nil,
    procedure
    begin
      if Task.State.IsFinal then
        if FActiveTasks.Remove(Task) >= 0 then
          FFinishedTasks.Add(Task);
      TMessageManager.DefaultManager.SendMessage(nil, TMessage<TTaskStateChanged>.Create(TTaskStateChanged(Task)));
    end);
end;

procedure THost.OnPluginNotify(Sender: TObject; const Item: TPlugin; Action: TCollectionNotification);
begin
  case Action of
    cnAdded: TMessageManager.DefaultManager.SendMessage(nil, TMessage<TMessagePlugin>.Create(TMessagePlugin.Create(Item, True)));
    cnRemoved:
      begin
        DetachSession(Item.SessionId);
        TMessageManager.DefaultManager.SendMessage(nil, TMessage<TMessagePlugin>.Create(TMessagePlugin.Create(Item, False)));
      end;
  end;
end;

procedure THost.RegisterAndLaunchNewTask(const NewTask: TTask);
begin
  NewTask.FExternalTask.StateChangesReceiver := Self;
  // register
  FTasks.Add(NewTask);
  FActiveTasks.Add(NewTask);
  // launch
  TThread.CreateAnonymousThread(NewTask.Execute).Start;
end;

procedure THost.SetMainWindowHandle(const Value: HWND);
begin
  FMainWindowHandle := Value;
end;

{ TReceiver }

constructor TReceiver.Create(AOwner: TTask);
begin
  FOwner := AOwner;
end;

{ TResultChangesReveiver }

procedure TResultChangesReceiver.NotifyResultChanged(const TaskId: TIdentity);
begin
  if FOwner.RetrieveResults then
  TThread.Queue(nil,
    procedure
    begin
      TMessageManager.DefaultManager.SendMessage(nil, TMessage<TTaskResultChanged>.Create(TTaskResultChanged(FOwner)));
    end
  );
end;

{ TLogReceiver }

procedure TLogReceiver.PostLogItem([ref]const Item: TLogItem);
begin
  if FOwner.AddLogItem(Item) then
  TThread.Queue(nil,
    procedure
    begin
      TMessageManager.DefaultManager.SendMessage(nil, TMessage<TTaskLogPosted>.Create(TTaskLogPosted(FOwner)));
    end
  )
end;

end.
