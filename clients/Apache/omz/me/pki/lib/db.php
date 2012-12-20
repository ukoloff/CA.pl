<?
$CFG->IP="'".AddSlashes($_SERVER[REMOTE_ADDR])."'";

$CFG->h=new SQLite3(dirname(__FILE__).'/data/db.sq3');
$CFG->h->exec(file_get_contents(dirname(__FILE__).'/db.sql'));
?>
