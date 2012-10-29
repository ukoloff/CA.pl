package Section;
use strict;

=head1 NAME

Section - template section handling routines

=head1 SYNOPSIS

 $s=Section->new('paths');
 $s->add($v=Var->new('base'));
 $template->add($s);

=head1 DESCRIPTION

Section is a collection of L<Var|Var>'s
and several sections unite in one L<Template|Template>.

In text file Section is represented as
 
 [paths]
 # Section's comment
 base=/var/spool/ca
 tmp=/var/tmp
 name=John\'s
 # Variable's comment

If $section->{Name} is undef, it is a special (main) section. It is always
printed first and without [ Name ] header. Variables in main section are
referred as C<< <var> >>, while in other sections as C<< <section::var> >>.

=head1 METHODS

=over 

=item sub new(Name)

Creates new section object.

=cut

sub new
{
 my ($class, $name)= @_;
 my $self={};
 $self->{Name}=$name;

 bless($self, $class);
 return $self;
}

=item $s->add($v)

Adds variable to a section;

=cut

sub add
{
 my ($self, $var)=@_;
 next	unless exists $var->{Name} and exists $var->{Fragments};
 $self->{lc $var->{Name}}=$var;
}

=item $s->copy()

Creates (almost) exact copy of the section. Comments and other stuff is not copied.

=cut

sub copy
{
 my $self=shift;
 my $z=Section->new($self->{Name});
 while(my($k, $v)=each %$self)
 {
  $z->{$k}=$v->copy	if ref($v)
 }
 return $z;
}

=item $s->dropEmptyVars()

Walks thru section's variables and removes ones that are empty (contains no data).

=cut

sub dropEmptyVars
{
 my $self=shift;
 while(my ($k, $v)=each %$self)
 {
  next	unless ref($v);
  next	unless $v->isEmpty;
  delete $self->{$k};
 }
}

=item $s->print( [file] )

Prints section to a text file.

If section contains (in ->{printOrder}) reference to another section, the latter
is used to set printing order of variables. Other (not mentioned) variables are
printed in alphabet order.

=cut

sub print
{
 my ($self, $fh)=@_;
 $fh=*STDOUT	unless $fh;
 print $fh "[ ", $self->{Name}, " ]\n"	if defined($self->{Name});
 Var::printComment($self, $fh);

 my %printedVars;

 if(ref($self->{printOrder}))
 {
  foreach my $k(sort keys %{$self->{printOrder}})
  {
   $k=$self->{printOrder}->{$k};
   next	unless ref($k);
   $k=lc($k->unEscape);
   my $v=$self->{$k};
   next	unless ref $v;
   $v->print($fh);
   $printedVars{$k}=1;
  }
 }
 delete $self->{printOrder};
 
 foreach my $k(sort keys %$self)
 {
  next	if $printedVars{$k};
  my $v=$self->{$k};
  $v->print($fh)	if ref($v);
 }
}

=item $s->trimComments()

Trims trailing spaces from comments of all variables in section and section itself. 
Called at the end of Template::read(file).

=cut

sub trimComments
{
 my $self=shift;
 Var::trimComment($self);
 foreach my $v(values %$self)
 {
  $v->trimComment	if ref($v);
 }
}

=item $s->addDependency($section)

This method works exactly as Var::addDependency.

See also L<BUGS|/bugs>.

=cut

sub addDependency
{
 return Var::addDependency(@_);
}

=item $s->copyFrom($section)

Copies variables from $section to $s. If some variable is already in $s it is not copied.

=cut

sub copyFrom
{
 my ($self, $src)=@_;
 return	unless ref $src;

 while(my ($k, $v)=each %$src)
 {
  next	unless ref $v;
  next	if ref($self->{$k});
  $self->{$k}=$v->copy;
 }
}

=item $s->fromHash( {var=>'value', var=>'value', ...} )

Adds some variables to a section according to contents of hash reference.

=cut

sub fromHash
{
 my ($self, $hash)=@_;
 return	unless ref $hash;
 while(my ($k, $v)=each %$hash)
 {
  next	if ref $v;
  $self->add($k=Var->new($k));
  $k->addRawStr($v);
 }
}

=item $hash=$s->asHash()

Returns simple (unblessed) hash reference with {param=>'value', param=>'value'... }
pairs from the section.

=cut

sub asHash
{
 my $self=shift;
 my $r={};
 while(my ($k, $v)=each %$self)
 {
  next	unless ref $v;
  $r->{$k}=$v->unEscape;
 }
 return $r;
}

=back

=head1 BUGS

Section object also uses some methods of L<Var|Var/bugs>.

=cut

1;
