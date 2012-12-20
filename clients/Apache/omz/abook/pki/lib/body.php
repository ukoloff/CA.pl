<?
if($CFG->tabs) return;

LoadLib('filter.body');

LoadLib('/pages');
$CFG->defaults->pagesize=25;
$p=PageStart($CFG->db->querySingle("Select Count(*)".$CFG->SQL));

$CFG->params->ca=$CFG->entry->ca;
pageNavigator();
$p0=$CFG->params->p;
unset($CFG->params->p);
sortedHeader('gsudr');
$s=$CFG->db->prepare("Select Certs.*, Attrs.*, u, CA.id As caId, CA.CN".$CFG->SQL." Limit ".$CFG->params->pagesize." Offset ".$p);
$x=$s->execute();
while($r=$x->fetchArray(SQLITE3_ASSOC)):
//print_r($r);
 $A='';
 if($CFG->Auth) $A= inGroupX('#browseDIT')? 'dc/user' : 'abook';
 if($A) $A="<span onMouseMove=\"userThumb(this, ".jsEscape($r[u]).")\"><A hRef='/omz/$A/.?u=".urlencode($r[u])."' Target='user'>";
 if($R=$r[Revoke])$R.="\n".$r[revokeReason];
 if($R=trim($R))$R=' Title="'.htmlspecialchars($R).'"';

 echo "<TR>",
    '<TD><A hRef="./', htmlspecialchars(hRef('ca', $r[caId])), '">', $r[CN], "</A><BR /></TD>",
    '<TD><A hRef="./?x&n=', $r[id], '" Target="crt">', substr($r[serial], 0, 8), strlen($r[serial])>8?'...':'', "</A><BR /></TD>",
    '<TD>', $A, $r[u], $A?'</A>':'', "<BR /></TD>",
    '<TD><Small>', strtr(htmlspecialchars($r[subj]), Array('/'=>'<wbr>/')), "</Small><BR /></TD>",
    "<TD$R>", htmlspecialchars(preg_replace('/\s.*/', '', $r[Revoke])), '<BR /></TD>',
    "</TR>\n";
endwhile;

?>
</Table>
<?
$CFG->params->p=$p0;
pageNavigator();

crlUpdate();
?>
