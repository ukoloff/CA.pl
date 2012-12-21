<?#X509 Test?>
<?
if(!$_SERVER[HTTPS]):?>
��� ������ ���� �������� ��������� <A hRef="/omz<?=htmlspecialchars($_SERVER[REQUEST_URI])?>">HTTPS</A>.
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
<H2>���������� ����������</H2>
<Table Border Width='100%' CellSpacing='0'>
<ColGroup Align='Right'>
<TR><TH>�</TH><TD><?=htmlspecialchars($_SERVER[SSL_CLIENT_M_SERIAL])?><BR /></TD></TR>
<TR><TH>DN</TH><TD><?=htmlspecialchars($_SERVER[SSL_CLIENT_S_DN])?><BR /></TD></TR>
<TR><TH>u</TH><TD><?=htmlspecialchars($r[u])?><? if($r[id]) echo "\n<A hRef='/omz/abook/pki/?x&n={$r[id]}'>&raquo;</A>";?><BR /></TD></TR>
</Table>
<H2>NB</H2>
&raquo;
�������� ����� ����� ������ � ���������, ������������ ��������� ������ Windows, �� ���� � Microsoft Internet Explorer
� Google Chrome
(<?=preg_match('/Windows/i', $_SERVER[HTTP_USER_AGENT])&&preg_match('/MSIE|AppleWebKit/i', $_SERVER[HTTP_USER_AGENT])?'�, �������, ':'��, ������, ��'?>
 � �����). � ��������� Opera � Firefox ���� �� �����.
<? if(preg_match('/Windows/i', $_SERVER[HTTP_USER_AGENT])): ?>
<BR />
&raquo;
�� ������ <A hRef='../x509test.js'>������� ��� ��������</A>
� Microsoft Internet Explorer, ����� �������, ���������� �� ���������� � ��������� Windows
<? endif; ?>
<!--[if IE ]>
<BR />
&raquo;
����� ��������� ������� �����������, � ��������� �������� �� ������� "����������" ������� ������ "�������� SSL" � �������� ��������.
��� <A hRef='#' onClick='clearSSL()'>������� ����</A>.
<Script><!-- // http://unmitigatedrisk.com/?p=13
function clearSSL()
{
 document.execCommand('ClearAuthenticationCache', false);
 location.reload();
}
//--></Script>
<![endif]-->
