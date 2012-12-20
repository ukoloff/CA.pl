<?
function caExec($args)
{
 $args=func_get_args();
 while(count($args)):
  $x=array_shift($args);
  if(is_object($x) or is_array($x))
   foreach($x as $k=>$v) $Z[$k]=$v;
  else
   $Z[$x]=array_shift($args);
 endwhile;

 if(array_key_exists('auth',  $Z)):
  unset($Z[auth]);
  $Z[authUser]=base64_encode($_SERVER['PHP_AUTH_USER']);
  $Z[authPass]=base64_encode($_SERVER['PHP_AUTH_PW']);
 endif;

 $x=proc_open("/usr/bin/sudo /home/uxmCA/CA.pl -web", Array(Array('pipe', 'r'), Array('pipe', 'w')),  $pipes);
 foreach($Z as $k=>$v)
  fwrite($pipes[0], "$k=$v\n");
 fclose($pipes[0]);
 $Z=stream_get_contents($pipes[1]);
 fclose($pipes[1]);
 proc_close($x);
 return $Z;
}

function caDB()
{
 return new SQLite3('/home/uxmCA/db/pub/pub.db');
}

?>
