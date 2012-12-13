use strict;
use Text::Iconv;

sub translit
{
 $_=shift;
 my %T=qw(¸ yo æ zh ö ts ÷ ch ø sh ù sch þ yu ÿ ya ¨ Yo Æ Zh Ö Ts × Ch Ø Sh Ù Sch Þ Yu ß Ya);
 my $K=join('', keys %T);
 s/[$K]/$T{$&}/g;
 tr/àáâãäåçèéêëìíîïðñòóôõúûüýÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÚÛÜÝ/abvgdeziyklmnoprstufh'y'eABVGDEZIYKLMNOPRSTUFH'Y'E/;
 return $_;
}

sub utfTranslit
{
 return translit(Text::Iconv->new("utf-8", "cp1251")->convert($_[0]))
}

1;
