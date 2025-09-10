unit FirstPluginImpl;

interface

uses System.SysUtils, System.Classes, System.UITypes, System.Generics.Collections, System.IOUtils, System.Masks, System.Diagnostics,
  PluginHostApi, PluginBase, Globals;

type

  TSearchFileAction = class (TActionBase, IAction)
  strict protected
    function Execute: ITask; override; safecall;
  end;

  TSearchInFileAction = class (TActionBase, IAction)
  strict protected
    function Execute: ITask; override; safecall;
  end;

  TSearchPlugin = class (TPluginBase, IPlugin)
  public
    constructor Create (ASessionId: TIdentity); override;
  end;

  TSearchResult = class (TInterfacedResult, IStringsResult, IIntegerResult, IResult<IListInternal<WideString>>)
  strict protected
    FStringsValue: IListInternal<WideString>;
    FIntegerResult: TAggregatedResult;
    property IntegerResult: TAggregatedResult read FIntegerResult write FIntegerResult implements IIntegerResult;
    function GetIntegerValue: Int64; safecall;
    function IIntegerResult.GetValue = GetIntegerValue;
    function GetStringsValue: IStrings; safecall;
    function IStringsResult.GetValue = GetStringsValue;
    function GetInternalValue: IListInternal<WideString>; safecall;
    function IResult<IListInternal<WideString>>.GetValue = GetInternalValue;
    function GetIntegerName: WideString; safecall;
    function IIntegerResult.GetName = GetIntegerName;
  public
    constructor Create (const StringsResultName, IntegerResultName: string); reintroduce;
    destructor Destroy; override;
  end;

  TSearchFileTask = class (TTaskBase, ITask)
  strict protected
    FParams: TSearchFileParams;
    FResult: IResult<IListInternal<WideString>>;
    function GetDetails: Widestring; override; safecall;
    function GetResult: IResult; override; safecall;
    procedure Execute; override; safecall;
  public
    constructor Create(ATaskId: TIdentity; AName: WideString; AParams: TSearchFileParams); reintroduce;
  end;

  TInterfacedIntegerList = class (TInterfacedObject, IListInternal<Int64>)
  private
    FInnerList: TList<Int64>;
  strict protected
    function GetCount: Integer; safecall;
    function GetItem(Index: Integer): Int64; safecall;
    procedure SetItem (Index: Integer; const Item: Int64);
    function Add (const Item: Int64): Integer;
    property Items[Index: Integer]: Int64 read GetItem write SetItem; default;
    property Count: Integer read GetCount;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
  end;

  TSearchInFileResult = class (TInterfacedResult, IStringsResult, IResult<IListInternal<WideString>>)
  private
    FStringsValue: IListInternal<WideString>;
    function GetStringsValue: IStrings; safecall;
    function IStringsResult.GetValue = GetStringsValue;
    function GetInternalValue: IListInternal<WideString>; safecall;
    function IResult<IListInternal<WideString>>.GetValue = GetInternalValue;
  public
    constructor Create (const ResultName: string); reintroduce;
  end;

  TSearchInFileTask = class (TTaskBase, ITask)
  strict protected
    FParams: TSearchInFileParams;
    FPatternsAsString: string;
    FResult: IResult<IListInternal<WideString>>;
    function GetDetails: Widestring; override; safecall;
    function GetResult: IResult; override; safecall;
    procedure Execute; override; safecall;
  public
    constructor Create(ATaskId: TIdentity; AName: WideString; AParams: TSearchInFileParams); reintroduce;
  end;

implementation

{ TSearchFileAction }

uses fSearchFilesParams, fSearchSubstringParams;

function TSearchFileAction.Execute: ITask;
var
  Params: TSearchFileParams;
begin
  Result := nil;
  Params.Path := ExtractFilePath(ParamStr(0));
  Params.Recursive := True;
  Params.MaskCombined := '*.dll,*.exe';
  with TfrmSearchFilesParams.Create(nil) do
  try
    ParentWindow := TGlobals.Host.MainWindowHandle;
    if not IsPositiveResult (ShowModal (Params)) then
      Exit;
  finally
    Free;
  end;
  Result := TSearchFileTask.Create(TGlobals.Host.NextIdentity, 'Поиск файлов', Params);
end;

{ TSearchInFileAction }

function TSearchInFileAction.Execute: ITask;
var
  Params: TSearchInFileParams;
begin
  Result := nil;
  Params.Filename := TPath.Combine(ExtractFilePath(ParamStr(0)), 'TestABC.txt');
  Params.Patterns := ['AAA', 'ABC', 'CB'];
  with TfrmSearchSubstringParams.Create(nil) do
  try
    ParentWindow := TGlobals.Host.MainWindowHandle;
    if not IsPositiveResult(ShowModal(Params)) then
      Exit;
  finally
    Free;
  end;
  Result := TSearchInFileTask.Create(TGlobals.Host.NextIdentity, 'Поиск строк в файле', Params);
