<?
Header('Content-Type: application/octet-stream');
Header('Content-Disposition: attachment; filename="'.$CFG->fileName.'.p7b"');

echo caExec(Array(command=>'pkcs7', n=>$CFG->params->n, chain=>isset($_GET[chain])));
?>
