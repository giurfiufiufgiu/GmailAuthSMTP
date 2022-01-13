unit Unit2;

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
  IdBaseComponent,
  IdComponent,
  IdTCPConnection,
  IdTCPClient,
  IdExplicitTLSClientServerBase,
  IdMessageClient,
  IdMessage,
  IdSMTPBase,
  IdSMTP,
  IdSASL,
  IdIOHandler,
  IdIOHandlerSocket,
  IdIOHandlerStack,
  IdSSL,
  IdSSLOpenSSL,
  IdIntercept,
  IdGlobal,
  Data.Bind.Components,
  Data.Bind.ObjectScope,
  REST.Client,
  IdCustomTCPServer,
  IdCustomHTTPServer,
  IdHTTPServer,
  REST.Authenticator.OAuth,
  IdContext,
  IdSASLCollection,
  IdSASLXOAUTH,
  IdOAuth2Bearer,
  Vcl.ExtCtrls,
  IdPOP3,
  IniFiles,
  Globals.Sample, EmailOAuthDm  ;

type



  TForm2 = class(TForm)
    Memo1: TMemo;
    btnAuthenticate: TButton;
    btnSendMsg: TButton;
    rgEmailProviders: TRadioGroup;
    btnCheckMsg: TButton;
    btnClearAuthToken: TButton;
    AtachedPath: TEdit;
    Label1: TLabel;
    procedure btnAuthenticateClick(Sender: TObject);
    procedure btnSendMsgClick(Sender: TObject);
    procedure btnCheckMsgClick(Sender: TObject);
    procedure btnClearAuthTokenClick(Sender: TObject);
    procedure updateButtonsEnabled;
  private
    { Private declarations }
  public
    EmailOAuthDataModule:TEmailOAuthDataModule;
    constructor Create(AOwner: TComponent); override;
    destructor Destory(AOwner: TComponent); virtual;
  end;



var
  Form2: TForm2;

implementation

{$R *.dfm}

uses
  System.NetEncoding,
  System.Net.URLClient,
  REST.Utils,
  Winapi.ShellAPI,
  REST.Consts,
  REST.Types,
  System.DateUtils,
  IdAttachmentFile
  , DecryptEncrypt;

const
  SClientIDNeeded = 'An ClientID is needed before a token can be requested';
  SRefreshTokenNeeded = 'An Refresh Token is needed before an Access Token can be requested';




procedure TForm2.btnAuthenticateClick(Sender: TObject);
begin
  EmailOAuthDataModule.Authenticate;
  updateButtonsEnabled;
end;

procedure TForm2.btnSendMsgClick(Sender: TObject);
begin
  EmailOAuthDataModule.SendMessage(Memo1,AtachedPath.Text);
  updateButtonsEnabled;
end;

constructor TForm2.Create(AOwner: TComponent);
var
  ep:TEmailProvider;
begin
  inherited;
  case rgEmailProviders.ItemIndex of
  0: ep := epGmail;
  1: ep := epOutlook;
  end;
  EmailOAuthDataModule:=TEmailOAuthDataModule.create(self,ep,Memo1);
  updateButtonsEnabled;
end;

destructor TForm2.Destory(AOwner: TComponent);
begin
  FreeAndNil(EmailOAuthDataModule);
  inherited;
end;

procedure TForm2.updateButtonsEnabled;
begin
  btnAuthenticate.Enabled :=  not EmailOAuthDataModule.getisAuthenticate;
  btnClearAuthToken.Enabled :=  EmailOAuthDataModule.getisAuthenticate;
end;

procedure TForm2.btnCheckMsgClick(Sender: TObject);
begin
  EmailOAuthDataModule.CheckMessage(memo1);
  updateButtonsEnabled;
end;

procedure TForm2.btnClearAuthTokenClick(Sender: TObject);
begin
  EmailOAuthDataModule.ClearAuthToken;
  updateButtonsEnabled;
end;

end.
