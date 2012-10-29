use strict;
use DBI;

foreach my $x(qw(pub sec))
{
 my $p="$::CFG{root}/db/$x";
 -d $p	or mkdir $p;
 my $f="$p/$x.db";
 my $z=DBI->connect("dbi:SQLite:$f");
 $::CFG{db}{$x}=$z;
 next	if 2<scalar $z->tables;
 my @stat=stat $p;
# chown $stat[4], $stat[5], $f;
 open F, '<', "$p.sql";
 $z->do($_)	foreach split(/;\s*\n/, join('', <F>));
 close F;
}

chmod 0700, "$::CFG{root}/db/sec";

1;
