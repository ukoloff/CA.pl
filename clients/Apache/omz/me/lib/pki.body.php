<Table Border CellSpacing='0' Width='100%'>
<TR Class='tHeader'>
<TH>№</TH>
<TH>Имя</TH>
<TH>Отозван</TH>
</TR>
<?
#$CFG->pki->db->busyTimeout(300);
if($CFG->Auth)
 pkiTable();
else
 LoadLib('auth');
?>
</Table>

<?
if(!$CFG->pki->Found) LoadLib('pki.form', 1);

if(!$CFG->params->u) LoadLib('pki.test', 1);

function pkiTable()
{
 global $CFG;
 $CFG->pki->Found=0;
 $s=$CFG->pki->db->prepare(<<<SQL
Select Attrs.*, DateTime(Revoke, 'localtime') As Rvk, revokeReason as rR,
 Issuer=(Select x509 From CA, Ini Where Name='userCA' And Value=CA.id) As ActiveCA,
 Revoke is Null Or revokeReason='certificateHold' as Active
From Certs, Attrs, User
Where Certs.id=Attrs.id And Certs.id=User.id And u=:u
Order By ctime
SQL
 );
// if(!$s) return Locked();
 $s->bindValue(':u', $CFG->pki->u);
 $r=$s->execute();
 while($z=$r->fetchArray(SQLITE3_ASSOC)):
  if($z[Active] and $z[ActiveCA]) $CFG->pki->Found++;
  if($R=$z[Rvk])$R.="\n".$z[rR];
  if($R=trim($R))$R=' Title="'.htmlspecialchars($R).'"';

  echo '<TR><TD><A hRef="/omz/abook/pki/?n=', $z[id], '">',  htmlspecialchars($z[serial]), '</A>', ($z[Active]&&$z[ActiveCA]?'&oplus;':''),
    "<BR /></TD><TD><small>", str_replace('=', '=<WBR>', str_replace('/', '<WBR>/', htmlspecialchars($z[subj]))),
    "<BR /></small></TD><TD$R>", htmlspecialchars(preg_replace('/\s.*/', '', $z[Rvk])),
    "<BR /></TD></TR>\n";
 endwhile;
}

?>
