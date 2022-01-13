program GMailAuthDemo;

uses
  Vcl.Forms,
  Unit2 in 'Unit2.pas' {Form2},
  Globals in 'Globals.Sample.pas',
  IdSASLXOAUTH in 'IdSASLXOAUTH.pas',
  IdOAuth2Bearer in 'IdOAuth2Bearer.pas',
  EmailOAuthDm in 'EmailOAuthDm.pas' {EmailOAuthDataModule: TDataModule},
  DecryptEncrypt in 'DecryptEncrypt.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
