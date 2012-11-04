#
# Create new key+certificate+sign
#

my $crtN=putCA();

print "Generating key...\n";
newKey();

print "Generating request...\n";
openSSL(qw(req -new), {config=>'conf', key=>'key', out=>'req'});

print "Signing...\n";
openSSL(qw(ca), {config=>'conf', in=>'req', out=>'crt'});
openSSL(qw(x509), {in=>'crt', out=>'crt0'});

print "Saving...\n";
my $keyN=storeKey();
$::CFG{db}{pub}->do("Insert Into Certs(Key, Issuer, BLOB) Values(?, ?, ?)", undef, $keyN, $crtN, readFile('crt0'));
my $N=$::CFG{db}{pub}->sqlite_last_insert_rowid;
updateSerial();
storeAttrs($N);
storeCA($N);
exportCrt($N);

1;
