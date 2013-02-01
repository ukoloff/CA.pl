#
# Update CRL(s) for user certificates
#

Lib('Detach');	# Go to background
Lib('AD');	# Any valid user accepted

# DoS check
exit	if $::CFG{db}{pub}->selectrow_arrayref("Select datetime('now', '-1 hour')<(Select Value From Ini Where Name='userCRL')")->[0];

$::CFG{db}{pub}->do("Insert Or Ignore Into Ini(Name, Notes) Values('userCRL', 'Last CRL update')");
$::CFG{db}{pub}->do("Update Ini Set Value=datetime() Where Name='userCRL'");

my $s=$::CFG{db}{pub}->prepare(<<SQL);
Select Distinct u
From User, Certs
Where User.id=Certs.id
And(Revoke is Null Or revokeReason='certificateHold')
SQL

$s->execute();
my @U;
while(my @r=$s->fetchrow_array)
{
 my $u=$r[0];
 my $dn=u2dn($u);
 $dn	or next;
 my $e=$::CFG{AD}{h}->search(base=>$dn, scope=>'base', filter=>'(!(UserAccountControl:1.2.840.113556.1.4.803:=2))', attrs=>['1.1'])->entry(0);
 $e	or next;
 push @U, $u;
}

$::CFG{db}{pub}->do(<<SQL);
Create Temp Table U1(
id	Integer Primary Key,
u	VarChar(255) Unique
)
SQL

$s=$::CFG{db}{pub}->prepare("Insert Into U1(u) Values(?)");
$s->execute($_)	foreach @U;

# Revoke
$::CFG{db}{pub}->do(<<SQL);
Update Certs
Set Revoke=datetime(), revokeReason='certificateHold'
Where Revoke is Null
And id In(Select id From User Where u Not In(Select u From U1))
SQL

# Un-Revoke
$::CFG{db}{pub}->do(<<SQL);
Update Certs
Set Revoke=Null, revokeReason=Null
Where Revoke is Not Null And revokeReason='certificateHold'
And id In(Select id From User Where u In(Select u From U1))
SQL

# Find user CA(s) to rebuild CRL
$s=$::CFG{db}{pub}->selectcol_arrayref(<<SQL);
Select Distinct CA.CN
From CA, Certs, User
Where Certs.id=User.id And Issuer=x509
SQL

foreach my $CA(@$s)
{eval{	# Generate CRL for CA
 my $t=tLoad('web/crl');
 $t->fromHash({paths=>{DIR=>$::CFG{tmp}}});
 tExpand($t);
 my $z=tLoad('web/0');
 tExpand($z);
 $t->prepend($z);
 $z=tLoad("ca/$CA");
 tExpand($z);
 $t->prepend($z);
 $z=tLoad("ca/0");
 tExpand($z);
 $t->prepend($z);
 $z=tLoad("0");
 tExpand($z);
 $t->prepend($z);
 $t->expand;
 $t->dropEmptyVars;

 $::CFG{Job}=$t;
 $::CFG{ca}=$CA;

 open $fh, '>', resolveFile($CA);
 $t->print($fh);
 close $fh;
 
 my $crtN=putCA();

 my $r=$::CFG{db}{pub}->selectrow_hashref(<<SQL, undef, $CA);
Select crlNo, Certs.id, Certs.Key, Certs.BLOB
From CA Left Join Certs On CA.crlSigner=Certs.id
Where CN=?
SQL

 if($r->{id} && $r->{Key})
 {
  writeFile('ca.crt', $r->{BLOB});
  writeFile('ca.key', $::CFG{db}{sec}->selectrow_arrayref("Select BLOB From Keys Where id=?", undef, $r->{Key})->[0]);
 }
 writeFile('crlnumber', $r->{crlNo});

 open $fh, '>', resolveFile('index');

 $s=$::CFG{db}{pub}->prepare(<<SQL);
Select Attrs.serial, subj, notBefore, Revoke, revokeReason
From Certs, Attrs, CA
Where CA.CN=?
And Certs.Issuer=CA.x509 And Certs.id=Attrs.id
And Revoke is not Null
And notAfter>substr(strftime('%Y%M%d%H%M%SZ'), 3)
SQL
 $s->execute($CA);
 while(my $r=$s->fetchrow_hashref)
 {
  my $R=$r->{Revoke};
  $R=~s/\D//g;
  substr($R, 0, 2, '');
  $R.='Z';
  $R.=",$r->{revokeReason}"	if $r->{revokeReason};
  print $fh "R\t$r->{notBefore}\t$R\t$r->{serial}\tunknown\t$r->{subj}\n";
 }
 close $fh;

 openSSL(qw(ca -gencrl), {config=>$CA, out=>"crl"});
 eval{ saveCRL(); };
}};

1;