end;

{ TSearchPlugin }

constructor TSearchPlugin.Create(ASessionId: TIdentity);
begin
  inherited Create(ASessionId);
  FName := 'Операции с файлами';
  FActionList.Add(TSearchFileAction.Create('Найти файлы в папке…'));
  FActionList.Add(TSearchInFileAction.Create('Найти строки в файле…'));
end;

{ TSearchFileTask }

constructor TSearchFileTask.Create(ATaskId: TIdentity; AName: WideString; AParams: TSearchFileParams);
begin
  inherited Create (ATaskId, AName);
  FParams := AParams;
  FSessionId := TGlobals.Plugin.SessionId;
  FResult := TSearchResult.Create('Список файлов', 'Файлов найдено');
end;

procedure TSearchFileTask.Execute;
const
  SearchOpt: array [False..True] of TSearchOption = (TSearchOption.soTopDirectoryOnly, TSearchOption.soAllDirectories);
var
  Masks: TObjectList<TMask>;
  Err: string;
  FilterPredicate: TDirectory.TFilterPredicate;
  SearchOption: TSearchOption;
  PreviousPath: string;
  AnyFileMask: Boolean;
  NewState: TTaskState;

  function CheckCancelling: Boolean;
  begin
    Result := State = Cancelling;
    if Result then
    begin
      NewState := Cancelled;
      FFinishMoment := Now;
      PostLogMessage (NewState.ToString);
      State := NewState;
    end;
  end;

begin
  try
    FStartMoment := Now;
    State := Running;
    PostLogMessage('Старт');

    if CheckCancelling then
      Exit;

    if not FParams.IsValid(Err) then
      raise Exception.Create(Err);
    SearchOption := SearchOpt [FParams.Recursive];
    PreviousPath := FParams.Path;
    PostLogMessage ('Поиск в ' + PreviousPath);
    var MM: TArray<string>;
    FParams.TryParseMask(MM, Err);
    if CheckCancelling then
      Exit;

    Masks := TObjectList<TMask>.Create(True);
    try
      AnyFileMask := False;
      for var M in MM do
        if M = '*.*' then
          AnyFileMask := True
        else
          Masks.Add(TMask.Create(M));
      if CheckCancelling then
        Exit;

      FilterPredicate :=
        function (const Path: string; const SearchRec: TSearchRec): Boolean

          function Matches: Boolean;
          begin
            for var Mask in Masks do
              if Mask.Matches(SearchRec.Name) then
                Exit(True);
            Result := False;
          end;

        begin
          if State = Cancelling then
            Abort;
          if not AnsiSameText(Path, PreviousPath) then
          begin
            PreviousPath := Path;
            PostLogMessage ('Поиск в ' + Path);
          end;
          Result := AnyFileMask or Matches;
          if Result then
          begin
            Self.FResult.Value.Add(TPath.Combine(Path, SearchRec.Name, False));
            NotifyResultChanged;
            PostLogMessage ('Найден файл ' + SearchRec.Name);
          end;
        end;

      for var F in TDirectory.GetFiles(FParams.Path, SearchOption, FilterPredicate) do
        if CheckCancelling then
          Exit;
      if CheckCancelling then
        Exit;
      FinishMoment := Now;
      NewState := Completed;
      PostLogMessage (NewState.ToString);
      State := NewState;
    finally
      Masks.Free;
    end;
  except
    on EA: EAbort do
      CheckCancelling;
    on E: Exception do
    begin
      FinishMoment := Now;
      NewState := Failed;
      PostLogMessage (Format('%s: <%s> %s', [NewState.ToString, E.ClassName, E.Message]));
      State := NewState;
    end;
  end;
end;

function TSearchFileTask.GetDetails: Widestring;
const
  Z: array[Boolean] of string = ('Поиск', 'Рекурсивный поиск');
begin
  Result := Format ('%s в папке %s по маске <%s>', [Z[FParams.Recursive], FParams.Path, FParams.MaskCombined]);
end;

function TSearchFileTask.GetResult: IResult;
begin
  Result := Self.FResult;
end;

{ TSearchResult }

constructor TSearchResult.Create(const StringsResultName, IntegerResultName: string);
begin
  Self.FName := StringsResultName;
  FIntegerResult := TAggregatedResult.Create(IntegerResultName);
  FStringsValue := TStringsInternal.Create;
end;

destructor TSearchResult.Destroy;
begin
  FreeAndNil(FIntegerResult);
  inherited;
end;

