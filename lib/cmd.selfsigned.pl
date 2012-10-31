#
# Create new self-signed certificate
#

print "Generating key...\n";
newKey();

print "Primary request...\n";
openSSL(qw(req -new -x509 -set_serial 0), {config=>'conf', key=>'key', out=>'ca.crt'});

writeFile('index', '');
writeFile('serial', '00');
writeFile('ca.key', readFile('key'));

print "Final signing...\n";
openSSL(qw(ca), {config=>'conf', ss_cert=>'ca.crt', out=>'crt'});
openSSL(qw(x509), {in=>'crt', out=>'crt0'});

print "Saving...\n";
my $keyN=storeKey();
$::CFG{db}{pub}->do("Insert Into Certs(Key, BLOB) Values(?, ?)", undef, $keyN, readFile('crt0'));
my $N=$::CFG{db}{pub}->sqlite_last_insert_rowid;
$::CFG{db}{pub}->do("Update Certs Set Issuer=id Where id=?", undef, $N);
storeAttrs($N);
storeCA($N);

1;
