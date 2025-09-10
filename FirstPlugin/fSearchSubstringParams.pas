unit fSearchSubstringParams;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Mask, Vcl.Buttons, Globals, System.Actions, Vcl.ActnList, System.UITypes;

type
  TfrmSearchSubstringParams = class(TForm)
    btOk: TButton;
    Button2: TButton;
    Panel1: TPanel;
    txtFileName: TLabeledEdit;
    btFileName: TBitBtn;
    lstPatterns: TListBox;
    ActionList1: TActionList;
    aForm: TAction;
    lblError: TLabel;
    txtPattern: TLabeledEdit;
    btAdd: TBitBtn;
    btDel: TBitBtn;
    aAdd: TAction;
    aDel: TAction;
    BitBtn1: TBitBtn;
    aClear: TAction;
    procedure aFormUpdate(Sender: TObject);
    procedure aAddUpdate(Sender: TObject);
    procedure aAddExecute(Sender: TObject);
    procedure aDelUpdate(Sender: TObject);
    procedure aDelExecute(Sender: TObject);
    procedure lstPatternsClick(Sender: TObject);
    procedure btFileNameClick(Sender: TObject);
    procedure aClearUpdate(Sender: TObject);
    procedure aClearExecute(Sender: TObject);
  private
    FOrigParams: TSearchInFileParams;
    procedure InitUI (aParams:TSearchInFileParams);
    function CollectUI: TSearchInFileParams;
  public
    function ShowModal (var aParams: TSearchInFileParams): TModalResult; reintroduce;
  end;

implementation

{$R *.dfm}

{ TfrmSearchSubstringParams }

procedure TfrmSearchSubstringParams.aAddExecute(Sender: TObject);
begin
  var I := lstPatterns.Items.IndexOf(txtPattern.Text);
  if I < 0 then
    lstPatterns.Items.Add(txtPattern.Text)
  else
    lstPatterns.ItemIndex := I;
end;

procedure TfrmSearchSubstringParams.aAddUpdate(Sender: TObject);
begin
  aAdd.Enabled := (txtPattern.Text > '') and (lstPatterns.Items.IndexOf(txtPattern.Text) < 0);
end;

procedure TfrmSearchSubstringParams.aClearExecute(Sender: TObject);
begin
  lstPatterns.Clear;
end;

procedure TfrmSearchSubstringParams.aClearUpdate(Sender: TObject);
begin
  aClear.Enabled := lstPatterns.Items.Count > 0;
end;

procedure TfrmSearchSubstringParams.aDelExecute(Sender: TObject);
begin
  lstPatterns.Items.Delete(lstPatterns.ItemIndex);
end;

procedure TfrmSearchSubstringParams.aDelUpdate(Sender: TObject);
begin
  aDel.Enabled := lstPatterns.ItemIndex >= 0;
end;

procedure TfrmSearchSubstringParams.aFormUpdate(Sender: TObject);
var
  ErrMsg: string;
begin
  btOk.Enabled := CollectUI.IsValid(ErrMsg);
  lblError.Caption := ErrMsg;
end;

procedure TfrmSearchSubstringParams.btFileNameClick(Sender: TObject);
begin
  with TFileOpenDialog.Create(nil) do
  try
    Title := 'Выбрать файл';
    Options := [fdoFileMustExist, fdoForceFileSystem];
    if Execute (Self.Handle) then
      txtFileName.Text := FileName;
  finally
    Free;
  end;
end;

function TfrmSearchSubstringParams.CollectUI: TSearchInFileParams;
begin
  Result.Filename := txtFileName.Text;
  Result.Patterns := lstPatterns.Items.ToStringArray;
end;

procedure TfrmSearchSubstringParams.InitUI(aParams: TSearchInFileParams);
begin
  txtFileName.Text := aParams.Filename;
  lstPatterns.Clear;
  lstPatterns.Items.AddStrings(aParams.Patterns);
end;

procedure TfrmSearchSubstringParams.lstPatternsClick(Sender: TObject);
begin
  if lstPatterns.ItemIndex >= 0 then
    txtPattern.Text := lstPatterns.Items[lstPatterns.ItemIndex];
end;

function TfrmSearchSubstringParams.ShowModal(var aParams: TSearchInFileParams): TModalResult;
begin
  FOrigParams := aParams;
  InitUI (FOrigParams);
  Result := inherited ShowModal;
  if IsPositiveResult (Result) then
    aParams := CollectUI;
end;

end.
