use strict;

use Digest::SHA1  qw(sha1_hex);

my $p="$::CFG{root}/tmp";
-d $p	or mkdir $p;
chmod 0700, $p;
$p.='/';

while(1)
{
 my $fh;
 open $fh, '<', '/dev/urandom';
 my $q;
 sysread $fh, $q, 4;
 close $fh;
 $q=$p.substr(sha1_hex($q), -12).$$;
 -d $q	and next;
 mkdir $q;
 chmod 0700, $q;
 $::CFG{tmp}="$q/";
 last;
}

sub resolveFile
{
 my $n=shift;
 return $::CFG{$n=~/^\// ?'root':'tmp'}.$n;
}

sub readFile
{
 open F, '<', resolveFile($_[0]);
 my $r=join('', <F>);
 close F;
 return $r;
}

sub writeFile
{
 open F, '>', resolveFile($_[0]);
 print F $_[1];
 close F;
}

END{
 unlink	while glob "$::CFG{tmp}*";
 rmdir $::CFG{tmp};
}

1;
