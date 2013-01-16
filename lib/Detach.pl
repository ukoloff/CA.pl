use strict;

if(not -t STDOUT)
{
 open STDOUT, '>', '/dev/null';
 open STDERR, '>', '/dev/null';
}

fork	and $::CFG{keepSandbox}=1, exit;
#setsid;

1;
