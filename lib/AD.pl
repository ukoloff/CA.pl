use strict;
use Net::LDAP;
use Net::LDAP::Util;
use MIME::Base64;

adConnect()	or die "Cannot connect to AD!\n";
A1(decode_base64($::CFG{web}{authUser}), decode_base64($::CFG{web}{authPass}))	or die "AD auth failed!\n";

sub adConnect
{
 for my $i(1..5)
 {
  my $h=Net::LDAP->new($::{CFG}{AD}{DC}, onerror => 'undef')	
    or	next;
  $h->start_tls or next;
  $::CFG{AD}{h}=$h;
  my $Root=$h->search(filter=>"objectClass=*", scope=>'base')->entry(0);
  $::CFG{AD}{Base}=$Root->get_value('defaultNamingContext');
  $::CFG{AD}{Domain}=(values %{Net::LDAP::Util::ldap_explode_dn($::CFG{AD}{Base})->[0]})[0];
  return 1;
 }
}

sub u2dn
{
 my $q=$::CFG{AD}{h}->search(base=>$::CFG{AD}{Base}, scope=>'sub', attrs=>['1.1'], filter=>'sAMAccountName='.Net::LDAP::Util::escape_filter_value(shift));
 return	unless 1==$q->count;
 return $q->entry(0)->dn;
}

sub dn2u
{
 my $q=$::CFG{AD}{h}->search(base=>$_[0], scope=>'base', attrs=>['sAMAccountName'], filter=>"objectClass=*");
 return	unless 1==$q->count;
 return $q->entry(0)->get_value('sAMAccountName');
}

# Authentication: Тот ли, за кого себя выдаёт?
sub A1
{
 my ($u, $pass)=@_;
 return	unless length($u) and length($pass);
 $::CFG{AD}{h}->bind($::CFG{AD}{Domain}."\\".$u, password=>$pass)	or return;
 $::CFG{AD}{u}=dn2u($::CFG{AD}{udn}=u2dn($u));
 return 1;
}

# Authorization: Имеет ли право? // Group membership
sub A2
{
 my $g=u2dn($_[0]);
 $g	or return;

 my @Q=($::CFG{AD}{udn});
 my %Seen;
 while(@Q)
 {
  my $q=$::CFG{AD}{h}->search(base=>pop(@Q), scope=>'base', filter=>'objectClass=*', attrs=>['memberOf'])->entry(0);
  foreach my $dn($q->get_value('memberOf'))
  {
   return 1	if $dn eq $g;
   next		if $Seen{$dn};
   $Seen{$dn}=1;
   push @Q, $dn;
  }
 }
}

1;
