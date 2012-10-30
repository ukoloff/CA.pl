#
# Entry point
#

Lib('Help')	unless @ARGV;
Lib('CA');

my $t=getOpt();
Job($t);

die "Invalid command '$::CFG{command}'!\n"	unless $::CFG{command}=~/^\w+$/;

Lib("cmd.$::CFG{command}");

sub getOpt
{
 my $t=Template->new;
 my $x='';
 my $N=1000;
 foreach my $a(@ARGV)
 {
  if('t' eq $x)
  {
   $t->fromHash({'template.'.$N++=>$a});
   $x='';
   next;
  }
  if('c' eq $x)
  {
   $t->fromHash({command=>$a});
   $x='';
   next;
  }
  if($a=~'=')
  {
   my @X=split '=', $a, 2;
   $t->fromHash($X[0]=~/^(.*?)::(.*)$/? {$1=>{$2=>$X[1]}} : {$X[0]=>$X[1]});
   next;
  }
  if($a=~/^-/)
  {
   $a=~s/^-//;
   $x=$a, next	if $a=~/^[tc]$/;
   $t->fromHash({command=>$a});
   next;
  }
  my $fh;
  open $fh, '<', $a	or die "Cannot open '$a':$!\n";
  my $t2=Template->new;
  $t2->read($fh);
  close($fh);
  $t2->prepend($t);
  $t=$t2;
 }
 return $t;
}

1;
