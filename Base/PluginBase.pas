unit PluginBase;

interface

uses System.SysUtils, System.Generics.Collections, System.SyncObjs, PluginHostApi;

type
  TActionBase = class abstract (TInterfacedObject, IAction)
  strict protected
    FName: WideString;
    function GetName: WideString; safecall;
    procedure SetName (const Value: WideString); safecall;
    function Execute: ITask; virtual; safecall; abstract;
    property Name: WideString read FName write FName;
  public
    constructor Create (const AName: string); reintroduce;
  end;

  IListInternal<T> = interface (IList<T>)
    procedure SetItem (Index: Integer; const Item: T);
    property Items[Index: Integer]: T read GetItem write SetItem; default;
    function Add (const Item: T): Integer;
  end;

  TListInternal<TItem> = class (TInterfacedObject, IListInternal<TItem>, IList<TItem>)
  strict protected
    FInnerList: TList<TItem>;
    function GetCount: Integer; safecall;
    function GetItem(Index: Integer): TItem; safecall;
    procedure SetItem (Index: Integer; const Item: TItem);
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TItem read GetItem write SetItem; default;
    function Add (const Item: TItem): Integer;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
  end;

  TStringsInternal = class (TListInternal<WideString>, IStrings)
  end;

  TActionList = class (TListInternal<IAction>, IActions)
  end;

  IPluginInternal = interface (IPlugin)
    procedure SetSessionId (const Value: TIdentity); safecall;
    procedure SetName (const Value: WideString); safecall;
    property SessionId: TIdentity read GetSessionId write SetSessionId;
    property Name: Widestring read GetName write SetName;
  end;

  TPluginBase = class (TInterfacedObject, IPlugin, IPluginInternal)
  strict protected
    FSessionId: TIdentity;
    FName: WideString;
    FActionList: IListInternal<IAction>;
    function GetSessionId: TIdentity; safecall;
    procedure SetSessionId (const Value: TIdentity); safecall;
    function GetName: Widestring; safecall;
    procedure SetName (const Value: WideString); safecall;
    function GetActions: IActions; safecall;
    property SessionId: TIdentity read GetSessionId write SetSessionId;
    property Name: Widestring read GetName write SetName;
    property Actions: IActions read GetActions;
  public
    constructor Create (ASessionId: TIdentity); virtual;
  end;

  TInterfacedResult = class (TInterfacedObject, IResult)
  strict protected
    FName: string;
    function GetName: WideString; safecall;
  public
    constructor Create (const AName: string); virtual;
    property Name: WideString read GetName;
  end;

  TAggregatedResult = class (TAggregatedObject, IResult)
  strict protected
    FName: string;
    function GetName: WideString; safecall;
  public
    constructor Create (const AName: string); virtual;
    property Name: WideString read GetName;
  end;

  ITaskInternal = interface (ITask)
    procedure SetTaskId (const Value: TIdentity);
    procedure SetSessionId (const Value: TIdentity);
    procedure SetName (const Value: WideString);
    procedure SetState (const NewState: TTaskState);
    procedure SetStartMoment (const Moment: TDateTime);
    procedure SetFinishMoment (const Moment: TDateTime);

    property TaskId: TIdentity read GetTaskId write SetTaskId;
    property SessionId: TIdentity read GetSessionId write SetSessionId;
    property Name: WideString read GetName write SetName;
    property State: TTaskState read GetState write SetState;
    property StartMoment: TDateTime read GetStartMoment write SetStartMoment;
    property FinishMoment: TDateTime read GetFinishMoment write SetFinishMoment;
  end;

  TTaskBase = class abstract (TInterfacedObject, ITask, ITaskInternal)
  strict protected
    FTaskId: TIdentity;
    FSessionId: TIdentity;
    FName: WideString;
    FState: TTaskState;
    FStartMoment: TDateTime;
    FFinishMoment: TDateTime;
    FLogReceiver: ILogReceiver;
    FStateChangesReceiver: IStateChangesReceiver;
    FResultChangesReceiver: IResultChangesReceiver;
    function GetTaskId: TIdentity; safecall;
    function GetSessionId: TIdentity; safecall;
    function GetName: WideString; safecall;
    function GetDetails: Widestring; virtual; safecall; abstract;
    function GetState: TTaskState; safecall;
    function GetStartMoment: TDateTime; safecall;
    function GetFinishMoment: TDateTime; safecall;
    procedure SetTaskId (const Value: TIdentity);
    procedure SetSessionId (const Value: TIdentity);
    procedure SetName (const Value: WideString);
    procedure SetState (const NewState: TTaskState);
    procedure SetStartMoment (const Moment: TDateTime);
    procedure SetFinishMoment (const Moment: TDateTime);
    function GetLogReceiver: ILogReceiver; safecall;
    procedure SetLogReceiver (const Receiver: ILogReceiver); safecall;
    function GetStateChangesReceiver: IStateChangesReceiver; safecall;
    procedure SetStateChangesReceiver (const Receiver: IStateChangesReceiver); safecall;
    function GetResultChangesReceiver: IResultChangesReceiver; safecall;
    procedure SetResultChangesReceiver (const Receiver: IResultChangesReceiver); safecall;
    function GetResult: IResult; virtual; safecall; abstract;
    property TaskId: TIdentity read GetTaskId write SetTaskId;
    property SessionId: TIdentity read GetSessionId write SetSessionId;
    property Name: WideString read GetName write SetName;
    property Details: WideString read GetDetails;
    property State: TTaskState read GetState write SetState;
    property StartMoment: TDateTime read GetStartMoment write SetStartMoment;
    property FinishMoment: TDateTime read GetFinishMoment write SetFinishMoment;
    property LogReceiver: ILogReceiver read GetLogReceiver write SetLogReceiver;
    property StateChangesReceiver: IStateChangesReceiver read GetStateChangesReceiver write SetStateChangesReceiver;
    property ResultChangesReceiver: IResultChangesReceiver read GetResultChangesReceiver write SetResultChangesReceiver;
    property Result: IResult read GetResult;
    procedure Execute; virtual; safecall; abstract;
    procedure Cancel; virtual; safecall;
    procedure PostLogMessage (const AText: string); virtual;
    procedure NotifyStateChanged; virtual;
    procedure NotifyResultChanged; virtual;
  public
    constructor Create(ATaskId: TIdentity; AName: WideString); reintroduce;
  end;

