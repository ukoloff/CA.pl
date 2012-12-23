#Lib('Errors');

while(<STDIN>)
{
 s/^\s+//; s/\s+$//;
 next	if /^#/;
 my ($k, $v)=split(/\s*=\s*/, $_, 2);
 $::{CFG}{web}{$k}=$v;
}

die "Invalid command '$::{CFG}{web}{command}'!\n"	unless $::{CFG}{web}{command}=~/^\w+$/;

storeIni();

Lib("web.$::{CFG}{web}{command}");

sub storeIni
{
 $::CFG{db}{pub}->do(<<SQL);
Create Temp Table Z(
 n	VarChar(255) Unique,
 v	Text
)
SQL

 my $s=$::CFG{db}{pub}->prepare("Insert Into Z(n, v) Values(?, ?)");
 $s->execute('OpenSSL', $::CFG{Job}->valueOf('ini', 'openssl'));
 $s->execute('groupC', $::CFG{Job}->valueOf('AD', 'groupC'));
 $s->execute('groupR', $::CFG{Job}->valueOf('AD', 'groupR'));

 $::CFG{db}{pub}->do(<<SQL);
Update Ini
Set Value=(Select v From Z Where n=Name)
Where Exists(Select * From Z Where n=Name And v<>Value)
SQL

 $::CFG{db}{pub}->do(<<SQL);
Insert Into Ini(Name, Value)
Select n, v From Z Where n Not In(Select Name From Ini)
SQL

 $::CFG{db}{pub}->do('Drop Table Z');

}

1;
