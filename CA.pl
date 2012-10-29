#!/usr/bin/perl

use strict;
use File::Basename;

$<	and die "Run $0 as root!\n";

$::CFG{0}=$0;
$0=basename($0);
$::CFG{root}=dirname($::CFG{0});
$|=1;

$ENV{PATH}='/bin/';
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

Lib('main');

sub Lib
{
 my $f=shift;
 require "$::CFG{root}/lib/$f.pl" ;
}

__END__
