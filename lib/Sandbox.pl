use strict;

use Digest::SHA1  qw(sha1_hex);
use MIME::Base64;
use Time::HiRes;

my $p="$::CFG{root}/tmp";
-d $p	or mkdir $p;
chmod 0700, $p;
$p.='/';

while(1)
{
 my  $q=$p.substr(randomHash64(), -12).$$;
 -d $q	and next;
 mkdir $q;
 chmod 0700, $q;
 $::CFG{tmp}="$q/";
 last;
}

sub randomHash
{
 my $fh;
 open $fh, '<', '/dev/urandom';
 my $q;
 sysread $fh, $q, 4;
 close $fh;
 return sha1_hex($q.Time::HiRes::gettimeofday);
}

sub randomHash64
{
 my $r=encode_base64(pack('H*', randomHash()));
 $r=~s/\W//g;
 return $r;
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
 return	if $::CFG{keepSandbox};
 unlink	while glob "$::CFG{tmp}*";
 rmdir $::CFG{tmp};
}

1;
