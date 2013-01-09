<?
LoadLib('db');

$i=getLogId();
$Err=$_POST['log'];
$Err='-'==$Err?'NULL':"'".AddSlashes($Err)."'";
mysql_query("Insert Into uxmJournal.pfx(Op, Parent, IP, Error) Values('i', $i, $CFG->IP, $Err)");

function getLogId()
{
 global $CFG;
 $H=getallheaders();
 $s=$CFG->h->prepare("Select idMy From H Where hash=?");
 $s->bindValue(1, $H['x-log-key']);
 $s=$s->execute()->fetchArray();
 return (int)$s[0];
}

?>
