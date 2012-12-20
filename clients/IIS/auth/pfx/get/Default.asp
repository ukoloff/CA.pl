<%@Language='JScript'%>
<%
Server.Execute('expire.asp');

(function()
{//Check AUTH_USER
 var k=Request('Ticket');
 if(!/^\w+$/.test(k)) return;
 var u=Application('@'+k);
 if(!u) return;
// Application.Contents.Remove('@'+k);
// Application.Contents.Remove('@!'+k);
 Response.AddHeader('X-DU', u);
// if('WU\\root'==u) { Response.AddHeader('X-U', 'Nobody'); return; }
 u=u.split('\\');
 if(u.length!=2) return;
 if(Server.CreateObject('ADSystemInfo').DomainShortName.toLowerCase()!=u[0].toLowerCase()) return;
 Response.AddHeader('X-U', u[1]);
})();

%>