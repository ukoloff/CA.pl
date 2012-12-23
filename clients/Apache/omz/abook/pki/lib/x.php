<?
LoadLib('/tabs');
$CFG->tabs=Array(''=>'#', info=>'Сертификат', txt=>'txt', crt=>'crt');

$groupR=$CFG->db->querySingle("Select Value From Ini Where Name='groupR'");

if($CFG->Super=inGroupX($groupR))
  $CFG->tabs+=Array(pem=>'pem');

$CFG->onLoadLib['body']='tabsBody';
tabsInit();
if(!$CFG->params->x)$CFG->params->x='info';

?>
