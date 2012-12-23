Unit proxyOff;

Interface

Implementation uses
  Registry;

Const
  pName='ProxyEnable';

Var
 R: TRegistry;
 Proxy: Integer;

Initialization
 R:=TRegistry.Create;
 R.OpenKey('Software\Microsoft\Windows\CurrentVersion\Internet Settings', False);
 Proxy:=R.ReadInteger(pName);
 R.WriteInteger(pName, 0);
 R.WriteInteger('CertificateRevocation', 0);
Finalization
 R.WriteInteger(pName, Proxy);
End.
