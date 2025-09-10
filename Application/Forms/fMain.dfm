object frmMain: TfrmMain
  Left = 0
  Top = 0
  Margins.Left = 5
  Margins.Top = 5
  Margins.Right = 5
  Margins.Bottom = 5
  Caption = 'frmMain'
  ClientHeight = 1196
  ClientWidth = 2115
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -21
  Font.Name = 'Segoe UI'
  Font.Style = []
  FormStyle = fsMDIForm
  Menu = MainMenu
  ShowHint = True
  OnCreate = FormCreate
  PixelsPerInch = 168
  TextHeight = 30
  object StatusBar: TStatusBar
    Left = 0
    Top = 1163
    Width = 2115
    Height = 33
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Panels = <
      item
        Text = 'P1'
        Width = 300
      end
      item
        Text = 'p2'
        Width = 300
      end
      item
        Text = 'p3'
        Width = 300
      end
      item
        Text = 
          '                                                                ' +
          '                                                                ' +
          '                                                                ' +
          '                                                                ' +
          '                          '
        Width = 5000
      end>
  end
  object MainMenu: TMainMenu
    Left = 266
    Top = 182
    object mnuFile: TMenuItem
      Caption = #1055#1086#1082#1072#1079#1072#1090#1100
      object mnuShowTaskList: TMenuItem
        Caption = #1057#1087#1080#1089#1086#1082' '#1086#1087#1077#1088#1072#1094#1080#1081
        OnClick = mnuShowTaskListClick
      end
    end
    object mnuExternal: TMenuItem
      Caption = #1050#1086#1084#1072#1085#1076#1099' '#1074#1085#1077#1096#1085#1080#1093' '#1084#1086#1076#1091#1083#1077#1081
    end
  end
end
