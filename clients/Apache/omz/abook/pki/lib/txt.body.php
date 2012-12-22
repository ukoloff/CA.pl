<TextArea Rows='21' ReadOnly AutoFocus Style='width: 100%;'>
<?
$x=proc_open("{$CFG->OpenSSL} x509 -noout -text", Array(Array('pipe', 'r'), Array('pipe', 'w')),  $pipes);

$s=$CFG->db->prepare('Select BLOB From Certs Where id=:n');
$s->bindValue(':n', $CFG->params->n);
$r=$s->execute()->fetchArray(SQLITE3_NUM);

fwrite($pipes[0], $r[0]);
echo htmlspecialchars(stream_get_contents($pipes[1]));
fclose($pipes[1]);
proc_close($x);
?>
</TextArea>