implementation

{ TActionBase }

constructor TActionBase.Create(const AName: string);
begin
  FName := AName;
end;

function TActionBase.GetName: WideString;
begin
  Result := FName;
end;

procedure TActionBase.SetName(const Value: WideString);
begin
  FName := Value;
end;

{ TPluginBase }

constructor TPluginBase.Create(ASessionId: TIdentity);
begin
  FSessionId := ASessionId;
  FActionList := TActionList.Create;
end;

function TPluginBase.GetActions: IActions;
begin
  Result := FActionList as IActions;
end;


function TPluginBase.GetName: Widestring;
begin
  Result := FName;
end;

function TPluginBase.GetSessionId: TIdentity;
begin
  Result := FSessionId;
end;

procedure TPluginBase.SetName(const Value: WideString);
begin
  FName := Value;
end;

procedure TPluginBase.SetSessionId(const Value: TIdentity);
begin
  FSessionId := Value;
end;

{ TTaskBase }

procedure TTaskBase.Cancel;
begin
  SetState(Cancelling);
end;

constructor TTaskBase.Create(ATaskId: TIdentity; AName: WideString);
begin
  FTaskId := ATaskId;
  FName := AName;
  FState := WaitingToRun;
end;

function TTaskBase.GetFinishMoment: TDateTime;
begin
  Result := FFinishMoment;
end;

function TTaskBase.GetLogReceiver: ILogReceiver;
begin
  Result := FLogReceiver;
end;

