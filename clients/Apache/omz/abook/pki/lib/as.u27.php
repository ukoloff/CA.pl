<? // Export all user certificates in pkcs7
$CFG->db->exec(<<<SQL
Create Temp Table X(
 idx	Integer Primary Key,
 n	Integer Not Null Unique
);

Insert Into X(n)
Select Certs.id
From User A, User U, Certs
Where A.id={$CFG->params->n}
 And U.u=A.u
 And Certs.id=U.id
 And Revoke is Null
Order By ctime Desc;
SQL
);

if(isset($_GET[chain])):
 do
  $CFG->db->exec(<<<SQL
Insert Into X(n)
Select Distinct Issuer
From X, Certs
Where n=id And Issuer Not In(Select n From X)
SQL
);
 while($CFG->db->changes());
endif;

if(!$CFG->db->querySingle("Select Count(*) From X")):
 Header('HTTP/1.0 404');
 exit;
endif;

$t=tempnam('/var/tmp', 'p7b');
$f=fopen($t, 'w');

$s=$CFG->db->prepare(<<<SQL
Select BLOB
From X, Certs
Where n=id
Order By idx
SQL
);
$s=$s->execute();
while($r=$s->fetchArray(SQLITE3_NUM))
  fwrite($f, $r[0]);
fclose($f);

Header('Content-Type: application/octet-stream');
Header('Content-Disposition: attachment; filename="'.$CFG->fileName.'.p7b"');

passthru("{$CFG->OpenSSL} crl2pkcs7 -nocrl -certfile $t");
unlink($t);

?>
