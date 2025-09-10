unit fSearchFilesParams;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Buttons, Vcl.Mask, System.Types, System.RegularExpressions, System.UITypes, System.IOUtils,
  System.Actions, Vcl.ActnList, Globals;

type
  TfrmSearchFilesParams = class(TForm)
    btOK: TButton;
    btCancel: TButton;
    Panel1: TPanel;
    txtFolder: TLabeledEdit;
    btFolder: TBitBtn;
    chkRecursive: TCheckBox;
    txtMask: TLabeledEdit;
    ActionList1: TActionList;
    lblErr: TLabel;
    actForm: TAction;
    procedure actFormUpdate(Sender: TObject);
    procedure btFolderClick(Sender: TObject);
  private
    FOrigParams: TSearchFileParams;
    procedure InitUI (aParams:TSearchFileParams);
    function CollectUI: TSearchFileParams;
  public
    function ShowModal (var aParams: TSearchFileParams): TModalResult; reintroduce;
  end;


implementation

{$R *.dfm}


{ TfrmSearchFilesParams }

procedure TfrmSearchFilesParams.actFormUpdate(Sender: TObject);
var
  E: string;
begin
  E := '';
  var C := CollectUI;
  btOK.Enabled := C.IsValid(E);
  lblErr.Caption := E;
end;

procedure TfrmSearchFilesParams.btFolderClick(Sender: TObject);
begin
  with TFileOpenDialog.Create(nil) do
  try
    Title := 'Выбрать папку';
    Options := [fdoPickFolders, fdoPathMustExist, fdoForceFileSystem];
    if Execute (Self.Handle) then
      txtFolder.Text := FileName;
  finally
    Free;
  end;
end;

function TfrmSearchFilesParams.CollectUI: TSearchFileParams;
begin
  with Result do
  begin
    Path := txtFolder.Text;
    Recursive := chkRecursive.Checked;
    MaskCombined := txtMask.Text;
  end;
end;

procedure TfrmSearchFilesParams.InitUI(aParams: TSearchFileParams);
begin
  with aParams do
  begin
    txtFolder.Text := Path;
    chkRecursive.Checked := Recursive;
    txtMask.Text := MaskCombined;
  end;
end;

function TfrmSearchFilesParams.ShowModal(var aParams: TSearchFileParams): TModalResult;
begin
  FOrigParams := aParams;
  InitUI (FOrigParams);
  Result := inherited ShowModal;
  if IsPositiveResult (Result) then
    aParams := CollectUI;
end;

end.
