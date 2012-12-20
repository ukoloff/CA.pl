use strict;

if(not -t STDOUT)
{
 open STDOUT, '>', '/dev/null';
 open STDERR, '>', '/dev/null';
}

fork	and exit;
#setsid;

1;
