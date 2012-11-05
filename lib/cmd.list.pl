#
# List certificates signed by CA
#

my $s=$::CFG{db}{pub}->prepare(<<SQL);
Select Attrs.*, Revoke, revokeReason
From CA, Certs, Attrs
Where CA.CN=?
And Certs.Issuer=CA.x509 And Certs.id=Attrs.id
Order By Certs.ctime
SQL

$s->execute($::CFG{ca});
while(my $r=$s->fetchrow_hashref)
{
 my $R=$r->{Revoke}? "\t$r->{Revoke}/".($r->{revokeReason}||'?'): '';
 print "$r->{id}/$r->{serial}\t$r->{notBefore}-$r->{notAfter}\t$r->{subj}$R\n";
}

1;
