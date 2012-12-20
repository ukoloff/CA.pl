<?
LoadLib('/uxmCA');

$H=getallheaders();
if(!isWord($Cookie=$H['x-cookie'])) Err('Cookie/403');
if(!isWord($Ticket=$H['x-ticket'])) Err('Ticket/403');

$R=caExec(Array(command=>'iPFX', step=>'BLOB', Cookie=>$Cookie, Ticket=>$Ticket));
$R=explode("\n", $R);

Header('X-u: '.$R[0]);
//Header('X-ForceRO: 1');	// To make Certfile ReadOnly

echo $R[1], "\n";

function isWord($S)
{
 return preg_match('/^\w+$/', $S);
}

function Err($S)
{
 exit;
}

?>
