package Fragment;
use strict;

sub new
{
 my $class= shift;
 my $self={};

 return bless($self, $class);
}

sub assign
{
 my ($self, $s)=@_;

 delete $self->{Var};
 delete $self->{Section};
 delete $self->{Env};

 $s=~s/\r\n?/\n/g;
 my $f='';
 my $q;
 while(length($s))
 {
  my $qq=($q or '\'"#<');
  $s=~s/^(.*?)([\\\n$qq])//	or last;
  $f.=$1;
  if("#" eq $2 or "\n" eq $2 or "<" eq $2)
  {
   $f.="\\".$2;
   next;
  }
  if("\\" eq $2)
  {
   $s=~s/^(.)//	and $f.="\\".$1;
   next;
  }
  $f.=$2;
  $q=$q? undef : $2;
 }
 $self->{Value}=$f.$s.$q;
}

sub isVar
{
 my $self=shift;
 return exists $self->{Var};
}

sub asString
{
 my $self=shift;
 if($self->isVar)
 {
  my $s=$self->{Var};
  $s=$self->{Section}.'::'.$s	if defined($self->{Section});
  return '<'.$s.'>';
 }
 return '<ENV::'.$self->{Env}.'>'	if exists $self->{Env};
 return $self->{Value};
}

sub unEscape
{
 my $self=shift;
 return $self->asString		if $self->isVar;
 return $ENV{$self->{Env}}	if exists $self->{Env};
 my $s=$self->{Value};
 my $r='';
 my $q=undef;
 while(length($s))
 {
  my $qq = $q? $q : "'\"";
  $s=~ s/^(.*?)([$qq\\])// or return $r.$s;
  $r.=$1;
  if("\\" ne $2)
  {
   $q= $q? undef : $2;
   next;
  }
  $s=~s/^(.)//s;
  next if "\n" eq $1;	# \<LF> -> nothing (New Line)
  if($q)
  {
   $r.=$1;      	# "\n" -> n 
   next;   	
  }
  $r.= eval("\"\\$1\"");
 }
 return $r;
}

sub pointsTo
{	# return Var object reffered by Fragment object
 my ($self, $template)=@_;

 return unless ref($template) and $self->isVar;
 my $s= defined($self->{Section})? $template->{lc($self->{Section})} : $template->{Main};
 return	unless ref($s);
 $s=$s->{lc($self->{Var})};
 return unless ref($s);
 return $s;
}

1;
