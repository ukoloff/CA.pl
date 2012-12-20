<?
$n=(int)trim($_GET['n']);
if($n<=0) return LoadLib('list');

$s=$CFG->db->prepare('Select Certs.id, subj, u From Certs Left Join Attrs Using(id) Left Join User Using(id) Where Certs.id=:n');
$s->bindValue(':n', $n);
$r=$s->execute()->fetchArray(SQLITE3_ASSOC);
if(!$r):
 Header('HTTP/1.0 404');
 exit;
endif;

$CFG->params->n=$n;
if(isset($_GET[x]))return LoadLib('x');

$u=$r[u];
if(!$u):
 foreach(array_reverse(split('/', $r[subj]))as $x):
  $x=split('=', $x, 2);
  $x=$x[1];
  if(!strlen($x) or preg_match('/@/', $x)) continue;
  $u=$x;
  break;
 endforeach;
endif;
if(!$u)$u='x509';
$CFG->fileName=$u;

$as=preg_replace('/\W/', '', $_GET['as']);
LoadLib('as.'.(file_exists(dirname(__FILE__).'/as.'.$as.'.php')? $as : 'crt'));
exit;
?>
