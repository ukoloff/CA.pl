<?
$CFG->ops=Array(
'^'=>'Начинается с',
'='=>'Равно',
':'=>'Содержит',
'$'=>'Заканчивается на',
'-'=>'Пусто',
'@'=>'NULL'
);

$CFG->filter=$CFG->sort;
unset($CFG->filter[g]);

switch($CFG->entry->ca=trim($_GET[ca]))
{
 case '': $CFG->entry->ca='*'; break;
 default: $CFG->entry->ca=(int)$CFG->entry->ca;
 case '*':
 case '-':
}

$CFG->q=parseFilter($CFG->params->q=trim($_GET[q]));
buildFilter();

function parseFilter($f)
{
 global $CFG;
 $R=Array();
 $l='';
 while(strlen($f)):
  $Q=preg_split('/([\\\\;])/', $f, 2, PREG_SPLIT_DELIM_CAPTURE);
  $l.=$Q[0]; $f=$Q[2];
  if("\\"!=$Q[1]){ $R[]=$l; $l=''; continue; }
  $l.=$f{0}; 
  $f=substr($f, 1);
 endwhile;
 if(strlen($l))$R[]=$l;
 $F=Array();
 foreach($R as $x):
  $s=$x{0}; $x=substr($x, 1);
  if(!s or !$CFG->filter[$s])continue;
  $not='!'==$x{0}; if($not) $x=substr($x, 1);
  $o=$x{0}; $x=substr($x, 1);
  if(!$CFG->ops[$o]) continue;
  if(preg_match('/[-@]/', $o)) unset($x);
  unset($Y);
  $Y->s=$s;
  $Y->not=$not;
  $Y->o=$o;
  $Y->v=$x;
  $F[]=$Y;
 endforeach;
 return array_reverse($F);
}

function buildFilter()
{
 global $CFG;
 $S='';
 foreach($CFG->q as $z):
  $S.="\nAnd ";
  if($z->not) $S.='Not ';
  $S.=$CFG->filter[$z->s][field];
  $v=SQLite3::escapeString($z->v);
  switch($z->o){
   case '=': $S.="='$v'"; break;
   case '^': $S.=" Like '$v%'"; break;
   case '$': $S.=" Like '%$v'"; break;
   case ':': $S.=" Like '%$v%'"; break;
   case '-': $S.="=''"; break;
   case '@': $S.=" is NULL"; break;
  }
 endforeach;
 switch($CFG->entry->ca)
 {
  case '-': $S.="\nAnd Issuer Not in(Select Distinct x509 From CA)"; break;
  default:  $S.="\nAnd Issuer=(Select x509 From CA Where id={$CFG->entry->ca})";
  case '*':
 }
 $CFG->SQL="\nFrom Certs Left Join Attrs Using(id) Left Join User Using(id) Left Join CA On Issuer=x509".
    preg_replace('/And/i', "Where", $S, 1)."\n".
    sqlOrderBy();
#    strtr(sqlOrderBy(), Array(ctime=>'Certs.ctime', serial=>'Attrs.serial', caId=>'CA.id'));
}

?>
