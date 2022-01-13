object EmailOAuthDataModule: TEmailOAuthDataModule
  OldCreateOrder = False
  Height = 398
  Width = 729
  object IdConnectionInterceptSMTP: TIdConnectionIntercept
    OnReceive = IdConnectionInterceptSMTPReceive
    OnSend = IdConnectionInterceptSMTPSend
    Left = 88
    Top = 64
  end
  object IdSSLIOHandlerSocketSMTP: TIdSSLIOHandlerSocketOpenSSL
    Destination = ':25'
    MaxLineAction = maException
    Port = 25
    DefaultPort = 0
    SSLOptions.Method = sslvSSLv23
    SSLOptions.SSLVersions = [sslvTLSv1, sslvTLSv1_1, sslvTLSv1_2]
    SSLOptions.Mode = sslmUnassigned
    SSLOptions.VerifyMode = []
    SSLOptions.VerifyDepth = 0
    Left = 248
    Top = 56
  end
  object IdHTTPServer1: TIdHTTPServer
    Active = True
    Bindings = <>
    DefaultPort = 8546
    OnCommandGet = IdHTTPServer1CommandGet
    Left = 352
    Top = 120
  end
  object IdSMTP1: TIdSMTP
    IOHandler = IdSSLIOHandlerSocketSMTP
    SASLMechanisms = <>
    Left = 88
    Top = 128
  end
  object IdConnectionPOP: TIdConnectionIntercept
    Left = 96
    Top = 272
  end
  object IdSSLIOHandlerSocketPOP: TIdSSLIOHandlerSocketOpenSSL
    Destination = ':110'
    Intercept = IdConnectionPOP
    MaxLineAction = maException
    Port = 110
    DefaultPort = 0
    SSLOptions.Method = sslvTLSv1_2
    SSLOptions.SSLVersions = [sslvTLSv1_2]
    SSLOptions.Mode = sslmClient
    SSLOptions.VerifyMode = []
    SSLOptions.VerifyDepth = 0
    Left = 256
    Top = 264
  end
  object IdPOP3: TIdPOP3
    Intercept = IdConnectionPOP
    IOHandler = IdSSLIOHandlerSocketPOP
    AuthType = patSASL
    AutoLogin = False
    SASLMechanisms = <>
    Left = 456
    Top = 232
  end
end
