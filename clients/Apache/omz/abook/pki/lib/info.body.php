<Table Border CellSpacing='0' Width='100%'>
<?
$s=$CFG->db->prepare('Select u, byWho As Creator, Attrs.*, Revoke, revokeReason From Certs Left Join Attrs Using(id) Left Join User Using(id) Where Certs.id=:n');
$s->bindValue(':n', $CFG->params->n);
$r=$s->execute()->fetchArray(SQLITE3_ASSOC);
unset($r[id]);
if(!$r[Revoke]) unset($r[revokeReason]);
if(!inGroupX($CFG->db->querySingle("Select Value From Ini Where Name='groupC'")))unset($r[Creator]);
foreach($r as $k=>$v)
 echo "<TR><TH Align='Right'>$k</TH><TD>", htmlspecialchars($v), "<BR /></TD></TR>\n";
?>
</Table>
<H2>�������</H2>
<LI><A hRef="./?n=<?=$CFG->params->n?>">crt</A>, <A hRef="./?chain&n=<?=$CFG->params->n?>">+chain</A>
<LI><A hRef="./?as=p7b&n=<?=$CFG->params->n?>">pkcs7</A>, <A hRef="./?chain&as=p7b&n=<?=$CFG->params->n?>">+chain</A>
<? if($r[u]): ?>
<LI><A hRef="./?as=u27&n=<?=$CFG->params->n?>">*.pkcs7</A>, <A hRef="./?chain&as=u27&n=<?=$CFG->params->n?>">+chain</A>
<? endif; ?>
<LI><A hRef="./?as=der&n=<?=$CFG->params->n?>">der</A>
<? if(!$CFG->Super) return; ?>
<LI><A hRef="./?as=pem&n=<?=$CFG->params->n?>">pem</A>, <A hRef="./?chain&as=pem&n=<?=$CFG->params->n?>">+chain</A>
<LI><A hRef="./?as=pfx&n=<?=$CFG->params->n?>">pfx</A>,
<A hRef="./?chain&as=pfx&n=<?=$CFG->params->n?>">+chain</A><? if(!$r[u]) return; ?>,
<A hRef="./?as=pfx&old&n=<?=$CFG->params->n?>">old-style</A>
