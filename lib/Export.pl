sub exportCrt
{
 my $N=shift;
 my $x=$::{CFG}{Job}->valueOf('post', 'export');
 return	unless $x;

 my $p=$::CFG{root}."/export";
 -d $p	or mkdir $p;
 chmod 0700, $p;
}

1;
