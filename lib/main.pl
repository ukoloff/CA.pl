#
# Entry point
#

Lib('Help')	unless 1==@ARGV;
Lib('CA');

my $t=Template->new;
my $fh;
open $fh, '<', $ARGV[0]	or die "Cannot open '$ARGV[0]': $!\n";
$t->read($fh);
close $fh;

Job($t);

die "Invalid command '$::CFG{command}'!\n"	unless $::CFG{command}=~/^\w+$/;

Lib("cmd.$::CFG{command}");

1;
