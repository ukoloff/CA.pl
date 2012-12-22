#
# Generate user ceritificate
#

Lib('AD');
Lib('Translit');

my $dn=$::CFG{AD}{udn};
if(length($::CFG{web}{u}))
{
 A2($::CFG{Job}->valueOf('AD', 'groupC'))	or die "Access denied!\n";
 $dn=u2dn($::CFG{web}{u})	or die "User not found!\n";
}

# Check for duplicates
$::CFG{db}{pub}->selectrow_arrayref(<<SQL, undef, dn2u($dn)->[0])->[0]	and die "Duplicate certificate!\n";
Select Count(*)
From Certs, User
Where u=? And User.id=Certs.id
And (Revoke is Null Or revokeReason='certificateHold')
And Issuer=(Select x509 From CA, Ini Where Name='userCA' And Value=CA.id)
SQL

my $e=$::CFG{AD}{h}->search(base=>$dn, scope=>'base',
 filter=>'(&(mail=*)(userPrincipalName=*)(!(UserAccountControl:1.2.840.113556.1.4.803:=2)))',
 attrs=>['cn', 'mail', 'userPrincipalName'])->entry(0);
$e	or die "Certificate generation not allowed!\n";
my $cn=utfTranslit($e->get_value('cn'));
my $mail=$e->get_value('mail');
my $upn=$e->get_value('userPrincipalName');

my $t=tLoad('web/new');
$t->fromHash({CN=>$cn, Mail=>$mail, UPN=>$upn, paths=>{DIR=>$::CFG{tmp}}});

tExpand($t);

my $z=tLoad('web/0');
tExpand($z);
$t->prepend($z);

$z=$t->copy;
$z->expand;
$z->dropEmptyVars;
$z=$z->valueOf('CA');
$z	or die "'CA=' not found in template!\n";
$z=tLoad("ca/$z");
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
$::{CFG}{ca}=$t->valueOf('ca');

open $fh, '>', resolveFile('conf');
$t->print($fh);
close $fh;

my $idCA=$::CFG{db}{pub}->selectrow_arrayref("Select id From CA Where CN=?", undef, $::CFG{ca})->[0];
$idCA	or	die "CA '$::CFG{ca}' not found!\n";
$::CFG{db}{pub}->do("Insert Or Ignore Into Ini(Name, Notes) Values('userCA', 'Checked by Web-server')");
$::CFG{db}{pub}->do("Update Ini Set Value=? Where Name='userCA'", undef, $idCA);

my $crtN=putCA();

#print "Generating key...\n";
newKey();

#print "Generating request...\n";
openSSL(qw(req -new), {config=>'conf', key=>'key', out=>'req'});

#print "Signing...\n";
openSSL(qw(ca -batch), {config=>'conf', in=>'req', out=>'crt'});
openSSL(qw(x509), {in=>'crt', out=>'crt0'});

#print "Saving...\n";
my $keyN=storeKey();
$::CFG{db}{pub}->do("Insert Into Certs(Key, Issuer, BLOB) Values(?, ?, ?)", undef, $keyN, $crtN, readFile('crt0'));
my $N=$::CFG{db}{pub}->sqlite_last_insert_rowid;
$::CFG{db}{pub}->do("Insert Into User(id, u, byWho) Values(?, ?, ?)", undef, $N, dn2u($dn), $::CFG{AD}{u});
updateSerial();
storeAttrs($N);

1;
