# Import PEM into DB

my $pem=$::{CFG}{Job}->valueOf('pem');
-f $pem	or die "Cannot find '$pem'!\n";

print "Reading certificate...\n";
openSSL(qw(x509 -in), $pem, {out=>'crt'});
print "Reading private key...\n";
openSSL(qw(rsa -in), $pem, {out=>'key'});

my %A;
my @vars=qw(serial issuer fingerprint);
my $f=readSSL(qw(x509 -noout -sha1), {in=>'crt'}, map {"-$_"} @vars);
while(<$f>)
{
 s/\s*$//;
 /=\s*/	or next;
 my $l=$`;
 my $r=$';
 foreach(@vars) { $A{$_}=$r	if $l=~/$_/i; }
}

print "UNIQUE check...\n";

$A{i}=$::{CFG}{db}{pub}->selectrow_arrayref("Select id From Attrs Where subj=?", undef, $A{issuer})->[0];

$::{CFG}{db}{pub}->selectrow_arrayref("Select count(*) From Certs, Attrs Where Issuer=? And Serial=? And Certs.id=Attrs.id", undef, $A{i}, $A{serial})->[0]
    and die "Certificate by '$A{issuer}\[$A{serial}]' found in DB!\n";

$::{CFG}{db}{pub}->selectrow_arrayref("Select count(*) From Attrs Where SHA1=?", undef, $A{fingerprint})->[0]
    and die "Certificate '$A{fingerprint}' found in DB!\n";

print "Storing to DB...\n";

$::{CFG}{db}{sec}->do("Insert Into Keys(BLOB) Values(?)", undef, readFile('key'));
$A{key}=$::CFG{db}{sec}->sqlite_last_insert_rowid;
$::{CFG}{db}{pub}->do("Insert Into Certs(Key, Issuer, BLOB) Values(?, ?, ?)", undef, $A{key}, $A{i}, readFile('crt'));
$A{N}=$::CFG{db}{pub}->sqlite_last_insert_rowid;
storeAttrs($A{N});

print "Adjust ctime...\n";

my @Sep=qw(20 - - T : :);
my $ctime=$::CFG{db}{pub}->selectrow_arrayref("Select notBefore From Attrs Where id=?", undef, $A{N})->[0];
$ctime=join('', map {shift(@Sep), $_} unpack('(A2)6', $ctime));
$ctime=$::CFG{db}{pub}->selectrow_arrayref("Select datetime(?)", undef, $ctime)->[0];

$ctime
    and $::CFG{db}{pub}->do("Update Certs Set ctime=? Where id=?", undef, $ctime, $A{N})
    and $::CFG{db}{sec}->do("Update Keys Set ctime=? Where id=?", undef, $ctime, $A{key});

1;
