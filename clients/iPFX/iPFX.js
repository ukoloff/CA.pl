//
// Model of iPFX
//

var URL='https://ekb.ru/omz/me/pki/';

var Ajax=X3();

Ajax.open('POST', URL, false);
Ajax.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
Ajax.send('url=?');

var Loc=Ajax.getResponseHeader('X-Location');
var Cookie=Ajax.getResponseHeader('X-Cookie');
WScript.Echo('1)', Loc, Cookie);
//WScript.Echo(Ajax.responseText); WScript.Quit();

Ajax.open('GET', Loc, false);

Ajax.send();
var Ticket=Ajax.getResponseHeader('X-Ticket');
WScript.Echo('2) krbTicket='+Ticket);

//WScript.Echo(Ajax.responseText); WScript.Quit();

Ajax.open('POST', URL, false);
Ajax.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
Ajax.setRequestHeader('X-Cookie', Cookie);
Ajax.setRequestHeader('X-Ticket', Ticket);
Ajax.send('blob=?'); 
WScript.Echo('3) PFX='+(''+Ajax.responseText).length);
WScript.Echo('3) ForceRO='+!!Ajax.getResponseHeader('X-ForceRO'));
WScript.Echo('3) u='+Ajax.getResponseHeader('X-U'));

function X3(){
 try{ return new ActiveXObject("Msxml2.XMLHTTP");}catch(e){};
 try{ return new ActiveXObject("Microsoft.XMLHTTP");}catch(e){};
 WScript.Echo('AJAX not supported!');
 WScript.Quit();
}
