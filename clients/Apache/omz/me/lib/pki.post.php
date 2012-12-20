<?
if(mayGenerate())
 caExec(Array(command=>'new', u=>$CFG->params->u, auth=>1));

Header('Location: ./'.hRef());
exit;
?>
