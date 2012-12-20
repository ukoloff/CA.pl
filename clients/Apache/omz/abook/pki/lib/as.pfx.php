<?
$pass=trim($_GET[pass]);
Header('Content-Type: application/octet-stream');
Header('Content-Disposition: attachment; filename="'.$CFG->fileName.(strlen($pass)?'.pfx':'').'"');

echo base64_decode(caExec(Array(command=>'pfx', auth=>1, n=>$CFG->params->n, chain=>isset($_GET[chain]), pass=>$pass)));
?>
