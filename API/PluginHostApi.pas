unit PluginHostApi;

interface
uses System.SyncObjs, System.SysUtils, Winapi.Windows;

type
  TIdentity = Integer;
  TTaskState = Integer;
  {$SCOPEDENUMS ON}
  TTaskStateEnum = (WaitingToRun, Running, Cancelling, Cancelled, Completed, Failed);
  {$SCOPEDENUMS OFF}
const
  WaitingToRun  = TTaskState(TTaskStateEnum.WaitingToRun);
  Running       = TTaskState(TTaskStateEnum.Running);
  Cancelling    = TTaskState(TTaskStateEnum.Cancelling);
  Cancelled     = TTaskState(TTaskStateEnum.Cancelled);
  Completed     = TTaskState(TTaskStateEnum.Completed);
  Failed        = TTaskState(TTaskStateEnum.Failed);

type

  TTaskStateHelper = record helper for TTaskState
    function IsFinal: Boolean;
    function ToString: string;
    function IsStartable: Boolean;
    function IsCancelable: Boolean;
  end;

  IHost = interface (IInterface)
  ['{BDD4C30B-CDF0-4BDD-9C59-B36FF723FF04}']
    function GetMainWindowHandle: HWND; safecall;
    property MainWindowHandle: HWND read GetMainWindowHandle;
    function NextIdentity: TIdentity; safecall;
  end;

  TLogItem = record
    TaskId: TIdentity;
    Moment: TDateTime;
    Text: WideString;
  end;

  ILogReceiver = interface (IInterface)
  ['{D4E2B4C4-1650-43AC-9058-E335E07622DE}']
    procedure PostLogItem ([ref] const Item: TLogItem); safecall;
  end;

  IResult = interface (IInterface)
  ['{E3D11CAB-93CB-4428-94E5-15E61594B0F1}']
    function GetName: WideString; safecall;
    property Name: WideString read GetName;
  end;

  IResult<T> = interface (IResult)
    function GetValue: T; safecall;
    property Value: T read GetValue;
  { Примечание для разработчиков плагинов.
    Следует помнить, что главное приложение (Host) может обратиться к
    IResult.Value для чтения в любой момент времени, асинхронно, (в своем
    потоке).
    Штатным поведением хоста является асинхронное чтение из IResult.Value
    после получения сигналов NotifyResultChanged и NotifyStateChanged.}
  end;

  IIntegerResult = interface (IResult<Int64>)
  ['{17408CF4-C062-43E4-A906-350FA2C064A7}']
  end;

  IList<T> = interface (IInterface)
    function GetCount: Integer; safecall;
    function GetItem(Index: Integer): T; safecall;
    property Count: Integer read GetCount;
    property Items[Index: Integer]: T read GetItem; default;
  end;

  IStrings = interface (IList<WideString>)
  ['{9E38B944-DD89-48BA-876F-2C808412F668}']
  end;

  IStringsResult = interface (IResult<IStrings>)
  ['{DB84BADC-FE38-4DBE-A102-46AD0735AA8D}']
  end;

  IResultChangesReceiver = interface (IInterface)
  ['{9828EF84-270D-4A3B-B511-7D412513DB9F}']
    procedure NotifyResultChanged (const TaskId: TIdentity); safecall;
  { Примечание для разработчиков плагинов.
    При получении уведомления об изменении результата с помощью
    NotifyResultChanged, главное приложение (Host) предполагает, что результат
    IResult является кумулятивным (накопительным). Например, для IStringsResult
    это означает, что новые строки добавляются в конец списка, и впоследствии ни
    они сами, ни их положение в списке не меняются. Если результат НЕ является
    накопительным, следует НЕ использовать NotifyResultChanged. В любом случае,
    окончательный результат IResult, (или его часть, недовыбранная в
    промежуточных выборках), будет извлечен Host-ом при переходе задачи в
    конечное состояние (State.IsFinal).
    Плагин не должен делать предположений о том, какая часть промежуточного
    результата будет извлечена главным приложением по сигналу
    NotifyResultChanged.
    Следует также учитывать, что извлечение окончательного и промежуточных
    результатов реализовано асинхронно, (в потоке Host-а), что может потребовать
    синхронизации многопоточного доступа к объектам IResult.Value.}
  end;

  IStateChangesReceiver = interface (IInterface)
  ['{E049FCD4-9EFD-4181-80A8-3449DFA1C65D}']
    procedure NotifyStateChanged (const TaskId: TIdentity); safecall;
  { Примечание для разработчиков плагинов.
    Передавать сообщение с помощью NotifyStateChanged при переходе задачи
    в конечное состояния (State.IsFinal) следует в последнюю очередь, после
    всех других сообщений, таких как PostLogItem или NotifyResultChanged,
    поскольку главное приложение (Host) отключает прием сообщений после
    завершения задачи. Непосредственно перед этим Host забирает результаты
    выполнения IResult, (асинхронно, в своем потоке).}
  end;

  ITask = interface
  ['{7FD5AE67-295C-4B03-BA7F-81E7A679C3FF}']
    function GetTaskId: TIdentity; safecall;
    function GetSessionId: TIdentity; safecall;
    function GetName: WideString; safecall;
    function GetDetails: Widestring; safecall;
    function GetState: TTaskState; safecall;
    function GetStartMoment: TDateTime; safecall;
    function GetFinishMoment: TDateTime; safecall;
    function GetLogReceiver: ILogReceiver; safecall;
    procedure SetLogReceiver (const Receiver: ILogReceiver); safecall;
    function GetStateChangesReceiver: IStateChangesReceiver; safecall;
    procedure SetStateChangesReceiver (const Receiver: IStateChangesReceiver); safecall;
    function GetResultChangesReceiver: IResultChangesReceiver; safecall;
    procedure SetResultChangesReceiver (const Receiver: IResultChangesReceiver); safecall;
    function GetResult: IResult; safecall;

    property TaskId: TIdentity read GetTaskId;
    property SessionId: TIdentity read GetSessionId;
    property Name: WideString read GetName;
    property Details: WideString read GetDetails;
    property State: TTaskState read GetState;
    property StartMoment: TDateTime read GetStartMoment;
    property FinishMoment: TDateTime read GetFinishMoment;
    property LogReceiver: ILogReceiver read GetLogReceiver write SetLogReceiver;
    property StateChangesReceiver: IStateChangesReceiver read GetStateChangesReceiver write SetStateChangesReceiver;
    property ResultChangesReceiver: IResultChangesReceiver read GetResultChangesReceiver write SetResultChangesReceiver;
    property Result: IResult read GetResult;

    procedure Execute; safecall;
    procedure Cancel; safecall;
  end;

  IAction = interface (IInterface)
  ['{5DEE886B-2E31-43F7-AD26-C970A5C095C8}']
    function GetName: WideString; safecall;
    property Name: Widestring read GetName;
    function Execute: ITask; safecall;
  end;

  IActions = interface (IList<IAction>)
  ['{4FF59A53-3760-4C38-ADB2-D39073909060}']
  end;

  IPlugin = interface (IInterface)
  ['{0644AC2F-528E-462E-BBAD-67362C79405F}']
    function GetSessionId: TIdentity; safecall;
    function GetName: WideString; safecall;
    function GetActions: IActions; safecall;

    property SessionId: TIdentity read GetSessionId;
    property Name: Widestring read GetName;
    property Actions: IActions read GetActions;
  end;

  THelloFunction = function (const Host: IHost): IPlugin; safecall;
  TGoodbyeProcedure = procedure; safecall;

const
  HelloFunctionName = 'HelloPlugin';
  GoodbyeProcedureName = 'GoodbyePlugin';

implementation


{ TTaskStateHelper }

function TTaskStateHelper.IsCancelable: Boolean;
begin
  Result := Self in [Running];
end;

function TTaskStateHelper.IsFinal: Boolean;
begin
  Result := Self in [Cancelled, Completed, Failed];
end;

function TTaskStateHelper.IsStartable: Boolean;
begin
  Result := Self = WaitingToRun;
end;

function TTaskStateHelper.ToString: string;
const
  Z: array[TTaskStateEnum] of string = ('Ждет запуска', 'Выполняется', 'В процессе отмены', 'Отменено', 'Завершено', 'Завершено с ошибкой');
begin
  Result := Z[TTaskStateEnum(Self)];
end;

end.