function TSearchResult.GetIntegerName: WideString;
begin
  Result := FIntegerResult.Name;
end;

function TSearchResult.GetIntegerValue: Int64;
begin
  Result := FStringsValue.Count;
end;

function TSearchResult.GetInternalValue: IListInternal<WideString>;
begin
  Result := FStringsValue;
end;

function TSearchResult.GetStringsValue: IStrings;
begin
  Result := FStringsValue as IStrings;
end;

{ TSearchInFileTask }

constructor TSearchInFileTask.Create(ATaskId: TIdentity; AName: WideString; AParams: TSearchInFileParams);
begin
  inherited Create (ATaskId, AName);
  FSessionId := TGlobals.Plugin.SessionId;
  FParams := AParams;
  FResult := TSearchInFileResult.Create('Список найденных позиций');
  for var S in FParams.Patterns do
    if FPatternsAsString = '' then
      FPatternsAsString := S
    else
      FPatternsAsString := FPatternsAsString + ',' + S
end;

procedure TSearchInFileTask.Execute;
type
  THash = Integer;
  PPattern = ^TPattern;
  TPattern = record
    Body: TBytes;
    Size: Integer;
    Hash: THash;
    FileOffset: Int64;
    BufferOffset: Int64;
    RollingHash: Integer;
    Eof: Boolean;
    Result: IListInternal<Int64>;
  end;

  function ResultToString (List: IListInternal<Int64>): string;
  begin
    var SB := TStringBuilder.Create;
    try
      for var i := 0 to List.Count - 1 do
        if i = 0 then
          SB.Append(List[i])
        else
          Sb.Append(',').Append(List[i]);
      Result := SB.ToString;
    finally
      FreeAndNil(SB);
    end;
  end;

const
  DefaultBufferSize = 32768;
  DefaultIntervalTicks = 10000000;

  function CalcHash (const Buf: TBytes; Start, Len: Int64): Integer;
  begin
    Assert (Start + Len <= Length(Buf));
    Result := 0;
    for var i := 0 to Start + Len - 1 do
      Inc(Result, Buf[i]);
  end;

var
  Patterns: TArray<TPattern>;
  Pattern: PPattern;
  Reader: TStream;
  Buffer: TBytes;
  BufferSize: Integer;
  ActualBufferSize: Integer;
  EofCount: Integer;
  FileSize: Int64;
  BytesRead: Int64;
  FileEof: Boolean;
  NewState: TTaskState;
  LastPostMessageTimeStamp: Int64;

  procedure ShiftWindow;
  begin
    if not FileEof and (ActualBufferSize <= Pattern.BufferOffset + Pattern.Size) then
    begin
      if State = Cancelling then
        Abort;

      var CurrentTimeStamp := TStopWatch.GetTimeStamp;
      if CurrentTimeStamp - LastPostMessageTimeStamp > DefaultIntervalTicks then
      begin
        var CurrentPercent := (100 * Pattern.FileOffset) / FileSize;
        PostLogMessage(Format ('Процент выполнения = %f', [CurrentPercent]));
        LastPostMessageTimeStamp := CurrentTimeStamp;
      end;

      var Offset := Pattern.BufferOffset;
      Move(Buffer[Offset], Buffer[0], Pattern.Size);
      var Batch := Reader.Read(Buffer, Pattern.Size, BufferSize - Pattern.Size);
      ActualBufferSize := Batch + Pattern.Size;
      Inc (BytesRead, Batch);
      if FileSize <= BytesRead then
        FileEof := True;
      for var i := 0 to High(Patterns) do
        Dec(Patterns[i].BufferOffset, Offset);
    end;
    if not Pattern.Eof and (ActualBufferSize <= Pattern.BufferOffset + Pattern.Size) then
    begin
      Pattern.Eof := True;
      Inc(EofCount);
    end;
    if not Pattern.Eof then
    begin
      Dec (Pattern.RollingHash, Buffer[Pattern.BufferOffset]);
      Inc (Pattern.BufferOffset);
      Inc (Pattern.RollingHash, Buffer[Pattern.BufferOffset + Pattern.Size - 1]);
      Inc (Pattern.FileOffset);
    end;
  end;

  procedure SaveResult;
  begin
    for var i := 0 to High(Patterns) do
    begin
      FResult.Value.Add(Format('[%s] кол-во = %d, позиции: %s'
                              , [FParams.Patterns[i], Patterns[i].Result.Count, ResultToString(Patterns[i].Result)]));
      PostLogMessage(Format('Для подстроки [%s] найдено %d вхождений', [FParams.Patterns[i], Patterns[i].Result.Count]));
    end;
  end;

