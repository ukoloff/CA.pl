use strict;

Lib('Sandbox');
Lib('DB');

sub buildCmd
{
 $::CFG{bin}|=$::CFG{Job}->valueOf('ini', 'openssl');
 my @R=($::CFG{bin});
 foreach my $a(@_)
 {
  'HASH' eq ref($a)	or push(@R, $a), next;
  push(@R, "-$_", resolveFile($a->{$_}))	foreach sort keys %$a;
 }
 return @R;
}

sub openSSL
{
 system(buildCmd(@_));
 -1==$?	and die "Exec error: $!\n";
 my $r=$?>>8;
 $r	and die "OpenSSL exit($r)!\n";
}

sub readSSL
{
 my $f;
 open $f, '-|', buildCmd(@_)	or die "Cannot start OpenSSL: $!\n";
 return $f;
}

sub randomSerial
{
 return	unless $::CFG{Job}->valueOf('ini', 'serial')=~m|^random(/(\d+))?$|i;
 my $n=$2||8;
 $::CFG{randomSerial}=$n;
 my $x=$::CFG{db}{pub}->prepare("Select Count(*) From Attrs Where serial=?");
 while(1)
 {
  my $s=substr(randomHash(), -2*$n);
  $x->execute($s);
  return $s	unless $x->fetchrow_arrayref->[0];
 }
}

sub putCA
{
 my $R=$::CFG{db}{pub}->selectrow_hashref(<<SQL, undef, $::CFG{ca});
Select
 CA.x509, CA.serial, Certs.BLOB, Certs.Key
From CA, Certs
Where CA.x509=Certs.id And CN=?
SQL
 die "Cannot find CA '$::CFG{ca}' in DB!\n"	unless $R;
 writeFile('serial', randomSerial || $R->{serial});
 writeFile('ca.crt', $R->{BLOB});
 writeFile('index', '');
 writeFile('ca.key', ($::CFG{db}{sec}->selectrow_array("Select BLOB From Keys Where id=?", undef, $R->{Key}))[0]);
 return $R->{x509};
}

sub updateSerial
{
 return	if $::CFG{randomSerial};
 my $s=readFile('serial');
 $s=~s/\s+$//;
 $::CFG{db}{pub}->do("Update CA Set Serial=? Where CN=?", undef, $s, $::CFG{ca});
}

sub newKey
{
 openSSL('genrsa', {out=>'key'}, $::CFG{Job}->valueOf('req', 'default_bits')||1024);
}

sub genPass
{
 return substr(randomHash(), -12);
}

sub storeKey
{
 my $p=$::CFG{Job}->valueOf('post', 'password');

 if('+' eq $p or 'generate' eq lc($p))
 {
  $p=genPass();
  print "Secret key encrypted with password '$p'\n";
 }

 if($p)
 {
  my @cmd=(qw(rsa), '-'.($::CFG{Job}->valueOf('ini', 'enc')||'des3'), {in=>'key', out=>'keyx'});
  if('?' ne $p and 'prompt' ne lc($p))
  {
   writeFile('pass', $p);
   push @cmd, qw(-passout), 'file:'.resolveFile('pass');
  }
  print "Encrypting secret key...\n";
  openSSL(@cmd);
 }

 $::CFG{db}{sec}->do("Insert Into Keys(BLOB) Values(?)", undef, readFile($p? 'keyx': 'key'));
 return $::CFG{db}{sec}->sqlite_last_insert_rowid;
}

sub storeAttrs
{
 my $N=shift;

 writeFile('attr', ($::CFG{db}{pub}->selectrow_array("Select BLOB From Certs Where id=?", undef, $N))[0]);

 my %Attrs;

 my $f=readSSL(qw(x509 -noout -sha1 -serial -subject -fingerprint -email), {in=>'attr'});
 while(<$f>)
 {
  s/^\s+//; s/\s+$//;
  next	unless length($_);
  $Attrs{email}=$_, next	unless /=\s*/;
  my $l=$`;
  my $r=$';
  foreach(qw(serial subject fingerprint))
  {
   $Attrs{$_}=$r	if $l=~/$_/i;
  }
 }
 close($f);

 $f=readSSL(qw(asn1parse), {in=>'attr'});
 while(<$f>)
 {
  /\s+UTCTIME\s*:(\S+)\s*$/	or next;
  if($Attrs{notBefore})
  {
   $Attrs{notAfter}=$1;
   last;
  }
  $Attrs{notBefore}=$1;
 }
 close($f);

 $::CFG{db}{pub}->do("Insert Or Replace Into Attrs(id, serial, subj, email, SHA1, notBefore, notAfter) Values(?,?,?,?,?,?,?)", undef,
    $N, $Attrs{serial}, $Attrs{subject}, $Attrs{email}, $Attrs{fingerprint}, $Attrs{notBefore}, $Attrs{notAfter});

 return unless $_[0];

 my @Sep=qw(20 - - T : :);
  my $ctime=join('', map {shift(@Sep), $_} unpack('(A2)6', $Attrs{notBefore}));
 $ctime=$::CFG{db}{pub}->selectrow_arrayref("Select datetime(?)", undef, $ctime)->[0];
 return	unless $ctime;

 $::CFG{db}{pub}->do("Update Certs Set ctime=? Where id=?", undef, $ctime, $N);
 my $K=$::CFG{db}{pub}->selectrow_arrayref("Select Key From Certs Where id=?", undef, $N)->[0];
 $K	and $::CFG{db}{sec}->do("Update Keys Set ctime=? Where id=?", undef, $ctime, $K);

}

sub storeNewAttrs
{
 my $s=$::CFG{db}{pub}->prepare("Select id From Certs Where id Not in(Select id From Attrs)");
 $s->execute();
 while(my @r=$s->fetchrow_array){ storeAttrs($r[0], $_[0]); }
}

sub storeCA
{
 my $ca=$::CFG{Job}->valueOf('post', 'ca');
 return	unless $ca;

 my $N=shift;
 $::CFG{db}{pub}->do("Insert Into CA(CN, x509) Values(?, ?)", undef, $ca, $N);

 print "New CA '$ca' created. It's time to create/edit $::CFG{root}/template/ca/$ca.conf\n";
}

1;
