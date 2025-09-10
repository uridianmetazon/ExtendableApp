unit Globals;

interface

uses System.SysUtils, System.IOUtils, PluginHostApi;

type

  TGlobals = class
  public
    class var Host: IHost;
    class var Plugin: IPlugin;
  end;

  TSearchFileParams = record
    Path: string;
    Recursive: Boolean;
    MaskCombined: string;
    function TryParseMask (out Masks: TArray<string>; out ErrorMessage: string): Boolean;
    function IsValid (out ErrorMessage: string): Boolean;
  end;

  TSearchInFileParams = record
    Filename: TFileName;
    Patterns: TArray<string>;
    function IsValid (out ErrorMessage: string): Boolean;
  end;

implementation

function TSearchFileParams.IsValid(out ErrorMessage: string): Boolean;
var
  Masks: TArray<string>;
begin
  try
    ErrorMessage := '';

    if not TPath.HasValidPathChars(Path, False) then
    begin
      ErrorMessage := 'Путь к папке содержит недопустимые символы';
      Exit(False);
    end;

    if not TDirectory.Exists(Path) then
    begin
      ErrorMessage := 'Папка не существует';
      Exit(False);
    end;

    if not TryParseMask(Masks, ErrorMessage) then
      Exit(False);

    for var M in Masks do
      if not TPath.HasValidPathChars(M, True) then
      begin
        ErrorMessage := Format ('Недопустимый символ в маске или имени файла <%s>', [M]);
        Exit(False);
      end;

    Result := True;
  except on E: Exception do
    begin
      ErrorMessage := 'Ошибка проверки входных параметров: <' + E.ClassName + '> ' + E.Message;
      Result := False;
    end;
  end;
end;

function TSearchFileParams.TryParseMask (out Masks: TArray<string>; out ErrorMessage: string): Boolean;
begin
  try
    ErrorMessage := '';
    Masks := MaskCombined.Split([',']);
    Result := True;
  except on E: Exception do
    begin
      ErrorMessage := 'Невозможно разобрать строку с масками файлов: <' + E.ClassName + '> ' + E.Message;
      Result := False;
    end;
  end;
end;



{ TSearchInFileParams }

function TSearchInFileParams.IsValid(out ErrorMessage: string): Boolean;
begin
  ErrorMessage := '';
  if not FileExists(Filename) then
  begin
    ErrorMessage := 'Файл не существует';
    Exit(False);
  end;

  if Length(Patterns) = 0 then
  begin
    ErrorMessage := 'Нет строк для поиска';
    Exit(False);
  end;

  Result := True;
end;

end.
