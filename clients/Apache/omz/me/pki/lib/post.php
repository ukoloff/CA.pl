<?
foreach(explode(' ', 'url blob')as $x) if(isset($_POST[$x])) { LoadLib($x); exit; }
exit;
?>
