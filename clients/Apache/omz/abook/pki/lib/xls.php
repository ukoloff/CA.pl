<?
Header('Content-Type: application/vnd.ms-excel');
Header('Content-Disposition: attachment; filename="users.xls"');
?>
<Table Border><!--
Select *<?=$CFG->SQL?>
-->
<?
$s=$CFG->db->prepare("Select u, CA.id As CAN, CN,Certs.ctime, Revoke, revokeReason, Attrs.*".$CFG->SQL);
$x=$s->execute();
$N=0;
while($r=$x->fetchArray(SQLITE3_ASSOC)):
 if(!$N++):
  echo '<TR>';
  foreach($r as $k=>$v) echo '<TH>', htmlspecialchars($k), '</TH>';
  echo "</TR>\n";
 endif;
 echo '<TR>';
 foreach($r as $k=>$v) echo '<TD>', htmlspecialchars($v), "</TD>";
 echo "</TR>\n";
endwhile;

?>
</Table>
