use strict;

Lib('Sandbox');
Lib('Template');
Lib('DB');
Lib('OpenSSL');

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
 $t->fromHash({'paths'=>{DIR=>$::CFG{tmp}}});

 $z=$t->copy;
 $z->expand;
 $z->dropEmptyVars;
 my $ca=$z->valueOf('ca');
 $ca	or die "CA not specified!\n";
 $::{CFG}{ca}=$ca;

 $ca=tLoad("ca/$ca");
 tExpand($ca);
 $t->prepend($ca);

 $ca=tLoad("ca/0");
 tExpand($ca);
 $t->prepend($ca);

 $t->expand;
 $t->dropEmptyVars;

 $::CFG{Job}=$t;
 $::{CFG}{command}=$t->valueOf('command');

 open $fh, '>', resolveFile('conf');
 $t->print($fh);
 close $fh;
}

1;
