unit PluginManager;

interface

uses System.SysUtils, System.SyncObjs, Winapi.Windows, System.Generics.Collections, 
    System.Messaging, System.Actions, System.IOUtils,
    PluginHostAPI;

type

  TPlugin = class
  private type
    TPluginAction = class (TContainedAction)
    private
      FExternalAction: IAction;
      FSessionId: TIdentity;
    public
      property ExternalAction: IAction read FExternalAction write FExternalAction;
      property SessionId: TIdentity read FSessionId write FSessionId;
      procedure ExternalActionExecute (Sender: TObject);
    end;
  private
    FFileName: string;
    FModule: HMODULE;
    FHello: THelloFunction;
    FGoodbye: TGoodbyeProcedure;
    FExternalObject: IPlugin;
    FSessionId: TIdentity;
    FActionList: TContainedActionList;
    FCaption: string;
    FDescription: string;
    procedure CreateActionList;
  public
    constructor LoadFromFile (const aFileName: string);
    destructor Destroy; override;
    property FileName: string read FFileName;
    property ExternalObject: IPlugin read FExternalObject;
    property SessionId: TIdentity read FSessionId;
    property ActionList: TContainedActionList read FActionList;
    property Caption: string read FCaption;
    property Description: string read FDescription;
  end;

  TMessagePlugin = record
    Plugin: TPlugin;
    Added: Boolean;
    constructor Create (const aPlugin: TPlugin; aAdded: Boolean);
  end;

  // Singleton
  TPluginManager = class (TObjectList<TPlugin>)
  private
    class var FUniqueInstance: TPluginManager;
    class destructor Destroy;
  public
    class function Create: TPluginManager;
    class function Default: TPluginManager;
  public
    procedure LoadAllFromDir (const aPath: string);
  end;

implementation

uses Host;

{ TPluginManager }

class function TPluginManager.Create: TPluginManager;
var
  newInstance: TPluginManager;
begin
  if FUniqueInstance = nil then
  begin
    newInstance := inherited Create(True);
    if (TInterlocked.CompareExchange<TPluginManager>(FUniqueInstance, newInstance, nil) <> nil) then
      newInstance.Free;
  end;
  Result := FUniqueInstance;
end;

class function TPluginManager.Default: TPluginManager;
begin
  Result := Create;
end;

class destructor TPluginManager.Destroy;
begin
  var oldInstance := TInterlocked.Exchange<TPluginManager>(FUniqueInstance, nil);
  if oldInstance <> nil then
    oldInstance.Free;
end;

procedure TPluginManager.LoadAllFromDir(const aPath: string);
begin
  for var F in TDirectory.GetFiles(aPath, '*.dll') do
    try
      Add (TPlugin.LoadFromFile(F));
    except on e: Exception do
    end;
end;

{ TPlugin }

procedure TPlugin.CreateActionList;
begin
  FActionList := TContainedActionList.Create(nil);
  if not Assigned(FExternalObject) then
    Exit;
  for var i := 0 to FExternalObject.Actions.Count - 1 do
  begin
    var A := FExternalObject.Actions[i];
    var PA := TPluginAction.Create(FActionList);
    PA.Caption := A.Name;
    PA.ExternalAction := A;
    PA.OnExecute := PA.ExternalActionExecute;
    PA.Tag := FSessionId;
    PA.SessionId := FSessionId;
    PA.ActionList := FActionList;
  end;
end;

destructor TPlugin.Destroy;
begin
  try
    FActionList.Free;
    FGoodbye;
    FExternalObject := nil;
    FreeLibrary(FModule);
  except on e: Exception do
  end;
  inherited;
end;

constructor TPlugin.LoadFromFile(const aFileName: string);
begin
  inherited Create;
  FFileName := aFileName;
  try
    FModule := SafeLoadLibrary(FFileName);
    FHello := GetProcAddress(FModule, HelloFunctionName);
    FGoodbye := GetProcAddress(FModule, GoodbyeProcedureName);
    FExternalObject := FHello (DefaultHost);
    FCaption := FExternalObject.Name;
    FSessionId := FExternalObject.SessionId;
    CreateActionList;
  except on e: Exception do
    raise;
  end;
end;

{ TPlugin.TPluginAction }

procedure TPlugin.TPluginAction.ExternalActionExecute(Sender: TObject);
var
  TaskInner: TTask;
begin
  var ExAction := FExternalAction;
  if Assigned(ExAction) then
  begin
    var ExTask := ExAction.Execute;
    if Assigned(ExTask) then
    begin
      TaskInner := TTask.Create(ExTask, SessionId);
      DefaultHost.RegisterAndLaunchNewTask(TaskInner);
    end;
  end;
end;

{ TMessagePlugin }

constructor TMessagePlugin.Create(const aPlugin: TPlugin; aAdded: Boolean);
begin
  Self.Plugin := aPlugin;
  Self.Added := aAdded;
end;

end.
