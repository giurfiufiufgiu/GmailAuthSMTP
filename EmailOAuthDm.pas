unit EmailOAuthDm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.Forms,
  Vcl.Dialogs,
  IPPeerClient,
  Data.Bind.Components,
  Data.Bind.ObjectScope,
  REST.Client,
  IdCustomTCPServer,
  IdCustomHTTPServer,
  IdHTTPServer,
  IdContext,
  IdSASLCollection,
  IdSASLXOAUTH,
  IdOAuth2Bearer,
  Vcl.ExtCtrls,
  IdPOP3,
  IniFiles ,
  Globals.Sample,
  IdIntercept, IdGlobal, IdIOHandler, IdIOHandlerSocket,
  IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdExplicitTLSClientServerBase, IdMessageClient,
  IdSMTPBase, IdSMTP,REST.Authenticator.OAuth,IdSASL ;

type
  TEmailProvider = (epGmail = 0 ,epOutlook = 1);
  PtrUInt = NativeUInt;

    TAuthType = class of TIdSASL;

  TProviderInfo = record
    AuthenticationType : TAuthType;
    AuthorizationEndpoint : string;
    AccessTokenEndpoint : string;
    ClientID : String;
    ClientSecret : string;
    ClientAccount : string;
    Scopes : string;
    SmtpHost : string;
    SmtpPort : Integer;
    PopHost : string;
    PopPort : Integer;
    AuthName : string;
    TLS : TIdUseTLS;
  end;
const
  clientredirect = 'http://localhost:8546';

  Providers : array[0..1] of TProviderInfo =
  (
    (  AuthenticationType : TIdOAuth2Bearer;
       AuthorizationEndpoint : 'https://accounts.google.com/o/oauth2/auth';
       AccessTokenEndpoint : 'https://accounts.google.com/o/oauth2/token';
       ClientID : google_clientid;
       ClientSecret : google_clientsecret;
       ClientAccount : google_clientAccount;  // your @gmail.com email address
       Scopes : 'https://mail.google.com/ openid';
       SmtpHost : 'smtp.gmail.com';
       SmtpPort : 465;
       PopHost : 'pop.gmail.com';
       PopPort : 995;
       AuthName : 'Google';
       TLS : utUseImplicitTLS
    ),
    (  AuthenticationType : TIdSASLXOAuth;
       AuthorizationEndpoint : 'https://login.live.com/oauth20_authorize.srf';
       AccessTokenEndpoint : 'https://login.live.com/oauth20_token.srf';
       ClientID : microsoft_clientid;
       ClientSecret : '';
       ClientAccount : microsoft_clientAccount; // your @live.com or @hotmail.com email address
       Scopes : 'wl.imap offline_access';
       SmtpHost : 'smtp.office365.com';
       SmtpPort : 587;
       PopHost : 'outlook.office365.com';
       PopPort : 995;
       AuthName : 'Microsoft';
       TLS : utUseImplicitTLS
    )
  );

  type

  TEnhancedOAuth2Authenticator = class (TOAuth2Authenticator)
  private
    procedure RequestAccessToken;
  public
    IDToken : string;
    procedure ChangeAuthCodeToAccesToken;
    procedure RefreshAccessTokenIfRequired;
  end;
type
  TEmailOAuthDataModule = class(TDataModule)
    IdConnectionInterceptSMTP: TIdConnectionIntercept;
    IdSSLIOHandlerSocketSMTP: TIdSSLIOHandlerSocketOpenSSL;
    IdHTTPServer1: TIdHTTPServer;
    IdSMTP1: TIdSMTP;
    IdConnectionPOP: TIdConnectionIntercept;
    IdSSLIOHandlerSocketPOP: TIdSSLIOHandlerSocketOpenSSL;
    IdPOP3: TIdPOP3;
    procedure IdConnectionInterceptSMTPReceive(ASender: TIdConnectionIntercept;
      var ABuffer: TIdBytes);
    procedure IdConnectionInterceptSMTPSend(ASender: TIdConnectionIntercept;
      var ABuffer: TIdBytes);
    procedure IdHTTPServer1CommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
  private
    EmailProvider:TEmailProvider;
    OAuth2_Enhanced : TEnhancedOAuth2Authenticator;
    IniSettings : TIniFile;
    isAuthenticate:boolean;
    Memo1:TMemo;
    procedure SetupAuthenticator;
  public
    function getisAuthenticate:boolean;
    procedure Authenticate;
    procedure ClearAuthToken;
    procedure SendMessage(Memo1:TMemo;Path:String);
    procedure CheckMessage(memo1:TMemo);
    constructor Create(AOwner: TComponent;ep:TEmailProvider;var Memo:TMemo); reintroduce;virtual;
    destructor Destroy;override;
  end;


implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

USES REST.Types,System.DateUtils,REST.Consts,System.Net.URLClient,
  System.NetEncoding,
  REST.Utils,
  Winapi.ShellAPI,
  IdAttachmentFile
  , DecryptEncrypt, Unit2,
  IdMessage;

const
  SClientIDNeeded = 'An ClientID is needed before a token can be requested';
  SRefreshTokenNeeded = 'An Refresh Token is needed before an Access Token can be requested';

{TEnhancedOAuth2Authenticator}
procedure TEnhancedOAuth2Authenticator.RefreshAccessTokenIfRequired;
begin
  if AccessTokenExpiry < now then
  begin
    RequestAccessToken;
  end;
end;

procedure TEnhancedOAuth2Authenticator.RequestAccessToken;
var
  LClient: TRestClient;
  LRequest: TRESTRequest;
  LToken: string;
  LIntValue: int64;
begin

  // we do need an clientid here, because we want
  // to send it to the servce and exchange the code into an
  // access-token.
  if ClientID = '' then
    raise EOAuth2Exception.Create(SClientIDNeeded);

  if RefreshToken = '' then
    raise EOAuth2Exception.Create(SRefreshTokenNeeded);

  LClient := TRestClient.Create(AccessTokenEndpoint);
  try
    LRequest := TRESTRequest.Create(LClient); // The LClient now "owns" the Request and will free it.
    LRequest.Method := TRESTRequestMethod.rmPOST;

    LRequest.AddAuthParameter('refresh_token', RefreshToken, TRESTRequestParameterKind.pkGETorPOST);
    LRequest.AddAuthParameter('client_id', ClientID, TRESTRequestParameterKind.pkGETorPOST);
    LRequest.AddAuthParameter('client_secret', ClientSecret, TRESTRequestParameterKind.pkGETorPOST);
    LRequest.AddAuthParameter('grant_type', 'refresh_token', TRESTRequestParameterKind.pkGETorPOST);

    LRequest.Execute;

    if LRequest.Response.GetSimpleValue('access_token', LToken) then
      AccessToken := LToken;
    if LRequest.Response.GetSimpleValue('refresh_token', LToken) then
      RefreshToken := LToken;
    if LRequest.Response.GetSimpleValue('id_token', LToken) then
      IDToken := LToken;

    // detect token-type. this is important for how using it later
    if LRequest.Response.GetSimpleValue('token_type', LToken) then
      TokenType := OAuth2TokenTypeFromString(LToken);

    // if provided by the service, the field "expires_in" contains
    // the number of seconds an access-token will be valid
    if LRequest.Response.GetSimpleValue('expires_in', LToken) then
    begin
      LIntValue := StrToIntdef(LToken, -1);
      if (LIntValue > -1) then
        AccessTokenExpiry := IncSecond(Now, LIntValue)
      else
        AccessTokenExpiry := 0.0;
    end;

    // an authentication-code may only be used once.
    // if we succeeded here and got an access-token, then
    // we do clear the auth-code as is is not valid anymore
    // and also not needed anymore.
    if (AccessToken <> '') then
    begin
      AuthCode := '';
    end;
  finally
    LClient.DisposeOf;
  end;
end;


// This function is basically a copy of the ancestor... but is need so we can also get the id_token value.
procedure TEnhancedOAuth2Authenticator.ChangeAuthCodeToAccesToken;
var
  LClient: TRestClient;
  LRequest: TRESTRequest;
  LToken: string;
  LIntValue: int64;
