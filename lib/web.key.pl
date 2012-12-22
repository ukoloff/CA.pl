#
# Export private key
#

Lib('AD');

exit	unless A2($::CFG{Job}->valueOf('AD', 'groupR'));

my $Key=$::CFG{db}{pub}->selectrow_arrayref("Select Key From Certs Where id=?", undef, $::{CFG}{web}{n})->[0];
print $::{CFG}{db}{sec}->selectrow_arrayref("Select BLOB From Keys Where id=?", undef, $Key)->[0];

1;
