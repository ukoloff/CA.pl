#
# Output PFX to user via WWW
#

$::CFG{db}{sec}->do("Delete From iPFX Where xtime<datetime()");

doPre()		if 'pre' eq $::CFG{web}{step};
doBLOB()	if 'BLOB' eq $::CFG{web}{step};

sub doPre
{ # Generate nonce
 my $s=$::CFG{db}{sec}->prepare("Select Count(*) From iPFX Where Cookie=?");
 my ($Cookie, $nonce);
 do{
  $nonce=randomHash64();
  ($Cookie, $nonce)=unpack('A'.(length($nonce)>>1).'A*', $nonce);
  $s->execute($Cookie); 
 } while($s->fetchrow_arrayref->[0]);
 $::CFG{db}{sec}->do("Insert Into iPFX(Cookie, nonce, xtime) Values(?, ?, datetime('now', '+1 minute'))", undef, $Cookie, $nonce);
 print "$Cookie\nhttp://ad.ekb.ru/auth/pfx/?nonce=$nonce\n";
}

sub doBLOB
{
 exit	unless $::CFG{web}{Cookie}=~/^\w+$/;
 exit	unless $::CFG{web}{Ticket}=~/^\w+$/;
 my $nonce=$::CFG{db}{sec}->selectrow_arrayref("Select nonce From iPFX Where Cookie=?", undef, $::CFG{web}{Cookie})->[0];
 exit	unless length($nonce);

 require LWP::UserAgent;
 my $u=LWP::UserAgent->new->post('https://ad.ekb.ru/auth/pfx/get/', {Ticket=>$nonce.$::CFG{web}{Ticket}})->header('X-U');
 length($u)	or exit;	# No user, no pfx
 print $u, "\n";

 $::CFG{db}{sec}->do("Update iPFX Set nonce=Null Where Cookie=?", undef, $::CFG{web}{Cookie});

 my $p=$::CFG{db}{pub}->selectrow_hashref("Select Certs.* From Certs, User Where u=? And User.id=Certs.id And Revoke is Null Order By ctime Desc", undef, $u);
 $p	or exit;
 writeFile('crt', $p->{BLOB});
 writeFile('key', $::CFG{db}{sec}->selectrow_arrayref('Select BLOB From Keys Where id=?', undef, $p->{Key})->[0]);
 writeFile('pass', substr($::CFG{web}{Cookie}, 2, 5));
 openSSL(qw(pkcs12 -export -passout), 'file:'.resolveFile('pass'), {in=>'crt', inkey=>'key', out=>'pfx'}, '-name', $u);
 print encode_base64(readFile('pfx'), ''), "\n";
}

1;
