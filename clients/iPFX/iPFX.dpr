Program iPFX;
Uses
  Windows,
  ComObj,
  SysUtils,
  proxyOff;

Const URL: String='https://ekb.ru/omz/me/pki/';

Var
  Ajax: Variant;
  LogKey: String;

Function getAjax: Variant;
Var
  Z: Variant;
Begin
  Z:=CreateOleObject('ScriptControl');
  Z.Language:='JScript';
  Z.AddCode('function X3(){'+
   'try{ return new ActiveXObject("Msxml2.XMLHTTP");}catch(e){};'+
   'try{ return new ActiveXObject("Microsoft.XMLHTTP");}catch(e){};}');
  getAjax:=Z.Eval('X3()');
End;

Procedure Post;
Begin
 Ajax.open('POST', URL, False);
 Ajax.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
End;

Procedure Error(S: String);
Begin
 Post();
 if Length(LogKey)>0 Then Ajax.setRequestHeader('X-Log-Key', LogKey);
 try Ajax.send('log='+S); except end;
 Halt(0);
End;

Function isWord(Const S: String): Boolean;
Var
  i: Integer;
Begin
 isWord:=False;
 if 0=Length(S) Then Exit;
 For i:=Length(S) DownTo 1 Do
  Case UpCase(S[i]) Of
   '0'..'9', 'A'..'Z':
  Else Exit;
  End{Case};
 isWord:=True;
End;

Function Base64Decode(Const S: String): String;
Var
  i: Integer;
  W, Buffer, Bits: Word;
Begin
  Result:='';
  Bits:=0; Buffer:=0; W:=0;
  For i:=1 To Length(S) Do
   Begin
    Case S[i] Of
     '+': W:=62;
     '/': W:=63;
     '=': Exit;
     '0'..'9': W:=Ord(S[i])+4;	//52-Ord('0')
     'A'..'Z': W:=Ord(S[i])-65;	//Ord('A');
     'a'..'z': W:=Ord(S[i])-71;	//Ord('a')-26
    Else
      Continue;
    End{Case S[i]};
    Inc(Bits, 6);
    Buffer:=Buffer Or(W SHL(16-Bits));
    If Bits<8 Then Continue;
    Result:=Result+Chr(Hi(Buffer));
    Buffer:=Buffer SHL 8;
    Dec(Bits, 8);
   End;
End;

Procedure protectCer;
Var
  Z: Variant;
  S: String;
Begin
 try
  Z:=CreateOleObject('WScript.Shell');
  S:=Z.RegRead('HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders\AppData');
  if 0=Length(S) Then Exit;
  Z.Run('attrib +R +S "'+S+'\Microsoft\SystemCertificates\My\Certificates\*"', 0, 0);
 except
 end;
End;

Function PFXIsPFXBlob(Var PFX): Bool; stdcall; External 'Crypt32.DLL';
Function PFXImportCertStore(Var PFX; Pass: LPCWSTR; Flags: LongInt): THandle;
         stdcall; External 'Crypt32.DLL';
Function CertOpenSystemStoreA(hprov: THandle; szSubsystemProtocol: LPCSTR): THandle;
         stdcall; External 'Crypt32.DLL';
Function CertEnumCertificatesInStore(hCertStore: THandle; pPrevCertContext: Pointer): Pointer;
         stdcall; External 'Crypt32.DLL';
Function CertAddCertificateContextToStore(hCertStore: THandle; pCertContext: Pointer;
           dwAddDisposition: LongInt; ppStoreContext: Pointer): BOOL;
         stdcall; External 'Crypt32.DLL';
Function CertCloseStore(hCertStore: THandle; dwFlags: LongInt): Bool;
         stdcall; External 'Crypt32.DLL';

Procedure installPFX(Const BLOB, Pass: String);
Var
 T: Record
  cbData: LongInt;
  pbData: Pointer;
 End;
 H, HS: THandle;
 Ctx: Pointer;
Begin
 If Length(BLOB)=0 Then Error('PFX/404');
 T.cbData:=Length(BLOB);
 T.pbData:=@BLOB[1];
 If Not PFXIsPFXBlob(T) Then Error('PFX/406');
 H:=PFXImportCertStore(T, PWideChar(WideString(Pass)), 0);
 If H=0 Then Error('PFX/'+IntToHex(GetLastError(), 0));
 HS:=CertOpenSystemStoreA(0, 'My');
 If HS=0 Then Error('MyStore/'+IntToHex(GetLastError(), 0));
 Ctx:=Nil;
 Repeat
  Ctx:=CertEnumCertificatesInStore(H, Ctx);
  If Ctx=Nil Then Break;
  CertAddCertificateContextToStore(HS, Ctx, 3{CERT_STORE_ADD_REPLACE_EXISTING}, Nil);
 Until False;
 CertCloseStore(H, 0);
 CertCloseStore(HS, 0);
End;

Procedure Main;
Var
  Cookie, Ticket, Location: String;
  ForceRO: Boolean;
Begin
 LogKey:='';
 Ajax:=getAjax();
 if VarIsEmpty(Ajax) Then Halt(1);
 Post();
 try Ajax.send('url='); except Error('POST/1'); end;
 Cookie:=Ajax.getResponseHeader('X-Cookie');
 Location:=Ajax.getResponseHeader('X-Location');
 if Not isWord(Cookie) Then Error('Cookie/403');
 if 0=Length(Location) Then Error('URL/404');
 try Ajax.open('GET', Location, False); except Error('URL/406'); end;
 Location:='';
 try Ajax.send(); except Error('GET'); end;
 Ticket:=Ajax.getResponseHeader('X-Ticket');
 if Not isWord(Ticket) Then Error('Ticket/403');
 Post();
 Ajax.setRequestHeader('X-Cookie', Cookie);
 Ajax.setRequestHeader('X-Ticket', Ticket);
 Cookie:=Copy(Cookie, 3, 5);
 Ticket:='';
 try Ajax.send('blob=?'); except Error('POST/2'); end;
 LogKey:=Ajax.getResponseHeader('X-Log-Key');
 if '-'=LogKey Then Halt(0);
 ForceRO:=Length(Ajax.getResponseHeader('X-ForceRO'))>0;
 installPFX(Base64Decode(Ajax.responseText), Cookie);
 if ForceRO Then protectCer;
 Error('-');
End;

Begin
 Main;
End.

