#
# Sign certificate request or selfsigned sertificate
#

my $req=$::CFG{Job}->valueOf(req)	or die "Request not specified!\n";

my $key;

eval{ openSSL(qw(req -in), $req, {out=>'req'}); $key='in'; };
eval{ openSSL(qw(x509 -in), $req, {out=>'req'}); $key='ss_cert'; }	unless $key;
die "'$req' is neither X509 certificate nor certificate request!\n"	unless $key;

my $crtN=putCA();

print "Signing...\n";
openSSL(qw(ca), {config=>'conf', $key=>'req', out=>'crt'});
openSSL(qw(x509), {in=>'crt', out=>'crt0'});

print "Saving...\n";
$::CFG{db}{pub}->do("Insert Into Certs(Issuer, BLOB) Values(?, ?)", undef, $crtN, readFile('crt0'));
my $N=$::CFG{db}{pub}->sqlite_last_insert_rowid;
updateSerial();
storeAttrs($N);
$::CFG{db}{pub}->do("Insert Into Log(id, src, job, req) Values(?, ?, ?, ?)", undef, $N, readFile('src'), readFile('conf'), readFile('req'));

1;