begin

  // we do need an authorization-code here, because we want
  // to send it to the servce and exchange the code into an
  // access-token.
  if AuthCode = '' then
    raise EOAuth2Exception.Create(SAuthorizationCodeNeeded);

  LClient := TRestClient.Create(AccessTokenEndpoint);
  try
    LRequest := TRESTRequest.Create(LClient); // The LClient now "owns" the Request and will free it.
    LRequest.Method := TRESTRequestMethod.rmPOST;
    // LRequest.Client := LClient; // unnecessary since the client "owns" the request it will assign the client

    LRequest.AddAuthParameter('code', AuthCode, TRESTRequestParameterKind.pkGETorPOST);
    LRequest.AddAuthParameter('client_id', ClientID, TRESTRequestParameterKind.pkGETorPOST);
    LRequest.AddAuthParameter('client_secret', ClientSecret, TRESTRequestParameterKind.pkGETorPOST);
    LRequest.AddAuthParameter('redirect_uri', RedirectionEndpoint, TRESTRequestParameterKind.pkGETorPOST);
    LRequest.AddAuthParameter('grant_type', 'authorization_code', TRESTRequestParameterKind.pkGETorPOST);

    LRequest.Execute;

    if LRequest.Response.GetSimpleValue('access_token', LToken) then
      AccessToken := LToken;
    if LRequest.Response.GetSimpleValue('refresh_token', LToken) then
      RefreshToken := LToken;
    if LRequest.Response.GetSimpleValue('id_token', LToken) then
      IDToken := LToken;


    // detect token-type. this is important for how using it later
    if LRequest.Response.GetSimpleValue('token_type', LToken) then
      TokenType := OAuth2TokenTypeFromString(LToken);

    // if provided by the service, the field "expires_in" contains
    // the number of seconds an access-token will be valid
    if LRequest.Response.GetSimpleValue('expires_in', LToken) then
    begin
      LIntValue := StrToIntdef(LToken, -1);
      if (LIntValue > -1) then
        AccessTokenExpiry := IncSecond(Now, LIntValue)
      else
        AccessTokenExpiry := 0.0;
    end;

    // an authentication-code may only be used once.
    // if we succeeded here and got an access-token, then
    // we do clear the auth-code as is is not valid anymore
    // and also not needed anymore.
    if (AccessToken <> '') then
      AuthCode := '';
  finally
    LClient.DisposeOf;
  end;

end;
{TEnhancedOAuth2Authenticator end}


{ TEmailOAuthDataModule }

procedure TEmailOAuthDataModule.Authenticate;
var
  uri : TURI;
begin
  if isAuthenticate then
    exit;
  uri := TURI.Create(OAuth2_Enhanced.AuthorizationRequestURI);
  if EmailProvider = epGmail then
    uri.AddParameter('access_type', 'offline');  // For Google to get refresh_token
  memo1.Lines.Add('opening Browser');
  ShellExecute(Application.Handle,//we need handle from the form if this doesnt work
    'open',
    PChar(uri.ToString),
    nil,
    nil,
    0
  );
end;

procedure TEmailOAuthDataModule.CheckMessage(memo1:TMemo);
var
  xoauthSASL : TIdSASLListEntry;
  msgCount : Integer;
