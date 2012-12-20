<?
foreach(explode(' ', 'url blob log')as $x) if(isset($_POST[$x])) { LoadLib($x); exit; }
exit;
?>
