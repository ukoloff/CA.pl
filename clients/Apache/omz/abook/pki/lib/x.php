<?
LoadLib('/tabs');
$CFG->tabs=Array(''=>'#', info=>'Сертификат', txt=>'txt', crt=>'crt');
if($CFG->Super='stas'==$CFG->u)
  $CFG->tabs+=Array(pem=>'pem');

$CFG->onLoadLib['body']='tabsBody';
tabsInit();
if(!$CFG->params->x)$CFG->params->x='info';

?>
