<?
Header('Content-Type: application/octet-stream');
Header('Content-Disposition: attachment; filename="'.$CFG->fileName.'.cer"');

$x=proc_open("/usr/bin/openssl x509 -outform der", Array(Array('pipe', 'r'), Array('pipe', 'w')),  $pipes);

$s=$CFG->db->prepare('Select BLOB From Certs Where id=:n');
$s->bindValue(':n', $CFG->params->n);
$r=$s->execute()->fetchArray(SQLITE3_NUM);

fwrite($pipes[0], $r[0]);
echo stream_get_contents($pipes[1]);
fclose($pipes[1]);
proc_close($x);

?>
