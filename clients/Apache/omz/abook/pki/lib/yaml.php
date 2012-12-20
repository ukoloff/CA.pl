<?
LoadLib('/yaml');

Header('Content-Type: text/yaml');
Header('Content-Disposition: attachment; filename="pki.yaml"');

echo "# Select *", strtr($CFG->SQL, Array("\n"=>"\n#\t")), "\n";

echo Spyc::YAMLDump(null);

$s=$CFG->db->prepare("Select u, CA.id As CAN, CN,Certs.ctime, Revoke, revokeReason, Attrs.*".$CFG->SQL);
$x=$s->execute();
while($r=$x->fetchArray(SQLITE3_ASSOC)):
 echo preg_replace('/^.*?(\r\n?|\n)/', '', Spyc::YAMLDump(Array($r)));
endwhile;

?>
