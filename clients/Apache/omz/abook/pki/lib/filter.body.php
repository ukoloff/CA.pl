<Script Src='filter.js'></Script>
<?
LoadLib('/forms');
$s=$CFG->db->prepare("Select * From CA");
$x=$s->execute();
while($r=$x->fetchArray(SQLITE3_ASSOC))
  $CA[]=$r;
foreach($CA as $z)
  $caList[$z[id]]=$z[CN];

$s=$CFG->db->prepare("Select Count(*) From Certs Where Issuer Not in(Select Distinct x509 From CA)")->execute()->fetchArray(SQLITE3_NUM);
if($s[0])$caList['-']='�� � CA';

if(count($caList)>1) $caList['*']='��� �����������';

$CFG->defaults->Input->BR='';
?>
<Form Action='./' Method='GET' onSubmit='return buildFilter(this)'>
<Select Style='position: absolute; top: 0;' onChange='saveAs(this);'>
<Option Value=''>��������� ���...
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
<A hRef='#' onClick='addFilter(); return false' title='�������� ������� ����������'>+</A>
<?
$CFG->defaults->q='!'.$CFG->params->q;
hiddenInputs();
unset($CFG->defaults->q);
Select('ca', $caList, 'CA: ');
?>
<Input Type='Submit' Value='��������� ������' x-Style='position: absolute; right: 0;'/>
</Form>
<?
aFilterLine(); 

function aFilterLine($q=null)
{
 global $CFG;
?>
<Div<? if(!$q) echo " id='emptyFilter'";?>>
<A hRef='#' onClick='removeFilter(this); return false;' title='������� ������� ����������'>-</A>
<Select>
<Option Value=''>����...
<?
foreach($CFG->filter as $k=>$v)
 if($k)
    echo '<Option Value="', htmlspecialchars($k), '"', $k==$q->s? ' Selected':'', '>', htmlspecialchars($v[name]), "\n";
?>
</Select>
<Label><Input Type='Checkbox' <?if($q->not)echo "Checked ";?>/>
��
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