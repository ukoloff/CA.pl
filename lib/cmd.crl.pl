#
# Generate CRL
#

my $crtN=putCA();

my $r=$::CFG{db}{pub}->selectrow_hashref(<<SQL, undef, $::CFG{ca});
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

my $fh;
open $fh, '>', resolveFile('index');

my $s=$::CFG{db}{pub}->prepare(<<SQL);
Select Attrs.serial, subj, notBefore, Revoke, revokeReason
From Certs, Attrs, CA
Where CA.CN=?
And Certs.Issuer=CA.x509 And Certs.id=Attrs.id
And Revoke is not Null
SQL
$s->execute($::CFG{ca});
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

#writeFile('index.attr', '');

openSSL(qw(ca -gencrl), {config=>'conf', out=>'crl'});
saveCRL();
print "Created $::CFG{ca}.crl\n";

1;
