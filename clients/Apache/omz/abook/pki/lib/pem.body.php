<TextArea Rows='21' ReadOnly AutoFocus Style='width: 100%;'>
<?
echo htmlspecialchars(caExec(Array(command=>'key', auth=>1, n=>$CFG->params->n)));

$s=$CFG->db->prepare('Select BLOB From Certs Where id=:n');
$s->bindValue(':n', $CFG->params->n);
$r=$s->execute()->fetchArray(SQLITE3_NUM);
echo htmlspecialchars($r[0]);

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
  echo $r[1];
 endwhile;
endif;
?>
</TextArea>
<?if(!isset($_GET[chain])):?>
&raquo;
<A hRef="./<?=htmlspecialchars(hRef('chain', ' '))?>">+chain</A>
<?endif;?>
