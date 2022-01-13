unit DecryptEncrypt;
//roll your own Encryption module here.
interface

  function DecryptStr(const CypheredText: String): String;
  function EncryptStr(const PlainText: String): String;

implementation


function EncryptStr(const PlainText: String): String;
begin
  Result := PlainText;
end;

function DecryptStr(const CypheredText: String): String;
begin
  Result := CypheredText;
end;



end.
