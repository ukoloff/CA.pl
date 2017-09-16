#
# Export pkcs12 (.pfx)
#

use Digest::MD5;

Lib('AD');

exit	unless A2($::CFG{Job}->valueOf('AD', 'groupR'));

writeFile('pass', $::{CFG}{web}{old} ? oldStylePass() : $::{CFG}{web}{pass} || "\n");
my $r=$::CFG{db}{pub}->selectrow_hashref("Select Key, BLOB From Certs Where id=?", undef, $::{CFG}{web}{n});
my $f;
open $f, '>', resolveFile('pem');
print $f $::{CFG}{db}{sec}->selectrow_arrayref("Select BLOB From Keys Where id=?", undef, $r->{Key})->[0], $r->{BLOB};
putChain($f)	if $::CFG{web}{chain};
close $f;

openSSL(qw(pkcs12 -export -passout), 'file:'.resolveFile('pass'), {in=>'pem', out=>'pfx'});
print encode_base64(readFile('pfx'), ''), "\n";

sub putChain
{
 my $f=shift;
 my $n=$::CFG{web}{n};
 my %Z;
 $Z{$n}=1;
 my $s=$::CFG{db}{pub}->prepare("Select id, BLOB From Certs Where id=(Select Issuer From Certs Where id=?)");
 while(1)
 {
  $s->execute($n);
  my $r=$s->fetchrow_hashref;
  last	unless $r;
  last	if $Z{$r->{id}};
  print $f $r->{BLOB};
  $n=$r->{id};
  $Z{$n}=1;
 }
}

sub oldStylePass
{
 my $u=$::{CFG}{db}{pub}->selectrow_arrayref("Select u From User Where id=?", undef, $::{CFG}{web}{n})->[0];
 $u	or exit;
 return uc(substr(Digest::MD5::md5_hex($u."!\n"), 0, 15))
}

1;