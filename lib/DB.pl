use strict;
use DBI;

my $DB="$::CFG{root}/db";
-d $DB	or	mkdir $DB	or die "Cannot create '$DB'!\n";

my %DBs;

foreach my $f(glob("$::CFG{root}/schema/*.sql"))
{
 my $db=basename($f);
 $db=~s/[.].*//;
 $DBs{$db}={mode=>0777, files=>[]}	unless $DBs{$db};
 $DBs{$db}{mode}&=(stat $f)[2];
 push @{$DBs{$db}{files}}, $f;
}

foreach my $f(keys %DBs)
{
 my $p="$DB/$f";
 -d $p	or mkdir $p	or die "Cannot create '$p'!\n";
 chmod(($DBs{$f}{mode}>>2)& 0111 | $DBs{$f}{mode}, $p);

 my $z=DBI->connect("dbi:SQLite:$p/$f.db");
 $::CFG{db}{$f}=$z;
 next	if 2<scalar $z->tables;

 foreach my $q(@{$DBs{$f}{files}})
 {
  open F, '<', $q;
  $z->do($_)	foreach split(/;\s*\n/, join('', <F>));
  close F;
 }
}

undef %DBs;
undef $DB;

1;
