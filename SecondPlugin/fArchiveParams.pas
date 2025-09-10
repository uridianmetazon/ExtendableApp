unit fArchiveParams;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons,
  Vcl.Mask, Vcl.ExtCtrls, Globals, System.UITypes, System.Actions,
  Vcl.ActnList;

type
  TfrmArchiveParams = class(TForm)
    btOK: TButton;
    btCancel: TButton;
    Panel1: TPanel;
    txtTarget: TLabeledEdit;
    txtSource: TLabeledEdit;
    btTarget: TBitBtn;
    btSource: TBitBtn;
    lblErrMsg: TLabel;
    ActionList1: TActionList;
    aForm: TAction;
    chkDetailedReport: TCheckBox;
    Label1: TLabel;
    txtCommandLine: TEdit;
    procedure aFormUpdate(Sender: TObject);
    procedure aTargetExecute(Sender: TObject);
    procedure aSourceExecute(Sender: TObject);
  private
    FOrigParams: TArchiveParams;
    procedure InitUI (aParams: TArchiveParams);
    function CollectUI: TArchiveParams;
  public
    function ShowModal(var aParams: TArchiveParams): TModalResult; reintroduce;
  end;

var
  frmArchiveParams: TfrmArchiveParams;

implementation

{$R *.dfm}

procedure TfrmArchiveParams.aFormUpdate(Sender: TObject);
var
  ErrMsg: string;
begin
  var UI := CollectUI;
  btOk.Enabled := UI.IsValid(ErrMsg);
  if ErrMsg > '' then
    lblErrMsg.Caption := ErrMsg
  else
    lblErrMsg.Caption := '';

  var CommandLine := UI.CommandLine;
  if not btOk.Enabled then
    txtCommandLine.Text := ''
  else
    if not AnsiSameText(txtCommandLine.Text, CommandLine) then
      txtCommandLine.Text := CommandLine;
end;

procedure TfrmArchiveParams.aSourceExecute(Sender: TObject);
begin
  with TFileOpenDialog.Create(nil) do
  try
    Title := 'Выбрать файл';
    //Options := [fdoPathMustExist];
    if Execute (Self.Handle) then
      txtSource.Text := FileName;
  finally
    Free;
  end;
end;

procedure TfrmArchiveParams.aTargetExecute(Sender: TObject);
begin
  with TFileSaveDialog.Create(nil) do
  try
    Title := 'Имя архива';
    Options := Options + [fdoStrictFileTypes];
    DefaultExtension := 'zip';
    if Execute (Self.Handle) then
      txtTarget.Text := FileName;
  finally
    Free;
  end;
end;

function TfrmArchiveParams.CollectUI: TArchiveParams;
begin
  Result.TargetFileName := txtTarget.Text;
  Result.SourcePath := txtSource.Text;
  Result.DetailedReport := chkDetailedReport.Checked;
end;

procedure TfrmArchiveParams.InitUI(aParams: TArchiveParams);
var
  ErrMsg: string;
begin
  txtTarget.Text := aParams.TargetFileName;
  txtSource.Text := aParams.SourcePath;
  chkDetailedReport.Checked := aParams.DetailedReport;
  if aParams.IsValid(ErrMsg) then
    txtCommandLine.Text := aParams.CommandLine
  else
    lblErrMsg.Caption := ErrMsg;
end;

function TfrmArchiveParams.ShowModal(var aParams: TArchiveParams): TModalResult;
begin
  FOrigParams := aParams;
  InitUI(FOrigParams);
  Result := inherited ShowModal;
  if IsPositiveResult(Result) then
    aParams := CollectUI;
end;

end.
