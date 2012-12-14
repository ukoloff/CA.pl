#
# Export certificate in pkcs7 (.p7b) form
#

my $f;
open $f, '>', resolveFile('crts');;

print $f $::CFG{db}{pub}->selectrow_arrayref("Select BLOB From Certs Where id=?", undef, $::CFG{web}{n})->[0];

putChain($f)	if $::CFG{web}{chain};

close $f;

openSSL(qw(crl2pkcs7 -nocrl), {certfile=>'crts'});

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

1;