begin

  Memo1.Lines.Add('refresh_token=' + OAuth2_Enhanced.RefreshToken);
  Memo1.Lines.Add('access_token=' + OAuth2_Enhanced.AccessToken);

  if OAuth2_Enhanced.AccessToken.Length = 0 then
  begin
    Memo1.Lines.Add('Failed to authenticate properly');
    Exit;
  end;

  IdPOP3.Host := Providers[ord(EmailProvider)].PopHost;
  IdPOP3.Port := Providers[ord(EmailProvider)].PopPort;
  IdPOP3.UseTLS := Providers[ord(EmailProvider)].TLS;

  xoauthSASL := IdPOP3.SASLMechanisms.Add;
  xoauthSASL.SASL := Providers[ord(EmailProvider)].AuthenticationType.Create(nil);

  if xoauthSASL.SASL is TIdOAuth2Bearer then
  begin
    TIdOAuth2Bearer(xoauthSASL.SASL).Token := OAuth2_Enhanced.AccessToken;
    TIdOAuth2Bearer(xoauthSASL.SASL).Host := IdPOP3.Host;
    TIdOAuth2Bearer(xoauthSASL.SASL).Port := IdPOP3.Port;
    TIdOAuth2Bearer(xoauthSASL.SASL).User := Providers[ord(EmailProvider)].ClientAccount;
  end
  else if xoauthSASL.SASL is TIdSASLXOAuth then
  begin
    TIdSASLXOAuth(xoauthSASL.SASL).Token := OAuth2_Enhanced.AccessToken;
    TIdSASLXOAuth(xoauthSASL.SASL).User := Providers[ord(EmailProvider)].ClientAccount;
  end;

  IdPOP3.AuthType := patSASL;
  IdPOP3.Connect;
  IdPOP3.CAPA;
  IdPOP3.Login;

  msgCount := IdPOP3.CheckMessages;

  ShowMessage(msgCount.ToString + ' Messages available for download');

  IdPOP3.Disconnect;
end;

procedure TEmailOAuthDataModule.ClearAuthToken;
var
  LTokenName : string;
begin
  if not isAuthenticate then
    exit;
  // Delete persistent Refresh_token.  Note
  //  - This probably should have a logout function called on it
  //  - The token should be stored in an encrypted way ... but this is just a demo.
  LTokenName := Providers[ord(EmailProvider)].AuthName + 'Token';
  IniSettings.DeleteKey(EncryptStr('Authentication'), EncryptStr(LTokenName));
  SetupAuthenticator;
end;

constructor TEmailOAuthDataModule.Create(AOwner: TComponent;ep:TEmailProvider;var Memo:TMemo);
var
  LFilename : string;
begin
  inherited create(AOwner);
  LFilename := ChangeFileExt(ParamStr(0),'.ini');
  IniSettings := TIniFile.Create(LFilename);

  OAuth2_Enhanced := TEnhancedOAuth2Authenticator.Create(nil);
  SetupAuthenticator;

  EmailProvider:=ep;
  Memo1:= Memo;
  SetupAuthenticator;
end;

destructor TEmailOAuthDataModule.Destroy;
begin
  FreeAndNil(IniSettings);
  FreeAndNil(OAuth2_Enhanced);

  inherited;
end;

function TEmailOAuthDataModule.getisAuthenticate: boolean;
begin
  Result := isAuthenticate;
end;

procedure TEmailOAuthDataModule.IdConnectionInterceptSMTPReceive(
  ASender: TIdConnectionIntercept; var ABuffer: TIdBytes);
begin
  Memo1.Lines.Add('R:' + TEncoding.ASCII.GetString(ABuffer));
end;

procedure TEmailOAuthDataModule.IdConnectionInterceptSMTPSend(
  ASender: TIdConnectionIntercept; var ABuffer: TIdBytes);
begin
  Memo1.Lines.Add('S:' + TEncoding.ASCII.GetString(ABuffer));
end;

procedure TEmailOAuthDataModule.IdHTTPServer1CommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  LCode: string;
  LURL : TURI;
  LTokenName : string;
begin
  if ARequestInfo.QueryParams = '' then
    Exit;
  LURL := TURI.Create('https://localhost/?' + ARequestInfo.QueryParams);
  try
    LCode := LURL.ParameterByName['code'];
  except
    Exit;
  end;
  OAuth2_Enhanced.AuthCode := LCode;
  OAuth2_Enhanced.ChangeAuthCodeToAccesToken;
  LTokenName := Providers[ord(EmailProvider)].AuthName + 'Token';
  IniSettings.WriteString(EncryptStr('Authentication'), EncryptStr(LTokenName), EncryptStr(OAuth2_Enhanced.RefreshToken));
  Memo1.Lines.Add('Authenticated via OAUTH2');
  SetupAuthenticator;
end;

procedure TEmailOAuthDataModule.SendMessage(Memo1:TMemo;Path:String);
var
  IdMessage: TIdMessage;
  Attachment: TIdAttachmentFile;
  xoauthSASL : TIdSASLListEntry;
