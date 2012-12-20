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
