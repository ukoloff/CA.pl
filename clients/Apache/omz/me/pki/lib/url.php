<?
LoadLib('/uxmCA');
$R=caExec(Array(command=>'iPFX', step=>'pre'));
$R=explode("\n", $R);
Header('X-Cookie: '.$R[0]);
Header('X-Location: '.$R[1]);
exit;
?>
