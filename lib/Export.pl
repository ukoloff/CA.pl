sub exportCrt
{
 my $x=$::{CFG}{Job}->valueOf('post', 'export');
 return	unless $x;

 $::CFG{N}=shift;

 my $p=resolveFile("/export");
 -d $p	or mkdir $p;
 chmod 0700, $p;

 print "Exporting...\n";
 foreach $x(split /\s*,\s*/, $x)
 {
  txtExport(), next	if($x eq 'txt');
  derExport(), next	if($x eq 'der');
  keyExport(), next	if($x eq 'key');
  crtExport($1), next	if($x=~/^crt([+])?/);
  p7bExport($1), next	if($x=~/^p7b([+])?/);
  pemExport($1), next	if($x=~/^pem([+])?/);
  pfxExport($1, $3), next	if($x=~/^pfx([+])?(\/(.*))?/);
  print "Ignored unknown export format '$x'\n";
 }
}

sub exportCAs
{
 return 'crt0'	unless $_[0];
 return 'crts'	if $::CFG{exportCAs}++;
 my %NN;
 my $s=$::CFG{db}{pub}->prepare("Select Issuer, BLOB From Certs Where id=?");
 my $fh;
 open $fh, '>', resolveFile('crts');
 my $N=$::CFG{N};
 while($N)
 {
  $NN{$N}=1;
  $s->execute($N);
  my @r=$s->fetchrow_array;
  print $fh $r[1];
  $N=$r[0];
  last	if $NN{$N};
 }
 close $fh;
 return 'crts';
}

sub txtExport
{
 my $fh=readSSL(qw(x509 -noout -text), {in=>'crt0'});
 writeFile("/export/$::CFG{N}.txt", join('', <$fh>));
 close $fh;
 print "Created $::CFG{N}.txt\n";
}

sub derExport
{
 openSSL(qw(x509 -outform der), {in=>'crt0', out=>"/export/$::CFG{N}.cer"});
 print "Created $::CFG{N}.cer\n";
}

sub key2export
{
 my $k=readFile('keyx')||readFile('key');
 return $k	if $k;
 print "Key not found to export!\n";
 return;
}

sub keyExport
{
 writeFile("/export/$::CFG{N}.key", key2export());
 print "Created $::CFG{N}.key\n";
}

sub crtExport
{
 writeFile("/export/$::CFG{N}.crt", readFile(exportCAs(@_)));
 print "Created $::CFG{N}.crt\n";
}

sub p7bExport
{
 openSSL(qw(crl2pkcs7 -nocrl), {certfile=>exportCAs(@_), out=>"/export/$::CFG{N}.p7b"});
 print "Created $::CFG{N}.p7b\n";
}

sub pemExport
{
 writeFile("/export/$::CFG{N}.pem", key2export().readFile(exportCAs(@_)));
 print "Created $::CFG{N}.pem\n";
}

sub pfxExport
{
 my ($plus, $pass)=@_;
 unless(-f resolveFile('key')){print "Key to export not found!\n"; return; }

 my @cmd=(qw(pkcs12 -export -passout), "file:".resolveFile('pfxPass'));
 if('?' eq $pass)
 {
  print "OpenSSL will prompt you for PFX password now:\n";
  pop(@cmd); pop(@cmd);
 }
 elsif(!$pass)
 {
  $pass=substr(randomHash(), -8);
  print "PFX will be encrypted with '$pass' password.\n";
 }
 writeFile('pfxPass', $pass);

 openSSL(@cmd, {in=>exportCAs($plus), inkey=>'key', out=>"/export/$::CFG{N}.pfx"});
 print "Created $::CFG{N}.pfx\n";
}

1;