begin
  IdSMTP1.AuthType := satNone;

  // if we only have refresh_token or access token has expired
  // request new access_token to use with request
  OAuth2_Enhanced.RefreshAccessTokenIfRequired;

  Memo1.Lines.Add('refresh_token=' + OAuth2_Enhanced.RefreshToken);
  Memo1.Lines.Add('access_token=' + OAuth2_Enhanced.AccessToken);

  if OAuth2_Enhanced.AccessToken.Length = 0 then
  begin
    Memo1.Lines.Add('Failed to authenticate properly');
    Exit;
  end;

  IdSMTP1.Host := Providers[ord(EmailProvider)].SmtpHost;
  IdSMTP1.Port := Providers[ord(EmailProvider)].SmtpPort;
  IdSMTP1.UseTLS := Providers[ord(EmailProvider)].TLS;

  xoauthSASL := IdSMTP1.SASLMechanisms.Add;
  xoauthSASL.SASL := Providers[ord(EmailProvider)].AuthenticationType.Create(nil);

  if xoauthSASL.SASL is TIdOAuth2Bearer then
  begin
    TIdOAuth2Bearer(xoauthSASL.SASL).Token := OAuth2_Enhanced.AccessToken;
    TIdOAuth2Bearer(xoauthSASL.SASL).Host := IdSMTP1.Host;
    TIdOAuth2Bearer(xoauthSASL.SASL).Port := IdSMTP1.Port;
    TIdOAuth2Bearer(xoauthSASL.SASL).User := Providers[ord(EmailProvider)].ClientAccount;
  end
  else if xoauthSASL.SASL is TIdSASLXOAuth then
  begin
    TIdSASLXOAuth(xoauthSASL.SASL).Token := OAuth2_Enhanced.AccessToken;
    TIdSASLXOAuth(xoauthSASL.SASL).User := Providers[ord(EmailProvider)].ClientAccount;
  end;


  IdSMTP1.Connect;
  IdSMTP1.AuthType := satSASL;
  IdSMTP1.Authenticate;

  IdMessage := TIdMessage.Create(Self);
  IdMessage.From.Address := Providers[ord(EmailProvider)].ClientAccount;
  IdMessage.From.Name := clientname;
  IdMessage.ReplyTo.EMailAddresses := IdMessage.From.Address;
  IdMessage.Recipients.Add.Text := clientsendtoaddress;
  IdMessage.Subject := 'Sending Message';
  IdMessage.Body.Text := 'with Attachment ' + Path;
  if FileExists(Path) then
    Attachment := TIdAttachmentFile.Create(IdMessage.MessageParts, Path);


  IdSMTP1.Send(IdMessage);

  IdSMTP1.Disconnect;
  if FileExists(Path) then
    FreeAndNil(Attachment);
  FreeAndNil(IdMessage);
end;

procedure TEmailOAuthDataModule.SetupAuthenticator;
var
  token,LTokenName : string;

begin
  OAuth2_Enhanced.ClientID := Providers[ord(EmailProvider)].ClientID;
  OAuth2_Enhanced.ClientSecret := Providers[ord(EmailProvider)].Clientsecret;
  OAuth2_Enhanced.Scope := Providers[ord(EmailProvider)].Scopes;
  OAuth2_Enhanced.RedirectionEndpoint := clientredirect;
  OAuth2_Enhanced.AuthorizationEndpoint := Providers[ord(EmailProvider)].AuthorizationEndpoint;
  OAuth2_Enhanced.AccessTokenEndpoint := Providers[ord(EmailProvider)].AccessTokenEndpoint;

  LTokenName := Providers[ord(EmailProvider)].AuthName + 'Token';

  token := DecryptStr(IniSettings.ReadString(
  EncryptStr('Authentication'),
  EncryptStr(LTokenName),
  ''));
  OAuth2_Enhanced.RefreshToken:=token;
  LTokenName := Providers[ord(EmailProvider)].AuthName + 'Token';
  isAuthenticate:= token.Length > 0;
//  isClearAuthToken := not isAuthenticate;
end;




end.
