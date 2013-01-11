use strict;

Lib('Sandbox');
Lib('Template');
Lib('DB');
Lib('OpenSSL');
Lib('Export');

# Load Template by name
sub tLoad
{
 my $f;
 my $t=shift;
 open $f, '<', "$::CFG{root}/template/$t.conf"	or die "Cannot open template '$t': $!\n";
 $t=Template->new;
 $t->read($f);
 close $f;
 return $t;
}

sub tExpand
{
 my $t=shift;

 my $x=$t;
 my @T=();
 my %Loaded;
 while(1)
 {
  push @T, reverse $x->templateNames;
  last	unless scalar @T;
  my $f=shift @T;
  next	if $Loaded{$f};
  $Loaded{$f}=1;
  $t->prepend($x=tLoad($f));
 }
}

sub Job
{
 my $t=shift;

 my $fh;
 open $fh, '>', resolveFile('src');
 $t->print($fh);
 close $fh;

 tExpand($t);
 my $z=tLoad('0');
 tExpand($z);
 $t->prepend($z);

 $z=Template->new;
 $z->fromHash({'paths'=>{DIR=>$::CFG{tmp}}});
 $z->prepend($t);
 $t=$z;

 for my $var(qw(command ca))
 {
  $z=$t->copy;
  $z->expand;
  $z->dropEmptyVars;
  my $val=$z->valueOf($var);
  $val	or die "'$var=' not found in template!\n";

  $z=tLoad("$var/$val");
  tExpand($z);
  $t->prepend($z);

  $z=tLoad("$var/0");
  tExpand($z);
  $t->prepend($z);
 }

 $t->expand;
 $t->dropEmptyVars;

 $::CFG{Job}=$t;
 $::CFG{command}=$t->valueOf('command');
 $::CFG{ca}=$t->valueOf('ca');

 open $fh, '>', resolveFile('conf');
 $t->print($fh);
 close $fh;
}

1;
