object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Test OAUTH2 Gmail Send Message'
  ClientHeight = 377
  ClientWidth = 594
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    594
    377)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 440
    Top = 184
    Width = 68
    Height = 13
    Anchors = [akTop, akRight]
    Caption = 'Path attached'
  end
  object Memo1: TMemo
    Left = 8
    Top = 72
    Width = 409
    Height = 182
    Anchors = [akLeft, akTop, akBottom]
    Lines.Strings = (
      'Memo1')
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object btnAuthenticate: TButton
    Left = 423
    Top = 8
    Width = 106
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Authenticate'
    TabOrder = 1
    OnClick = btnAuthenticateClick
  end
  object btnSendMsg: TButton
    Left = 423
    Top = 95
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Send MSG'
    TabOrder = 2
    OnClick = btnSendMsgClick
  end
  object rgEmailProviders: TRadioGroup
    Left = 8
    Top = 8
    Width = 409
    Height = 58
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Provider'
    Columns = 2
    ItemIndex = 0
    Items.Strings = (
      'GMail'
      'Microsoft')
    TabOrder = 3
  end
  object btnCheckMsg: TButton
    Left = 423
    Top = 136
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Check MSG'#39's'
    TabOrder = 4
    OnClick = btnCheckMsgClick
  end
  object btnClearAuthToken: TButton
    Left = 423
    Top = 39
    Width = 106
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Clear Auth Token'
    TabOrder = 5
    OnClick = btnClearAuthTokenClick
  end
  object AtachedPath: TEdit
    Left = 432
    Top = 208
    Width = 121
    Height = 21
    Anchors = [akTop, akRight]
    TabOrder = 6
    Text = '..\..\README.md'
  end
end