begin
  try
    FStartMoment := Now;
    State := Running;
    PostLogMessage('Старт');
    LastPostMessageTimeStamp := TStopwatch.GetTimeStamp;

    var ErrMsg: string;
    if not FParams.IsValid(ErrMsg) then
      raise Exception.Create(ErrMsg);

  {$REGION 'init vars'}
    BufferSize := 0;
    SetLength(Patterns, Length(FParams.Patterns));
    for var i := 0 to High(FParams.Patterns) do
    begin
      Patterns[i].Body := TEncoding.ANSI.GetBytes(FParams.Patterns[i]);
      Patterns[i].Size := Length(Patterns[i].Body);
      if Patterns[i].Size > BufferSize then
        BufferSize := Patterns[i].Size;
      Patterns[i].BufferOffset := 0;
      Patterns[i].FileOffset := 0;
      Patterns[i].Hash := CalcHash(Patterns[i].Body, 0, Patterns[i].Size);
      Patterns[i].Result := TInterfacedIntegerList.Create;
      Patterns[i].Eof := False;
    end;
    BufferSize := BufferSize shl 4;
    if BufferSize < DefaultBufferSize then
      BufferSize := DefaultBufferSize;
    SetLength(Buffer, BufferSize);
    EofCount := 0;
    BytesRead := 0;
    FileEof := False;
    LastPostMessageTimeStamp := 0;
    {$ENDREGION}

    if State = Cancelling then
      Abort;

    Reader := TFileStream.Create(FParams.Filename, fmOpenRead or fmShareDenyWrite);
    try
      FileSize := Reader.Size;
      BytesRead := Reader.Read(Buffer, 0, BufferSize);
      ActualBufferSize := BytesRead;
      if ActualBufferSize < BufferSize then
        FileEof := True;
      for var i := 0 to High(Patterns) do
        if Patterns[i].Size <= ActualBufferSize then
          Patterns[i].RollingHash := CalcHash (Buffer, Patterns[i].BufferOffset, Patterns[i].Size)
        else
        begin
          Patterns[i].Eof := True;
          Inc(EofCount);
        end;

      var Spinner := -1;
      while EofCount < Length(Patterns) do
      begin
        Spinner := (Spinner + 1) mod Length(Patterns);
        Pattern := @Patterns[Spinner];
        if Pattern.Eof then
          Continue;
        if Pattern.Hash = Pattern.RollingHash then
          if CompareMem(@(Pattern.Body[0]), @(Buffer[Pattern.BufferOffset]), Pattern.Size) then
            Pattern.Result.Add(Pattern.FileOffset + 1); // result position starts with 1
        ShiftWindow;
      end;

      if State = Cancelling then
        Abort;

      SaveResult;
      FFinishMoment := Now;
      NewState := Completed;
      PostLogMessage(NewState.ToString);
      State := NewState;
    finally
      FreeAndNil(Reader);
    end;
  except
    on EA: EAbort do
    begin
      SaveResult;
      FFinishMoment := Now;
      NewState := Cancelled;
      PostLogMessage(NewState.ToString);
      State := NewState;
    end;
    on E: Exception do
    begin
      SaveResult;
      FinishMoment := Now;
      NewState := Failed;
      PostLogMessage (Format('%s: <%s> %s', [NewState.ToString, E.ClassName, E.Message]));
      State := NewState;
    end;
  end;
end;

function TSearchInFileTask.GetDetails: Widestring;
begin
  Result := Format('Поиск в файле %s строк %s', [FParams.Filename, FPatternsAsString]);
end;

function TSearchInFileTask.GetResult: IResult;
begin
  Result := FResult;
end;

{ TInterfacedIntegerList }

function TInterfacedIntegerList.Add(const Item: Int64): Integer;
begin
  Result := FInnerList.Add(Item);
end;

constructor TInterfacedIntegerList.Create;
begin
  FInnerList := TList<Int64>.Create;
end;

destructor TInterfacedIntegerList.Destroy;
begin
  FreeAndNil(FInnerList);
  inherited;
end;

function TInterfacedIntegerList.GetCount: Integer;
begin
  Result := FInnerList.Count;
end;

function TInterfacedIntegerList.GetItem(Index: Integer): Int64;
begin
  Result := FInnerList[Index];
end;

procedure TInterfacedIntegerList.SetItem(Index: Integer; const Item: Int64);
begin
  FInnerList[Index] := Item;
end;

{ TSearchInFileResult }

constructor TSearchInFileResult.Create(const ResultName: string);
begin
  inherited Create(ResultName);
  FStringsValue := TStringsInternal.Create;
end;

function TSearchInFileResult.GetInternalValue: IListInternal<WideString>;
begin
  Result := FStringsValue;
end;

function TSearchInFileResult.GetStringsValue: IStrings;
begin
  Result := FStringsValue as IStrings;
end;

end.
