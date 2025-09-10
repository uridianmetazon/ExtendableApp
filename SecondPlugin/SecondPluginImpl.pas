unit SecondPluginImpl;

interface

uses System.SysUtils, System.IOUtils, System.UITypes, System.Classes, Winapi.Windows, PluginBase, PluginHostApi, Globals;

type

  TCommandLinePlugin = class (TPluginBase, IPlugin)
  public
    constructor Create (ASessionId: TIdentity); override;
  end;

  TArchiveAction = class (TActionBase, IAction)
  strict protected
    function Execute: ITask; override; safecall;
  end;

  IIntegerResultInternal = interface (IIntegerResult)
    procedure SetValue (const aValue: Int64);
    property Value: Int64 read GetValue write SetValue;
  end;

  TArchiveResult = class (TInterfacedResult, IResult, IIntegerResult, IIntegerResultInternal)
  private
    FValue: Int64;
    procedure SetValue (const aValue: Int64);
    function GetValue: Int64; safecall;
  end;

  TArchiveTask = class (TTaskBase)
  strict protected
    FResult: IIntegerResultInternal;
    FParams: TArchiveParams;
    procedure Execute; override; safecall;
    function GetDetails: Widestring; override; safecall;
  public
    constructor Create (ATaskId: TIdentity; const AName: WideString; const AParams: TArchiveParams); reintroduce;
    function GetResult: IResult; override; safecall;
  end;

implementation

uses fArchiveParams;

{ TCommandLinePlugin }

constructor TCommandLinePlugin.Create(ASessionId: TIdentity);
begin
  inherited Create (ASessionId);
  FName := 'Инструменты командной строки';
  FActionList.Add(TArchiveAction.Create('Архивировать файл(ы)…'));
end;

{ TArchiveAction }

function TArchiveAction.Execute: ITask;
var
  Params: TArchiveParams;
begin
  Params.TargetFileName := 'Archive.zip';
  Params.SourcePath := TPath.Combine(ExtractFilePath(ParamStr(0)), '*.txt');
  with TfrmArchiveParams.Create(nil) do
  try
    ParentWindow := TGlobals.Host.MainWindowHandle;
    if not IsPositiveResult(ShowModal(Params)) then
      Exit(nil);
  finally
    Free;
  end;
  Result := TArchiveTask.Create(TGlobals.Host.NextIdentity, 'Архивирование файлов', Params);
end;

{ TArchiveTask }

constructor TArchiveTask.Create(ATaskId: TIdentity; const AName: WideString; const AParams: TArchiveParams);
begin
  inherited Create (TGlobals.Host.NextIdentity, AName);
  FParams := aParams;
  FSessionId := TGlobals.Plugin.SessionId;
  FResult := TArchiveResult.Create('Код завершения внешнего процесса');
end;

procedure TArchiveTask.Execute;
var
  ErrMsg: string;
  NewState: TTaskState;
  StartupInfo: TStartupInfo;
  SecurityAttributes: TSecurityAttributes;
  ChildProcess: TProcessInformation;
  PipeReadHandle: THandle;
  PipeWriteHandle: THandle;
  PipeWriteClosed: Boolean;
  Reader: TStreamReader;
  ChildProcessExitCode: DWORD;
begin
  try
    FStartMoment := Now;
    if State = Cancelling then
      Abort;
    State := Running;
    PostLogMessage('Старт');

    if not FParams.IsValid(ErrMsg) then
      raise Exception.Create('ErrMsg');

    ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
    SecurityAttributes.nLength := SizeOf(SecurityAttributes);
    SecurityAttributes.bInheritHandle := True;
    SecurityAttributes.lpSecurityDescriptor := nil;

    PipeWriteClosed := False;
    if not CreatePipe(PipeReadHandle, PipeWriteHandle, @SecurityAttributes, 0) then
      RaiseLastOSError;
    try
      if not SetHandleInformation(PipeReadHandle, HANDLE_FLAG_INHERIT, 0) then
        RaiseLastOSError;

      StartupInfo.cb := SizeOf(StartupInfo);
      StartupInfo.hStdOutput := PipeWriteHandle;
      StartupInfo.hStdError := PipeWriteHandle;
      StartupInfo.wShowWindow := SW_HIDE;
      StartupInfo.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;

      if not CreateProcess(
        nil,
        PChar(FParams.CommandLine),
        @SecurityAttributes,
        @SecurityAttributes,
        True,
        CREATE_NO_WINDOW or NORMAL_PRIORITY_CLASS,
        nil,
        nil,
        StartupInfo,
        ChildProcess
      ) then
        RaiseLastOSError;

      try
        CloseHandle(PipeWriteHandle); // чтобы не зависал ReadFile внутри Reader
        PipeWriteClosed := True;
        Reader := TStreamReader.Create(THandleStream.Create(PipeReadHandle), TEncoding.ANSI);
        try
          Reader.OwnStream;
          while WaitForSingleObject (ChildProcess.hProcess, 10) = WAIT_TIMEOUT do
          begin
            if State = Cancelling then
            begin
              TerminateProcess(ChildProcess.hProcess, 1001);
              Abort;
            end;
            while not Reader.EndOfStream do
            begin
              PostLogMessage(Reader.ReadLine);
              if State = Cancelling then
              begin
                TerminateProcess(ChildProcess.hProcess, 1001);
                Abort;
              end
            end;
          end;
          while not Reader.EndOfStream do
            PostLogMessage(Reader.ReadLine);
        finally
          FreeAndNil(Reader);
        end;
      finally
        GetExitCodeProcess(ChildProcess.hProcess, ChildProcessExitCode);
        CloseHandle(ChildProcess.hThread);
        CloseHandle(ChildProcess.hProcess);
        FResult.Value := ChildProcessExitCode;
      end;

    finally
      if not PipeWriteClosed then
        CloseHandle(PipeWriteHandle);
      CloseHandle(PipeReadHandle);
    end;
    FinishMoment := Now;
    NewState := Completed;
    PostLogMessage(NewState.ToString);
    State := NewState;
  except
    on EA: EAbort do
    begin
      FinishMoment := Now;
      NewState := Cancelled;
      PostLogMessage(NewState.ToString);
      State := NewState;
    end;
    on E: Exception do
    begin
      FinishMoment := Now;
      NewState := Failed;
      PostLogMessage (Format('%s: <%s> %s', [NewState.ToString, E.ClassName, E.Message]));
      State := NewState;
    end;
  end;
end;

function TArchiveTask.GetDetails: Widestring;
begin
  Result := 'Архивирование в ' + FParams.TargetFileName + ' из ' + FParams.SourcePath;
end;

function TArchiveTask.GetResult: IResult;
begin
  Result := FResult;
end;

{ TArchiveResult }

function TArchiveResult.GetValue: Int64;
begin
  Result := FValue;
end;

procedure TArchiveResult.SetValue(const aValue: Int64);
begin
  FValue := aValue;
end;

end.
