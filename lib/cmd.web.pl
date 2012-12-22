#Lib('Errors');

while(<STDIN>)
{
 s/^\s+//; s/\s+$//;
 next	if /^#/;
 my ($k, $v)=split(/\s*=\s*/, $_, 2);
 $::{CFG}{web}{$k}=$v;
}

die "Invalid command '$::{CFG}{web}{command}'!\n"	unless $::{CFG}{web}{command}=~/^\w+$/;

Lib("web.$::{CFG}{web}{command}");

1;
