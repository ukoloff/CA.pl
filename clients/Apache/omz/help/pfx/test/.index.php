<?#X509 Test?>
<?
if(!$_SERVER[HTTPS]):?>
Для работы этой страницы требуется <A hRef="/omz<?=htmlspecialchars($_SERVER[REQUEST_URI])?>">HTTPS</A>.
<Script><!--
location='/omz<?=$_SERVER[REQUEST_URI]?>';
//--></Script>
<?
exit;
endif;

if(function_exists('LoadLib'))LoadLib('/uxmCA');

$db=caDB();
$s=$db->prepare(<<<SQL
Select Certs.id, User.u
From Certs, Attrs A, User, Attrs IA
Where
 Certs.id=A.id And Certs.id=User.id
 And Certs.Issuer=IA.id
 And A.serial=:sn
 And A.subj=:dn
 And IA.subj=:idn
SQL
);
$s->bindValue(':sn', $_SERVER[SSL_CLIENT_M_SERIAL]);
$s->bindValue(':dn', $_SERVER[SSL_CLIENT_S_DN]);
$s->bindValue(':idn', $_SERVER[SSL_CLIENT_I_DN]);
$r=$s->execute()->fetchArray(SQLITE3_ASSOC);

?>
<H2>Предъявлен сертификат</H2>
<Table Border Width='100%' CellSpacing='0'>
<ColGroup Align='Right'>
<TR><TH>№</TH><TD><?=htmlspecialchars($_SERVER[SSL_CLIENT_M_SERIAL])?><BR /></TD></TR>
<TR><TH>DN</TH><TD><?=htmlspecialchars($_SERVER[SSL_CLIENT_S_DN])?><BR /></TD></TR>
<TR><TH>u</TH><TD><?=htmlspecialchars($r[u])?><? if($r[id]) echo "\n<A hRef='/omz/abook/pki/?x&n={$r[id]}'>&raquo;</A>";?><BR /></TD></TR>
</Table>
<H2>NB</H2>
&raquo;
Проверка имеет смысл только в браузерах, использующих хранилище ключей Windows, то есть в Microsoft Internet Explorer
и Google Chrome
(<?=preg_match('/Windows/i', $_SERVER[HTTP_USER_AGENT])&&preg_match('/MSIE|AppleWebKit/i', $_SERVER[HTTP_USER_AGENT])?'и, кажется, ':'но, похоже, не'?>
 в Вашем). В браузерах Opera и Firefox ключ не виден.
<? if(preg_match('/Windows/i', $_SERVER[HTTP_USER_AGENT])): ?>
<BR />
&raquo;
Вы можете <A hRef='../x509test.js'>открыть эту страницу</A>
в Microsoft Internet Explorer, чтобы увидеть, установлен ли сертификат в хранилище Windows
<? endif; ?>
<!--[if IE ]>
<BR />
&raquo;
Чтобы повторить попытку авторизации, в свойствах Интернет на вкладке "Содержание" нажмите кнопку "Очистить SSL" и обновите страницу.
Или <A hRef='#' onClick='clearSSL()'>нажмите сюда</A>.
<Script><!-- // http://unmitigatedrisk.com/?p=13
function clearSSL()
{
 document.execCommand('ClearAuthenticationCache', false);
 location.reload();
}
//--></Script>
<![endif]-->
