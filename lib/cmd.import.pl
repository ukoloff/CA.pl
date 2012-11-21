# Import PEM into DB

my $pem=$::{CFG}{Job}->valueOf('pem');
-f $pem	or die "Cannot find '$pem'!\n";

openSSL(qw(x509 -in), $pem, {out=>'crt'});
openSSL(qw(rsa -in), $pem, {out=>'key'});

my $issuer;
my $f=readSSL(qw(x509 -noout -issuer), {in=>'crt'});
while(<$f>)
{
 s/\s*$//;
 /=\s*/	or next;
 $issuer=$';
 last;
}
#print "Issuer='$issuer'\n";

$::{CFG}{db}{sec}->do("Insert Into Keys(BLOB) Values(?)", undef, readFile('key'));
my $keyN=$::CFG{db}{sec}->sqlite_last_insert_rowid;
$::{CFG}{db}{pub}->do("Insert Into Certs(Key, Issuer, BLOB) Values(?, (Select id From Attrs Where subj=?), ?)", undef, $keyN, $issuer, readFile('crt'));
my $crtN=$::CFG{db}{pub}->sqlite_last_insert_rowid;
storeAttrs($crtN);

my @Sep=qw(20 - - T : :);
my $ctime=$::CFG{db}{pub}->selectrow_arrayref("Select notBefore From Attrs Where id=?", undef, $crtN)->[0];
$ctime=join('', map {shift(@Sep), $_} unpack('(A2)6', $ctime));
$ctime=$::CFG{db}{pub}->selectrow_arrayref("Select datetime(?)", undef, $ctime)->[0];

$ctime
    and $::CFG{db}{pub}->do("Update Certs Set ctime=? Where id=?", undef, $ctime, $crtN)
    and $::CFG{db}{sec}->do("Update Keys Set ctime=? Where id=?", undef, $ctime, $keyN);

1;
