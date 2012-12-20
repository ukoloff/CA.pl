<%@Language='JScript'%>
<%
//Application.Contents.RemoveAll();
Server.Execute('get/expire.asp');

var k, nonce=''+Request('nonce');
do k=rnd(); while(Application('@'+nonce+k));

Application('@'+nonce+k)=''+Request.ServerVariables('AUTH_USER');
Application('@!'+nonce+k)=(new Date()).getTime()+7000;

Response.AddHeader('X-Ticket', k);

function rnd(N)
{
 for(var S=''; S.length<(N||12); )
 {
  var n=Math.floor(62*Math.random());
  S+=String.fromCharCode('Aa0'.charCodeAt(n/26)+n%26);
 }
 return S;
}

%>