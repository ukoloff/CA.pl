print <<EOT;
$0: A bit improved version of OpenSSL CA.pl

Usage: $::CFG{0} job-file

+-Sample job-file--+
|command=newcrt    |
|template=WWW      |
|CN=www.site.com   |
+------------------+
EOT

exit;

1;
