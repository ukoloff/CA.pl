//
// Update Certificates
//

var URL='https://ekb.ru/omz/abook/pki/';
var Server='Directum';
//var DB='Sandbox';
var DB='Directum';

WScript.Echo('Getting CSV...');

var Ajax=new ActiveXObject("Msxml2.XMLHTTP");
Ajax.open('GET', URL+'?q=r@;u!@&sort=C&as=csv', false);
Ajax.send();
var Q=namedCSV(parseCSV(Ajax.responseText));

WScript.Echo('Connecting to MS SQL...');

var SQL=goSQL();

WScript.Echo('Поиск неустановленных сертификатов...');

var Dir, sys;

for(var i in Q)
{
 var X=Q[i];
 if(X.Revoke || !X.u) continue;

 SQL.user(0)=X.u;
 var Rs=SQL.user.Execute();
 if(Rs.EOF) continue;

 var U={};
 U.cn=X.subj.replace(/.*\/CN=/i, '').replace(/\/.*/, '');
 for(var E=new Enumerator(Rs.Fields); !E.atEnd(); E.moveNext())
   U[E.item().name]=E.item().value;

 SQL.crt(0)=U.Analit;
 SQL.crt(1)=U.SHA1=X.SHA1.replace(/\W/g, '');
 if(SQL.crt.Execute()(0).value>0) continue;

 WScript.Echo(X.u+'\t'+U.UserKod+'\t'+U.cn+'\t'+U.UserName+'\t//'+U.Analit);

 if(!Dir)Dir=goDirectum();
 if(!sys) sys=getSys();

 WScript.Echo('Загрузка сертификата...');

 Ajax.open('GET', URL+'?n='+X.id, false);
 Ajax.send();
 var N1=sys.tmp();
 var FC=sys.fso.CreateTextFile(N1, true);
 FC.Write(Ajax.responseText);
 FC.Close();
 var N2=sys.tmp();
 sys.sh.Run('"C:/Program Files/OpenSSL/openssl.exe" x509 -in "'+
    N1+'" -outform der -out "'+N2+'"', 0, true);
 sys.fso.DeleteFile(N1);

 WScript.Echo('Установка сертификата...');

 try{
  SQL.reset(0)=U.Analit;
  SQL.reset.Execute();

  var POL=Dir.ReferencesFactory.ПОЛ.GetObjectByCode(U.Kod);
  var CER=POL.DetailDataSet(2);

// Работает в Directum 4.6.1; В Directum 4.7 юзать Dir.ScriptFactory
  var Events = CER.Events;
  Events.AddCheckPoint();
  Events.Events(9/*dseBeforeInsert*/).Enabled = false;
  CER.Append();
  Events.ReleaseCheckPoint();

  CER.ISBStartObjectName='{B1B27433-D685-47F8-8500-CF9525407145}';
  CER.СтрокаТ2=U.cn;
  CER.СодержаниеТ2=U.SHA1;
  CER.Requisites('ТекстТ2').LoadFromFile(N2);
  CER.ISBCertificateInfo=U.UserName;
  CER.ISBCertificateType='ЭЦП и шифрование';
  CER.ISBDefaultCert='Да';
  CER.СостояниеТ2='Действующая';
  POL.Save();

 }catch(e){
 WScript.Echo('Error: '+e.message);
 }

 sys.fso.DeleteFile(N2);
}

WScript.Echo("That's all folks!");

// Functions...

function parseCSV(S)
{
 var L='', F=[], All=[], q=0, eol=0;
 while(S.length)
 {
  (q? /""?|$/ : /;|"|\r\n?|\n|$/).test(S);
  L+=RegExp.leftContext;
  S=RegExp.rightContext;
  if(q)
   switch(RegExp.lastMatch)
   {
    case '"': q=0; continue; 
    case '""': L+='"'; continue;
    case '': eol=1;
   }
  else
  {
   if('"'==RegExp.lastMatch) { q=1; continue; }
   eol=';'!=RegExp.lastMatch;
  }
  F.push(L); L='';
  if(!eol) continue;
  All.push(F); F=[];
 }
 return All;
}

function namedCSV(CSV)
{
 for(var i=CSV.length-1; i>=0; i--)
   if((CSV[i].length>1)||(CSV[i][0].length>0)) break;
 CSV.length=i+1;
 if(!i) return CSV;
 var F=CSV.shift(), R=[];
 while(D=CSV.shift())
 {
  var R2={};
  for(var i in F) R2[F[i]]=D[i];
  R.push(R2);
 }
 return R;
}

function goSQL()
{
 var Z=new ActiveXObject("ADODB.Connection");
 Z.Provider='SQLOLEDB';
 Z.Open("Integrated Security=SSPI;Data Source="+Server);
 Z.DefaultDatabase=DB;

 var X={h: Z};
 X.Cmd=function(name, SQL)
 {
  var Cmd=new ActiveXObject("ADODB.Command");
  Cmd.ActiveConnection=this.h;
  Cmd.CommandText=SQL;
  this[name]=Cmd;
 }

 readSQL(X);
 return X;
}

function readSQL(SQL)
{
 var f=WScript.CreateObject("Scripting.FileSystemObject").
    OpenTextFile(WScript.ScriptFullName, 1);	//ForReading
 var name='', Txt='';
 while(!f.AtEndOfStream)
 {
  var s=f.ReadLine();
  if(!name)
  {
   if(s.match(/^\s*\/\*[-\s]*\[(\w+)\.sql\][-\s]+$/i)) name=RegExp.$1;
   continue;
  }
  if(!s.match(/^[-\s]+\*\/\s*$/))
  {
   Txt+=s+'\n';
   continue;
  }
  SQL.Cmd(name, Txt);
  name=Txt='';
 }
 f.Close();
}

function goDirectum()
{
 var lp=new ActiveXObject("SBLogon.LoginPoint");
 var D=lp.GetApplication("ServerName="+Server+";DBName="+DB+";IsOSAuth=1");
 return D;
}

function rnd(N)
{
 for(var S=''; S.length<(N||12); )
 {
  var n=Math.floor(62*Math.random());
  S+=String.fromCharCode('Aa0'.charCodeAt(n/26)+n%26);
 }
 return S;
}

function getSys()
{
 var R={};
 R.fso=new ActiveXObject("Scripting.FileSystemObject");
 R.sh=new ActiveXObject("WScript.Shell")
 R.tmpPath=R.sh.ExpandEnvironmentStrings('%TEMP%/');
 R.tmp=function()
 {
  do var n=this.tmpPath+rnd(); while(this.fso.FileExists(n));
  return n;
 }
 return R;
}

// SQL

/*--[user.sql]--------------------------------------------------------
Select
 UserLogin, UserKod, UserName, P.Analit, P.Kod
From
 mbUser U, mbAnalit P, mbVidAn V
Where
 U.NeedEncode='W' And U.UserKod=P.Dop And
 P.Vid=V.Vid And V.Kod='ПОЛ'
 And U.UserLogin=?
---------------------------------------------------------------------*/

/*--[crt.sql]--------------------------------------------------------
Select Count(*)
From MBAnValR2
Where
 Analit=?
 And SoderT2=?
---------------------------------------------------------------------*/

/*--[reset.sql]--------------------------------------------------------
Update MBAnValR2
  Set DefaultCert='Н', CertificateType='Э'
Where
 Analit=?
---------------------------------------------------------------------*/

//-[EOF]---------------------------------------------------------------
