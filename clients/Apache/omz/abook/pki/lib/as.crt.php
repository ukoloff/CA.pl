<?
Header('Content-Type: application/x-x509-ca-cert');
Header('Content-Disposition: attachment; filename="'.$CFG->fileName.'.crt"');

$s=$CFG->db->prepare('Select BLOB From Certs Where id=:n');
$s->bindValue(':n', $CFG->params->n);
$r=$s->execute()->fetchArray(SQLITE3_NUM);
echo $r[0];

if(!isset($_GET[chain])) return;
unset($Z);
$n=$CFG->params->n;
$Z[$n]=1;
$s=$CFG->db->prepare("Select id, BLOB From Certs Where id=(Select Issuer From Certs Where id=:n)");
while(1):
 $s->bindValue(':n', $n);
 $r=$s->execute()->fetchArray(SQLITE3_NUM);
 $n=$r[0];
 if(!$n) return;
 if($Z[$n]) return;
 $Z[$n]=1;
 echo $r[1];
endwhile;

?>
