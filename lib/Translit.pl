use strict;
use Text::Iconv;

sub translit
{
 $_=shift;
 my %T=qw(� yo � zh � ts � ch � sh � sch � yu � ya � Yo � Zh � Ts � Ch � Sh � Sch � Yu � Ya);
 my $K=join('', keys %T);
 s/[$K]/$T{$&}/g;
 tr/��������������������������������������������������/abvgdeziyklmnoprstufh'y'eABVGDEZIYKLMNOPRSTUFH'Y'E/;
 return $_;
}

sub utfTranslit
{
 return translit(Text::Iconv->new("utf-8", "cp1251")->convert($_[0]))
}

1;
