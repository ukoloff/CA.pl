print <<EOT;
$0: A bit improved version of OpenSSL CA.pl

Usage: $0 file -c command -t template var=value section::var=value file -t template var=value ...
 -xxx		short for command=xxx
 -c xxx		short for command=xxx
 -t xxx		short for template=xxx

e.g.
#1: $0 -c sign req=user.req template=email
#2: $0 -newcrt -t WWW CN=www.site.com req::default_bits=2048
#3: $0 -selfsigned -t WWW -t subjectAltName CN=me AltName::DNS.1=me AltName::DNS.2=me.domain
or simply:
#1: $0 file#1
#2: $0 file#2
#3: $0 file#3
+-file#1---------+ +-file#2------------+ +-file#3--------------------+
|command=sign    | |command=newcrt     | |command=selfsigned         |
|req=user.req    | |template=WWW       | |template.1=WWW             |
|template=email  | |CN=www.site.com    | |template.2=subjectAltName  |
+----------------+ |[req]              | |CN=me                      |
                   |default_bits=2048  | |[AltName]                  |
                   +-------------------+ |DNS.1=<CN>                 |
                                         |DNS.2=<CN>.domain          |
                                         +---------------------------+
EOT
print "Supported commands: ", join(', ', sort map {$_=basename($_); $_=~s/^.*?\.//; $_=~s/\.[^.]*$//; $_} glob('lib/cmd.*.pl')), "\n";
exit;
1;
