package Var;
use strict;

::Lib('Fragment');

=head1 NAME

Var - template variables handling routines

=head1 SYNOPSIS

 $v=Var->new('x');
 $v->assign('CA:<Params::isCA>');
 $section->add($v);

=head1 DESCRIPTION

Variable object represent one string C<var=value> of Template. It can
contain:

=over

=item Static strings

=item References to other variables C<< (<Section::Variable>) >>

=item Special variables C<< <ENV::Name> >> that refers to environment strings

=item Comment field: C< # any text... >

=back

According to OpenSSL.conf practice variables use quotes (both C<'...'> and C<"...">)
for screening of special characters - everything between quotes is taken literally.
Also backslash (\) force the following character to be taken literally 
(eg it can be used to C<"insert \" inside quotes">, and also outside
quotes it can be used to insert some special characters (eg \n for newline).

=head1 METHODS

=over

=cut

=item sub new($name)

Creates new variable object with empty content.

=cut

sub new
{
 my ($class, $name)= @_;
 my $self={};
 $self->{Name}=$name;
 $self->{Fragments}=[];

 bless($self, $class);
 return $self;
}

=item $copy=$v->copy()

Makes (almost) exact copy of variable. Comment and other stuff is not copied. 
Used fragments are not copied but shared by old and new versions of variables.

=cut

sub copy
{
 my $self=shift;
 my $z=Var->new($self->{Name});
 push @{$z->{Fragments}}, @{$self->{Fragments}};
 return $z;
}

=item $v->isEmpty()

Return true if variable is empty, that is contains no data at all. 
Eg, C<var=''> is not empty, and C<var=> is.

=cut

sub isEmpty
{
 my $self=shift;
 return not scalar @{$self->{Fragments}};
}

=item $v->asString()

Returns a string representation of variable value, so it can be written
to a text file, for example. Special characters remains escaped/quoted.

See also unEscape() method, that removes quotes and escapes from result.

=cut

sub asString
{
 my $self=shift;
 my $r='';
 foreach my $f(@{$self->{Fragments}})
 {
  $r.=$f->asString;
 }
 $r=~s/^(\s+)/'$1'/;
 $r.="''"	if $r=~/\s\z/;
 return $r;
}

=item $v->assign($str)

This is reverse function of asString(). Given a string representation it
reconstructs all fragments at puts them into variable guts.

This method assumes $str is properly formatted. It performs some check
and cleanups though (eg. closes unclosed quotes).

=cut

sub assign
{	# Parse string and assign it to $Var
 my ($self, $s)=@_;
 $s=~s/\r\n?/\n/g;
 my $f='';
 my $q;
 while(length($s))
 {
  my $qq=($q or '\'"#<');
  $s=~s/^(.*?)([\\\n$qq])//	or last;
  $f.=$1;
  if("#" eq $2 or "\n" eq $2)
  {
   $f.="\\".$2;
   next;
  }
  if("\\" eq $2)
  {
   $s=~s/^(.)//	and $f.="\\".$1;
   next;
  }
  if('<' eq $2)
  {
   $self->add($f);
   $f='';
   my $var;
   if($s=~s/(.*?)>//)
   {
    $var=$1;
   }
   else
   {
    $var=$s;
    $s='';
   }
   $var=~s/^\s+//; $var=~s/\s+$//; $var=~s/[\r\n]/ /g;
   my $section=undef;
   if($var=~s/^(.*)::\s*//)
   {
    $section=$1;
    $section=~s/\s+$//;
   }
   $self->addVar($section, $var);
   next;
  }
  $f.=$2;
  $q=$q? undef : $2;
 }
 $self->add($f.$s.$q);
}

=item $str=$v->unEscape()

Returns string representation of variable value. Unlike asString() method
it returns `raw' string. All escapings are unescaped and (nonescaped) quotes
removed. So for C<var=''> empty string is returned.

=cut

sub unEscape
{
 my $self=shift;
 my $r='';
 foreach my $f(@{$self->{Fragments}})
 {
  $r.=$f->unEscape;
 }
 return $r;
}

=item $v->dependsOn()

Returns number of variables this one depends on.

=cut

sub dependsOn
{
 my $self=shift;
 my $r=0;
 foreach my $f(@{$self->{Fragments}})
 {
  $r++	if $f->isVar;
 }
 return $r;
}

=item $v->printComment( [file] )

Prints $v->{Comment} if it is defined.

See also L<BUGS|/bugs>.

=cut

sub printComment
{
 my ($self, $fh)=@_;
 my $s=$self->{Comment};
 $s=~s/\s+$//;
 return unless length($s);
 $fh=*STDOUT	unless $fh;
 foreach my $ss(split /\n/, $s)
 {
  $ss=~s/\s+$//;
  $ss.=' '	if $ss=~/\\$/;
  print $fh '#', $ss, "\n";
 }
 print $fh "\n";
}

=item $v->print( [file] )

Prints full definition of variable to a text file.

=cut

sub print
{
 my ($self, $fh)=@_;
 $fh=*STDOUT	unless $fh;
 print $fh $self->{Name}, "\t= ",$self->asString, "\n";
 $self->printComment($fh);
}

=item $v->trimComment()

This method trim trailing spaces from $v->{Comment} and if the latter
becomes empty, totally deletes it. It is called at the end of
reading template from text file by Template::read.

See also L<BUGS|/bugs>.

=cut

sub trimComment
{
 my $self=shift;
 return unless exists $self->{Comment};
 my $s=$self->{Comment};
 $s=~s/\s+$//;
 if($s)
 {
  $self->{Comment}=$s;
  return;
 }
 delete($self->{Comment});
}

=item $v->add($str)

Adds static fragment to contents of variable. This string assumed to
be properly formated, eg all quotes and special characters properly
quoted/escaped.

Fool-proof version of this method is addRawStr().

=cut

sub add
{
 my ($self, $str)=@_;
 return	unless length($str);
 my $f=Fragment->new;
 $f->{Value}=$str;
 push @{$self->{Fragments}}, $f;
}

=item $v->addRawStr($str)

Adds static fragment to contents of variable. All special characters in $str
are properly escaped/quoted.

=cut

sub addRawStr
{
 my ($self, $str)=@_;
 return	unless length($str);
 my $r='';
 my $N=0;
 $str=~s/\r\n?/\n/g;
 $str=~s/\\/\\\\/g;
 foreach my $s(split /\n/, $str)
 {
  next unless $s=~/["'#<\s]/;
  if($s!~/\'/)
  {
   $s="'$s'";
   next;
  }
  $s=~s/"/\\"/g;
  $s="\"$s\"";
 }continue{
  $r.="\\n\\\n"	if $N;
  $N=1;
  $r.=$s;
 }
 $self->add($r);
}

=item $v->addVar($section, $name)

Add fragment that refers to a variable $name in section $section C<< (<$section::$name>) >>.

If $section is undef this result in variable in main section. $section='ENV' leads
to special case - using environment variable (%ENV).

=cut

sub addVar
{
 my ($self, $section, $var)=@_;
 my $f=Fragment->new;
 if('env' eq lc($section))
 {
  $f->{Env}=$var;
 }
 else
 {
  $f->{Section}=$section;
  $f->{Var}=$var;
 }
 push @{$self->{Fragments}}, $f;
}

=item $v->expandEnv()

Replaces all C<< <ENV::Name> >> fragments with values from environment.

=cut

sub expandEnv
{
 my $self=shift;
 my $Fr=$self->{Fragments};
 $self->{Fragments}=[];
 foreach my $f(@$Fr)
 {
  if($f->{Env})
  {
   $self->addRawStr($ENV{$f->{Env}});
   next;
  }
  push @{$self->{Fragments}}, $f;
 }
}

=item $v->addDependency($var)

This is a core of Template::expandVars and Template::copySections.

During this methods every $var contains $var->{In} and $var->{On} hashes,
that refers to variables, that [In] are used in definition of $var and
[On] depend on $var respectively. Not just directly dependent, but also
transitievly. For example, if C<< a=<b>; b=<c> >> then

 a->{In}={}
 a->{On}={Nb=>b, Nc=>c}
 b->{In}={Na=>a}
 b->{On}={Nc=>c}
 c->{In}={Na=>a, Nb=>b}
 c->{On}={}

Method addDependency() updates {In} and {Out} for all variables involved:

=over

=item mark $v depends on $var

=item mark $v depends on 'grandsons' (that $var depends on)

=item mark 'granpas' (that depend on $v) depends also on $var

=item mark every 'granpa' depends on every 'grandson'

=back

But if $var is already dependent on $v (directly or transitievly) this method
refuses to work and returns error to a caller.

This algorithm may be time and memory consuming for big and complex templates
(up to O(N^4)), but in real life most template variables unite in clusters,
so complexity should be O(N^2) or even O(N)

See also L<BUGS|/bugs>.

=cut

sub addDependency
{
 my ($self, $child)=@_;
 return 1
    unless ref($self) and $self->{N} and ref($child) and $child->{N};
 return					# Loop! Don't add dependency
    if $self->{N}==$child->{N}	# ref to self
    or $self->{In}->{$child->{N}};	# ref to [grand]parent
 return 1				# Already dependent
    if exists $self->{On}->{$child->{N}};	

 foreach my $grandson($child, values %{$child->{On}})
 {
  foreach my $granpa($self, values %{$self->{In}})
  {
   next	if exists $granpa->{On}->{$grandson->{N}};
   $granpa->{On}->{$grandson->{N}}=$grandson;
   $grandson->{In}->{$granpa->{N}}=$granpa;
  }
 }

 return 1;				# Ok
}

=back

=head1 BUGS

Methods trimComment(), printComment() and addDependency() are in fact also
used by Section object. They should be moved to common ancestor
of Var and Section. Some day...

=cut

1;
