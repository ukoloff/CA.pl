<?
LoadLib('/uxmCA');

$CFG->pki->db=caDB();

$groupC=$CFG->pki->db->querySingle("Select Value From Ini Where Name='groupC'");

$CFG->pki->Creator=$CFG->params->u? inGroupX($groupC) : 0;	# 1 to allow self-generation
$CFG->pki->u=$CFG->params->u;
if(!$CFG->pki->u)$CFG->pki->u=$CFG->u;

function mayGenerate()
{
 global $CFG;
 if(!$CFG->pki->Creator) return;
 if(!ldap_count_entries($CFG->AD->h,
    ldap_read($CFG->AD->h, user2dn($CFG->pki->u), '(&(mail=*)(userPrincipalName=*)(!(UserAccountControl:1.2.840.113556.1.4.803:=2)))', Array('1.1')))) return;
 return 1;
}

?>
