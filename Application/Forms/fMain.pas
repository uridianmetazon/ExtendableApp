unit fMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.CategoryButtons, Data.DB, FireDAC.Comp.Client,
  System.Actions, Vcl.ActnList, Vcl.ActnMan, Vcl.Menus, Vcl.StdCtrls, IOUtils,
  Vcl.ComCtrls, System.Messaging, PluginHostAPI, PluginManager, Host;

type
  TfrmMain = class(TForm)
    MainMenu: TMainMenu;
    mnuFile: TMenuItem;
    mnuExternal: TMenuItem;
    StatusBar: TStatusBar;
    mnuShowTaskList: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure mnuShowTaskListClick(Sender: TObject);
  private
    FAutoShowTaskList: Boolean;
    function FindChildForm (aFormClass: TFormClass): TForm;
    procedure CreateGui(aPlugin: TPlugin);
    procedure RemoveGui(aSessionId: NativeInt);
    procedure LogEventListener(const Sender: TObject; const M: TMessage);
    procedure TaskStateChangedListener(const Sender: TObject; const M: TMessage);
    procedure PluginEventListener(const Sender: TObject; const M: TMessage);
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses fAsyncOperationList;

procedure TfrmMain.TaskStateChangedListener(const Sender: TObject; const M: TMessage);
begin
  if FAutoShowTaskList and not Assigned(FindChildForm(TfrmAsyncOperationList)) then
  begin
    FAutoShowTaskList := False;
    mnuShowTaskList.Click;
  end;
  //var Task := MessageAsTask(M);
end;

procedure TfrmMain.CreateGui(aPlugin: TPlugin);
begin
  var MM := TMenuItem.Create(Application);
  MM.Caption := aPlugin.Caption;
  MM.Hint := aPlugin.Description;
  MM.Tag := aPlugin.SessionId;
  mnuExternal.Add(MM);
  for var A in aPlugin.ActionList do
  begin
    var M := TMenuItem.Create(MM);
    M.Action := A;
    M.Caption := A.Caption;
    M.Hint := A.Hint;
    MM.Add(M);
  end;
end;

function TfrmMain.FindChildForm(aFormClass: TFormClass): TForm;
begin
  for var i := 0 to MDIChildCount - 1 do
    if MDIChildren[i] is aFormClass then
      Exit (MDIChildren[i]);
  Result := nil;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FAutoShowTaskList := True;

  var M := TMessageManager.DefaultManager;
  M.SubscribeToMessage(TMessage<TTaskStateChanged>, TaskStateChangedListener);
  M.SubscribeToMessage(TMessage<TTaskLogPosted>, LogEventListener);
  M.SubscribeToMessage(TMessage<TMessagePlugin>, PluginEventListener);

  DefaultHost.SetMainWindowHandle(Self.Handle);
  TPluginManager.Default.LoadAllFromDir(ExtractFilePath(ParamStr(0)));
end;

procedure TfrmMain.LogEventListener(const Sender: TObject; const M: TMessage);
begin
  var Task := MessageAsTask(M);
  if not Assigned(Task) then
    Exit;
  StatusBar.Panels[3].Width := 5000;
  StatusBar.Panels[0].Text := 'Задача: ' + Task.Name;
  StatusBar.Panels[1].Text := 'Статус: ' + Task.State.ToString;
  StatusBar.Panels[2].Text := '';      // debug
  StatusBar.Panels[3].Text := 'Лог: ' + Task.LastLogMessage;
end;

procedure TfrmMain.mnuShowTaskListClick(Sender: TObject);
begin
  TfrmAsyncOperationList.Create(Application).Show;
end;

procedure TfrmMain.PluginEventListener(const Sender: TObject; const M: TMessage);
begin
  var EventData := (M as TMessage <TMessagePlugin>).Value;
  case EventData.Added of
    True: CreateGui(EventData.Plugin);
    False: RemoveGui(EventData.Plugin.SessionId);
  end;

end;

procedure TfrmMain.RemoveGui(aSessionId: NativeInt);
begin
  for var i := mnuExternal.Count - 1 downto 0 do
    if mnuExternal[i].Tag = aSessionId then
    begin
      mnuExternal.Remove(mnuExternal[i]);
      Exit;
    end;
end;

end.