function TTaskBase.GetName: WideString;
begin
  Result := FName;
end;

function TTaskBase.GetResultChangesReceiver: IResultChangesReceiver;
begin
  Result := FResultChangesReceiver;
end;

function TTaskBase.GetSessionId: TIdentity;
begin
  Result := FSessionId;
end;

function TTaskBase.GetStartMoment: TDateTime;
begin
  Result := FStartMoment;
end;

function TTaskBase.GetState: TTaskState;
begin
  Result := FState;
end;

function TTaskBase.GetStateChangesReceiver: IStateChangesReceiver;
begin
  Result := FStateChangesReceiver;
end;

function TTaskBase.GetTaskId: TIdentity;
begin
  Result := FTaskId;
end;

procedure TTaskBase.NotifyResultChanged;
begin
  if Assigned(FResultChangesReceiver) then
    FResultChangesReceiver.NotifyResultChanged(FTaskId);
end;

procedure TTaskBase.NotifyStateChanged;
begin
  if Assigned (FStateChangesReceiver) then
    FStateChangesReceiver.NotifyStateChanged(FTaskId);
end;

procedure TTaskBase.PostLogMessage(const AText: string);
var
  LogItem: TLogItem;
begin
  LogItem.Moment := Now;
  if Assigned (FLogReceiver) then
  begin
    LogItem.TaskId := FTaskId;
    LogItem.Text := AText;
    FLogReceiver.PostLogItem(LogItem);
  end;
end;

procedure TTaskBase.SetFinishMoment(const Moment: TDateTime);
begin
  FFinishMoment := Moment;
end;

procedure TTaskBase.SetLogReceiver(const Receiver: ILogReceiver);
begin
  FLogReceiver := Receiver;
end;

procedure TTaskBase.SetName(const Value: WideString);
begin
  FName := Value;
end;

procedure TTaskBase.SetResultChangesReceiver(const Receiver: IResultChangesReceiver);
begin
  FResultChangesReceiver := Receiver;
end;

procedure TTaskBase.SetSessionId(const Value: TIdentity);
begin
  FSessionId := Value;
end;

procedure TTaskBase.SetStartMoment(const Moment: TDateTime);
begin
  FStartMoment := Moment;
end;

procedure TTaskBase.SetState(const NewState: TTaskState);
var
  Result: Boolean;
begin
  var OldState := FState;
  repeat
    if (OldState = NewState) or OldState.IsFinal then
      Exit;
    OldState := TInterlocked.CompareExchange(FState, NewState, OldState, Result);
  until Result;
  NotifyStateChanged;
end;

procedure TTaskBase.SetStateChangesReceiver(
  const Receiver: IStateChangesReceiver);
begin
  FStateChangesReceiver := Receiver;
end;

procedure TTaskBase.SetTaskId(const Value: TIdentity);
begin
  FTaskId := Value;
end;

{ TInterfacedResult }

constructor TInterfacedResult.Create(const AName: string);
begin
  FName := AName;
end;

function TInterfacedResult.GetName: WideString;
begin
  Result := FName;
end;

{ TAggregatedResult }

constructor TAggregatedResult.Create(const AName: string);
begin
  FName := AName;
end;

function TAggregatedResult.GetName: WideString;
begin
  Result := FName;
end;

{ TListInternal<TItem> }

function TListInternal<TItem>.Add(const Item: TItem): Integer;
begin
  Result := FInnerList.Add(Item);
end;

constructor TListInternal<TItem>.Create;
begin
  FInnerList := TList<TItem>.Create;
end;

destructor TListInternal<TItem>.Destroy;
begin
  FreeAndNil(FInnerList);
  inherited;
end;

function TListInternal<TItem>.GetCount: Integer;
begin
  Result := FInnerList.Count;
end;

function TListInternal<TItem>.GetItem(Index: Integer): TItem;
begin
  Result := FInnerList[Index];
end;

procedure TListInternal<TItem>.SetItem(Index: Integer; const Item: TItem);
begin

end;

end.
