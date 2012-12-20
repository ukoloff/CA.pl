<Script><!--
function saveAs(z)
{
 z.blur();
 if(!z.value.length) return;
 var x=z.value;
 z.value='';
 location.search+='&as='+x;
}

function addFilter()
{
 var d=document.createElement('div');
 findId('Filters').appendChild(d);
 d.innerHTML=findId('emptyFilter').innerHTML;
}

function removeFilter(A)
{
 var d=A.parentNode;
 var z=d.parentNode;
 z.removeChild(d);
}

function buildFilter(f)
{
 var z=findId('Filters');
 var S='';
 for(var i=z.children.length-1; i>=0; i--)
 {
  var x=z.children[i];
  var a=x.getElementsByTagName('select'), b=x.getElementsByTagName('input');
  if(!a[0].value) continue;
  if(S.length)S+=';';
  S+=a[0].value;
  if(b[0].checked)S+='!';
  S+=a[1].value;
  if(/^[-@]$/.test(a[1].value)) continue;
  S+=b[1].value.replace(/[\\;]/g, '\\$&');
 }
// if(!S.length) return false;
 f.q.value=S;
}

//--></Script>
<?
LoadLib('/forms');
$s=$CFG->db->prepare("Select * From CA");
$x=$s->execute();
while($r=$x->fetchArray(SQLITE3_ASSOC))
  $CA[]=$r;
foreach($CA as $z)
  $caList[$z[id]]=$z[CN];

$s=$CFG->db->prepare("Select Count(*) From Certs Where Issuer Not in(Select Distinct x509 From CA)")->execute()->fetchArray(SQLITE3_NUM);
if($s[0])$caList['-']='Не в CA';

if(count($caList)>1) $caList['*']='Все сертификаты';

$CFG->defaults->Input->BR='';
?>
<Form Action='./' Method='GET' onSubmit='return buildFilter(this)'>
<Select Style='position: absolute; top: 0;' onChange='saveAs(this);'>
<Option Value=''>Сохранить как...
<Option Value='csv'>CSV
<Option Value='xls'>Excel
<Option Value='json'>JSON
<Option Value='yaml'>YAML
</Select>
<Div id='Filters'>
<?
foreach($CFG->q as $q) aFilterLine($q);
?>
</Div>
<A hRef='#' onClick='addFilter(); return false' title='Добавить условие фильтрации'>+</A>
<?
$CFG->defaults->q='!'.$CFG->params->q;
hiddenInputs();
unset($CFG->defaults->q);
Select('ca', $caList, 'CA: ');
?>
<Input Type='Submit' Value='Применить фильтр' x-Style='position: absolute; right: 0;'/>
</Form>
<?
aFilterLine(); 

function aFilterLine($q=null)
{
 global $CFG;
?>
<Div<? if(!$q) echo " id='emptyFilter'";?>>
<A hRef='#' onClick='removeFilter(this); return false;' title='Удалить условие фильтрации'>-</A>
<Select>
<Option Value=''>Поле...
<?
foreach($CFG->filter as $k=>$v)
 if($k)
    echo '<Option Value="', htmlspecialchars($k), '"', $k==$q->s? ' Selected':'', '>', htmlspecialchars($v[name]), "\n";
?>
</Select>
<Label><Input Type='Checkbox' <?if($q->not)echo "Checked ";?>/>
не
</Label>
<Select>
<?
foreach($CFG->ops as $k=>$v)
 if($k)
    echo '<Option Value="', htmlspecialchars($k), '"', $k==$q->o? 'Selected':'', '>', htmlspecialchars($v), "\n";
?>
</Select>
<Input Value="<?=htmlspecialchars($q->v)?>">

</Div><?
}
?>