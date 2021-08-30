

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