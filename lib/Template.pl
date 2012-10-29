package Template;
use strict;

use 5.006;

=head1 NAME

Template - template handling routines

=head1 SYNOPSIS

 $t=Template->new;
 open($fh, 'test.conf');
 $t->read($fh);
 close($fh);
 $t->print;

=head1 DESCRIPTION

Templates are used for:

=over

=item *
Storing configuration of CA

=item *
Control of CA operation

=item *
Generation of OpenSSL.conf files

=back

Templates consist of [C<sections>] and sections of C<var=value> pairs. One var can
refer to another using C<< a=<[section::]b> >> syntax. One section can
import variables from another with C< copySection=name > syntax. Templates can inherit
their content with C< template=name > and C< file=filename > syntax.

=head1 METHODS

=over

=cut

::Lib('Section');
::Lib('Var');

=item sub new()

Creates new (empty) Template

 $t=Template->new;

=cut

sub new
{
 my $class = shift;
 my $self={};

 bless($self, $class);
 $self->add(Section->new());

 return $self;
}

=item $t->add($section)

Add new section to template. If $section->{Name} is undef, it becomes 'Main' (first) section

=cut

sub add
{
 my ($self, $section)=@_;
 return	unless exists $section->{Name};
 $self->{defined($section->{Name})? lc($section->{Name}) : 'Main'}=$section;
}

=item $copy=$t->copy()

Create new template, almost equal to the former. Comments and other stuff are not copied.

=cut

sub copy
{
 my $self=shift;
 my $z=Template->new;
 while(my($k, $v)=each %$self)
 {
  $z->{$k}=$v->copy	if ref($v)
 }
 return $z;
}

=item $x=$t->valueOf( ['section', ] 'var')

Get the value of the single variable. If section is omitted, main section is used

For non existing variables return undef. For existing - string (possibly empty).

=cut

sub valueOf
{
 my $self=shift;
 my $v=$self->{scalar(@_)>1? lc(shift) : 'Main'};
 return	unless ref $v;
 $v=$v->{lc shift};
 return	unless ref $v;
 return $v->unEscape;
}

=item $t->fileName()

Return value of file C<file=...> variable or undef

=cut

sub fileName
{
 my $self=shift;
 my $t=$self->copy;
 $t->expand;
 return $t->valueOf('file');
}

=item $t->templateNames()

Returns array (may be empty) with all values of C<template.n=...>

=cut

sub templateNames
{
 my $self=shift;
 my $t=$self->copy;
 my @T;
 $t->expand;
 while(my ($k, $v)=each %{$t->{Main}})
 {
  next unless $k=~/^template(\.\d+)?$/;
  push @T, $v->unEscape;
 }
 return @T;
}

=item $hash=$t->asHash()

Returns template contents as pure simple (not blessed) hash reference.

=cut

sub asHash
{
 my $self=shift;
 my $r=$self->{Main}->asHash;
 foreach my $s(values %$self)
 {
  next	unless ref $s;
  next	unless defined $s->{Name};
  $r->{lc $s->{Name}}=$s->asHash;
 }
 return $r;
}

=item $t->fromHash( {var=>'value', section=>{var=>'value'... }... } )

Creates sections and variables from keys and values of the hash reference.

=cut

sub fromHash
{
 my ($self, $hash)=@_;
 return	unless	ref $hash;
 $self->{Main}->fromHash($hash);
 while(my ($k, $v)=each %$hash)
 {
  next	unless ref $v;
  $self->add($k=Section->new($k));
  $k->fromHash($v);
 }
}

=item $t->dropEmptyVars()

Walks thru template and kills all variables that are empty

=cut

sub dropEmptyVars
{
 my $self=shift;
 while(my ($k, $s)=each %$self)
 {
  next	unless ref $s;
  $s->dropEmptyVars;
 }
}

=item $t->prepend($template)

Copies sections and variables from $template to $t.
Section and variables of $t stay intact, only new ones are copied.

=cut

sub prepend
{
 my ($self, $t)=@_;
 return	unless ref $t;
 while(my ($k, $s)=each %$t)
 {
  next	unless ref($s);
  if(exists $self->{$k})
  {
   $self->{$k}->copyFrom($s);
  }
  else
  {
   $self->add($s->copy);
  }
 }
}

=item $t->print( [$file] )

Prints template to a file. 

If template contains [.printOrder] and [.printOrder.<section>] sections,
they define the order of printing. Sections and variables not listed in
[.printOrder*] sections are printed in alphabet order.

=cut

sub print
{
 my ($self, $fh)=@_;
 $fh=*STDOUT	unless $fh;

 my %Done=();
 my $ps=sub
 {
  my $n=shift;
  return	if $Done{$n};
  my $s=$self->{$n};
  return	unless ref $s;
  $Done{$n}=1;
  $s->{printOrder}=$self->{".printorder.".$n};
  $s->print($fh);
 };

 $ps->('Main');
 my $s=$self->{'.printorder'};
 if(ref $s)
 {
  $s=$s->asHash;
  foreach my $k(sort keys %$s)
  {
   $ps->(lc($s->{$k}));
  }
 }
 foreach my $s(sort keys %$self)
 {
  $ps->($s);
 }
}

