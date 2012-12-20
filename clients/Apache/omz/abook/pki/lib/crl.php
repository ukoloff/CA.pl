<?
if(!$CFG->Auth) return;
if($CFG->db->querySingle("Select datetime('now', '-6 hours')<(Select Value From Ini Where Name='userCRL')")) return;
caExec(Array(command=>'crl', auth=>1));
?>
