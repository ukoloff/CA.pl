<?
LoadLib('/uxmCA');
LoadLib('db');

$H=getallheaders();
if(!isWord($Cookie=$H['x-cookie'])) Err('Cookie/403');
if(!isWord($Ticket=$H['x-ticket'])) Err('Ticket/403');

$R=caExec(Array(command=>'iPFX', step=>'BLOB', Cookie=>$Cookie, Ticket=>$Ticket));
$R=explode("\n", $R);

$u=AddSlashes($R[0]);
mysql_query("Insert Into uxmJournal.pfx(Op, IP, u) Values('g', {$CFG->IP}, '$u')");

$s=$CFG->h->prepare('Select id From H Where hash=?');
do $s->bindValue(1, $rr=rnd()); while(@$s->execute()->fetchArray());

$s=$CFG->h->prepare('Insert Into H(idMy, hash) Values(:id, :hash)');
$s->bindValue(':id', mysql_insert_id());
$s->bindValue(':hash', $rr);
$s->execute();

Header('X-Log-Key: '.$rr);

Header('X-u: '.$R[0]);
//Header('X-ForceRO: 1');	// To make Certfile ReadOnly

echo $R[1], "\n";

function isWord($S)
{
 return preg_match('/^\w+$/', $S);
}

function rnd()
{
 $f=fopen('/dev/urandom', 'r');
 return preg_replace('/\W/', '', base64_encode(sha1(fread($f, 4).microtime(), true)));
}

function Err($S)
{
 global $CFG;
 $S=AddSlashes($S);
 mysql_query("Insert Into uxmJournal.pfx(Op, IP, Error) Values('g', {$CFG->IP}, '$S')");
 Header('X-Log-Key: -');
 exit;
}

?>
