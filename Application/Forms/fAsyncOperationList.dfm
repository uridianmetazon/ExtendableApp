object frmAsyncOperationList: TfrmAsyncOperationList
  Left = 0
  Top = 0
  Margins.Left = 5
  Margins.Top = 5
  Margins.Right = 5
  Margins.Bottom = 5
  Caption = #1057#1087#1080#1089#1086#1082' '#1086#1087#1077#1088#1072#1094#1080#1081
  ClientHeight = 780
  ClientWidth = 1036
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -21
  Font.Name = 'Segoe UI'
  Font.Style = []
  FormStyle = fsMDIChild
  Visible = True
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 168
  TextHeight = 30
  object Splitter1: TSplitter
    Left = 0
    Top = 444
    Width = 1036
    Height = 8
    Cursor = crVSplit
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alBottom
    MinSize = 53
    ExplicitTop = 708
    ExplicitWidth = 1193
  end
  object ControlList: TControlList
    Left = 0
    Top = 78
    Width = 1036
    Height = 366
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alClient
    ItemHeight = 240
    ItemMargins.Left = 0
    ItemMargins.Top = 0
    ItemMargins.Right = 0
    ItemMargins.Bottom = 0
    ParentColor = False
    TabOrder = 0
    OnShowControl = ControlListShowControl
    object lblOperationName: TLabel
      Left = 0
      Top = 0
      Width = 1032
      Height = 30
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Align = alTop
      Caption = 'lblOperationName'
      ExplicitWidth = 171
    end
    object lblOperationState: TLabel
      Left = 0
      Top = 30
      Width = 1032
      Height = 30
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Align = alTop
      Caption = 'lblOperationState'
      ExplicitWidth = 161
    end
    object lblDetails: TLabel
      Left = 0
      Top = 150
      Width = 1032
      Height = 30
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Align = alTop
      Caption = 'lblDetails'
      ExplicitWidth = 85
    end
    object lblStartMoment: TLabel
      Left = 0
      Top = 60
      Width = 1032
      Height = 30
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Align = alTop
      Caption = 'lblStartMoment'
      ExplicitWidth = 143
    end
    object lblFinishMoment: TLabel
      Left = 0
      Top = 90
      Width = 1032
      Height = 30
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Align = alTop
      Caption = 'lblFinishMoment'
      ExplicitWidth = 154
    end
    object lblResult: TLabel
      Left = 0
      Top = 120
      Width = 1032
      Height = 30
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Align = alTop
      Caption = 'lblResult'
      ExplicitWidth = 78
    end
    object btCancel: TControlListButton
      Left = 14
      Top = 183
      Width = 246
      Height = 44
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = #1055#1088#1077#1088#1074#1072#1090#1100' '#1074#1099#1087#1086#1083#1085#1077#1085#1080#1077
      OnClick = btCancelClick
    end
    object btShowLog: TControlListButton
      Left = 280
      Top = 182
      Width = 246
      Height = 45
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = #1055#1086#1082#1072#1079#1072#1090#1100' '#1083#1086#1075
      OnClick = btShowLogClick
    end
    object btShowResult: TControlListButton
      Left = 546
      Top = 182
      Width = 246
      Height = 45
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = #1055#1086#1082#1072#1079#1072#1090#1100' '#1088#1077#1079#1091#1083#1100#1090#1072#1090
      OnClick = btShowResultClick
    end
  end
  object FilterPanel: TPanel
    Left = 0
    Top = 0
    Width = 1036
    Height = 78
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alTop
    TabOrder = 1
    object Filter: TRadioGroup
      Left = 1
      Top = 1
      Width = 378
      Height = 77
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = #1055#1086#1082#1072#1079#1099#1074#1072#1090#1100' '#1079#1072#1076#1072#1095#1080
      Columns = 2
      ItemIndex = 1
      Items.Strings = (
        #1040#1082#1090#1080#1074#1085#1099#1077
        #1047#1072#1074#1077#1088#1096#1077#1085#1085#1099#1077)
      TabOrder = 0
      OnClick = FilterClick
    end
  end
  object LogPanel: TPanel
    Left = 0
    Top = 452
    Width = 1036
    Height = 328
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alBottom
    Caption = 'LogPanel'
    TabOrder = 2
    object lblRowCount: TLabel
      Left = 1
      Top = 297
      Width = 1034
      Height = 30
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Align = alBottom
      ExplicitWidth = 6
    end
    object TabControl: TTabControl
      Left = 1
      Top = 1
      Width = 1034
      Height = 36
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Align = alTop
      TabOrder = 0
      Tabs.Strings = (
        #1051#1086#1075' '#1074#1099#1087#1086#1083#1085#1077#1085#1080#1103
        #1056#1077#1079#1091#1083#1100#1090#1072#1090' '#1074#1099#1087#1086#1083#1085#1077#1085#1080#1103)
      TabIndex = 0
      OnChange = TabControlChange
    end
    object grdLog: TDBGrid
      Left = 1
      Top = 37
      Width = 1034
      Height = 260
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Align = alClient
      DataSource = dsLog
      TabOrder = 1
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -21
      TitleFont.Name = 'Segoe UI'
      TitleFont.Style = []
      Columns = <
        item
          Expanded = False
          FieldName = 'Moment'
          Width = 235
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'Text'
          Width = 500
          Visible = True
        end>
    end
    object grdResultStrings: TDBGrid
      Left = 1
      Top = 37
      Width = 1034
      Height = 260
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Align = alClient
      DataSource = dsResultStrings
      TabOrder = 2
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -21
      TitleFont.Name = 'Segoe UI'
      TitleFont.Style = []
      Columns = <
        item
          Expanded = False
          FieldName = 'Text'
          Width = 500
          Visible = True
        end>
    end
  end
  object dsLog: TDataSource
    AutoEdit = False
    Left = 525
    Top = 641
  end
  object dsResultStrings: TDataSource
    AutoEdit = False
    Left = 693
    Top = 641
  end
end
