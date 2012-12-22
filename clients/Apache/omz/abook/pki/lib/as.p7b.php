<?
Header('Content-Type: application/octet-stream');
Header('Content-Disposition: attachment; filename="'.$CFG->fileName.'.p7b"');

$t=tempnam('/var/tmp', 'p7b');
$f=fopen($t, 'w');

$s=$CFG->db->prepare('Select BLOB From Certs Where id=:n');
$s->bindValue(':n', $CFG->params->n);
$r=$s->execute()->fetchArray(SQLITE3_NUM);
fwrite($f, $r[0]);

if(isset($_GET[chain])):
 unset($Z);
 $n=$CFG->params->n;
 $Z[$n]=1;
 $s=$CFG->db->prepare("Select id, BLOB From Certs Where id=(Select Issuer From Certs Where id=:n)");
 while(1):
  $s->bindValue(':n', $n);
  $r=$s->execute()->fetchArray(SQLITE3_NUM);
  $n=$r[0];
  if(!$n) break;
  if($Z[$n]) break;
  $Z[$n]=1;
  fwrite($f, $r[1]);
 endwhile;
endif;
fclose($f);

passthru("{$CFG->OpenSSL} crl2pkcs7 -nocrl -certfile $t");
unlink($t);
?>
