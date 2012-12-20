<%@Language='JScript'%>
<%
var ks=[];
for(var E=new Enumerator(Application.Contents); !E.atEnd(); E.moveNext())
{
 var k=E.item();
 if(/^@!\w+$/.test(k))
  if(Application(k)<(new Date()).getTime())
	ks.push(k);
}

for(var i in ks)
{
 var k=ks[i];
 Application.Contents.Remove(k);
 Application.Contents.Remove(k.replace(/^@!/, '@'));
}
%>