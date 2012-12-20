<?
Header('Content-Type: text/csv');
Header('Content-Disposition: attachment; filename="pki.csv"');

$s=$CFG->db->prepare("Select u, CA.id As CAN, CN,Certs.ctime, Revoke, revokeReason, Attrs.*".$CFG->SQL);
$x=$s->execute();
$N=0;
while($r=$x->fetchArray(SQLITE3_ASSOC)):
 if(!$N++):
  foreach($r as $k=>$v) echo csvEsc($k), ";";
  echo "\n";
 endif;
 foreach($r as $k=>$v) echo csvEsc($v), ";";
 echo "\n";
endwhile;

function csvEsc($S)
{
 return preg_match('/["\r\n;]/', $S)? '"'.strtr($S, Array('"'=>'""')).'"' : $S;
}
?>
