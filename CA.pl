#!/usr/bin/perl

use strict;
use File::Basename;

$< == (stat $0)[4] or die "Run $0 as @{[(getpwuid((stat $0)[4]))[0]]}!";

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