=item $t->read( [$file] )

Reads template contents from textfile until EOF

=cut

sub read
{
 my ($self, $fh)=@_;
 $fh=*STDIN	unless $fh;
 my $Section=$self->{Main};
 my $commentTo=\$Section->{Comment};
 my $Var;

 while(my $s=<$fh>)
 {
  $s=~s/^\s+//;
  if(!length($s))
  {			# Empty line -> comment
   $$commentTo.="\n";
   next;
  }
  if($s=~s/^#//)
  {			# Comment
   $s=~s/\s+$//;
   $$commentTo.="$s\n";
   next;
  }
  if($s=~s/^\[\s*//)
  {			# [ Section ]
   $s=~s/\].*//s;
   $s=~s/\s*$//;
   $self->add($Section=Section->new($s));
   $commentTo=\$Section->{Comment};
   next;
  }
  my $v;
  if($s=~s/^(.*?)([#=])//)
  {
   $v=$1;
   if('#' eq $2)
   {
    $s='#'.$s;
   }
   else
   {
    $s=~s/^\s+//;
   }
  }
  else
  {
   $v=$s;
   $s='';
  }
# Start of var=...
  $v=~s/\s+$//;
  $Section->add($Var=Var->new($v));
  $commentTo=\$Var->{Comment};

  my $f='';
  my $q=undef;
  while(length($s))
  {
   my $qq=($q or "\"'#<");
   $s=~s/^(.*?)([$qq\\])//	or last;
   if('#' eq $2)
   {			# Comment
    my $pre=$1;
    $pre=~s/\s+$//;
    $Var->add($f.$pre);
    $f='';
    $s=~s/\s+$//;
    $$commentTo.=$s;
    $s='';
    last;
   }
   $f.=$1;
   if('<' eq $2)
   {			# <section::var>
    $Var->add($f);
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
    $var=~s/^\s+//; $var=~s/\s+$//;
    my $section=undef;
    if($var=~s/^(.*)::\s*//)
    {
     $section=$1;
     $section=~s/\s+$//;
    }
    $Var->addVar($section, $var);
    next;
   }
   if("\\" eq $2)
   {			# \?
    if($s=~/^\r?\n?\z/)
    {			# \<End-Of-Line>
     $f.="\\\n";
     $s=<$fh>;
     next;
    }
    $s=~s/^(.)//s;
    $f.="\\".$1;
    next;
   }
   $f.=$2;
   $q=$q? undef : $2;
  }	# while(length($s))...
  $s=~s/\s+$//;
  $Var->add($f.$s.$q);
 }
 $self->trimComments;
}

=item $t->trimComments()

Used internally by $t->read() to trim trailing spaces from all comments

=cut

sub trimComments
{
 my $self=shift;
 foreach my $s(values %$self)
 {
  $s->trimComments	if ref $s;
 }
}

=item $t->markVarsToExpand()

Used internally by $t->expandVars(). Performs environment expansion C<< (<ENV::HOME>->$HOME) >>
and marks variables that are real variables (not just static strings).

=cut

sub markVarsToExpand
{
 my $self=shift;
 my $N=0;
 foreach my $s(values %$self)
 {
  next	unless ref($s);
  foreach my $v(values %$s)
  {
   next unless ref($v);
   delete $v->{N};
   delete $v->{Seen};
   delete $v->{In};
   delete $v->{On};
   $v->expandEnv;
   next unless $v->dependsOn;
   $v->{N}=++$N;
   $v->{In}={};		# Vars depend on $v
   $v->{On}={};		# Vars $v depends upon
  }
 }
}

=item $t->expandVars()

Performs variable expansion, that is replaces all variables with their value.

Detects loops C<< (a=<b>; b=<a>) >> and breaks them in some (arbitrary) position.

=cut

sub expandVars
{
 my $self=shift;

 $self->markVarsToExpand();
 foreach my $s(values %$self)
 {
  next	unless ref($s);
  foreach my $v(values %$s)
  {
   next	unless ref($v);
   next	unless $v->{N};
   my @Fragments=();
   foreach my $f(@{$v->{Fragments}})
   {
    if(!$f->isVar)
    {
     push @Fragments, $f;
     next;
    }
    my $child=$f->pointsTo($self);
    next	unless $child;
    if($v->addDependency($child))
    {
     push @Fragments, $f;
     next;
    }
# this dependency leads to loop; break it
#    push @Fragments, $self->{brokenLink}	if $self->{brokenLink};
   }	# foreach my $f...
   $v->{Seen}=1;
   $v->{Fragments}=\@Fragments;
   $self->earlyExpandVars($v)	unless scalar %{$v->{On}};
  }	# foreach my $v...
 }
# At this point all Vars must be expanded (early), but I cannot prove this, so...
 foreach my $s(values %$self)
 {
  next	unless ref($s);
  foreach my $v(values %$s)
  {
   next	unless ref $v;
   next	unless $v->{N};
   $self->expand1Var($v);
  }
 }
}

=item $t->earlyExpandVars($var, $var...)

Used internally by $t->expandVars(). 
Expand only these vars, provided they are ready to expand.

=cut

sub earlyExpandVars
{	# used internally by expandVars
 my @List=@_;
 my $self=shift @List;
 while(my $v=pop @List)
 {
  next	unless $v->{Seen} and !scalar(%{$v->{On}});

  while(my($N, $granpa)=each %{$v->{In}})
  {	# delete $granpa's dependency on $v
   delete $v->{In}->{$N};
   delete $granpa->{On}->{$v->{N}};
   push @List, $granpa	if $granpa->{Seen} and !scalar(%{$granpa->{On}});
  }
  $self->expand1Var($v);
 }
}

=item $t=expand1Var($var)

Used internally by $t->expandVars(). 
Expand variable and all variables it uses.

=cut

sub expand1Var
{
 my ($self, $v)=@_;
 return	unless ref($v);
 return unless $v->{N};

 delete $v->{N};
 delete $v->{Seen};
 delete $v->{In};
 delete $v->{On};

 my @Fragments=();
 foreach my $f(@{$v->{Fragments}})
 {
  if(!$f->isVar)
  {
   push @Fragments, $f;
   next;
  }
  my $child=$f->pointsTo($self);
  next	unless $child;
  $self->expand1Var($child);
  push @Fragments, @{$child->{Fragments}};
 }
 $v->{Fragments}=\@Fragments;
}

=item $t->markSectionsToCopy()

Used internally by $t->copySections().
For all sections find their copySection.n=? variables and marks sections
that need to borrow from others.

=cut

sub markSectionsToCopy
{
 my $self=shift;
 my $N=0;
 foreach my $s(values %$self)
 {
  next	unless ref($s);
  delete $s->{Seen};
  delete $s->{N};
  delete $s->{In};
  delete $s->{On};
  delete $s->{copyFrom};
  my @Src;
  while(my($k, $v)=each %$s)
  {
   next	unless $k=~/^copysection(\.\d+)?$/;
   delete $s->{$k};
   my $ref=$self->{lc($v->unEscape)};
   push @Src, $ref	if ref($ref);
  }
  next	unless scalar @Src;
  $s->{copyFrom}=\@Src;
  $s->{N}=++$N;
  $s->{In}={};		# Sections that include $s
  $s->{On}={};		# Sections included in $s
 }
}

=item $t->copySections()

Perform section expansion (Section copying). 
Copy variables from one section to another according to copySection.n=...

Detects loops C<< (a::copySection=b; b::copySection=a) >> and breaks them.

=cut

sub copySections
{
 my $self=shift;
 $self->markSectionsToCopy;

 foreach my $s(values %$self)
 {
  next	unless ref $s;
  next	unless $s->{N};
  my @Src;
  foreach my $z(@{$s->{copyFrom}})
  {
   push @Src, $z	if($s->addDependency($z));
  }
  $s->{Seen}=1;
  $s->{copyFrom}=\@Src;
  $self->earlyCopySections	unless scalar %{$s->{On}};
 }
# Again, here all sections must be already [early] copied, but I'd better check
 foreach my $s(values %$self)
 {
  next	unless ref $s;
  next	unless $s->{N};
  $self->copy1Section($s);
 }
}

=item $t->earlyCopySections($section, $section...)

Used internally by $t->copySections().
Copy content to specified sections, provided they are ready.

=cut

sub earlyCopySections
{
 my @List=@_;
 my $self=shift @List;
 while(my $s=pop @List)
 {
  next	unless $s->{Seen} and !scalar(%{$s->{On}});
  while(my($N, $granpa)=each %{$s->{In}})
  {	# delete $granpa's dependency on $s
   delete $s->{In}->{$N};
   delete $granpa->{On}->{$s->{N}};
   push @List, $granpa	if $granpa->{Seen} and !scalar(%{$granpa->{On}});
  }
  $self->copy1Section($s);
 }
}

=item $t->copy1Section($section)

Used internally by $t->copySections().
Copy content to specified section, and recursively to all sections it depends on.

=cut

sub copy1Section
{
 my ($self, $s)=@_;
 return	unless ref($s);
 return unless $s->{N};

 my $Src=$s->{copyFrom};

 delete $s->{N};
 delete $s->{Seen};
 delete $s->{In};
 delete $s->{On};
 delete $s->{copyFrom};
 foreach my $z(@$Src)
 {
  $self->copy1Section($z);
  $s->copyFrom($z);
 }
}

=item $t->expand()

Perform full expand on template: variable expansion + section copying.

=cut

sub expand
{
 my $self=shift;
 $self->expandVars;
 $self->copySections;
}

=back

That's all folks

=cut

1;
