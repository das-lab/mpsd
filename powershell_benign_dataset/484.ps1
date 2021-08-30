

function Remove-HostFileEntry{



    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$false)]
		[String]
		$IP,
        
        [Parameter(Mandatory=$false)]
		[String]
		$DNS
	)

    
    
    
    $HostFile = "$env:windir\System32\drivers\etc\hosts"
    
    get-content $HostFile | %{
        if($_.StartsWith("
        
            $Content += $_ + "`n"
            			
        }else{                    

            $HostIP = ([regex]"(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))").match($_).value
            $HostDNS = ($_ -replace $HostIP, "") -replace '\s+',""
            
            if($HostIP -eq $IP -or $HostDNS -eq $DNS){
			
                Write-Host "Remove host file entry: "$(if($IP){$IP + " "}else{})$(if($DNS){$DNS})
                				
            }else{
            
                $Content += $_ + "`n"
            }
        }    
    }	
    
    Set-Content -Path $HostFile -Value $Content
    
    Set-Content -Path $HostFile -Value (Get-Content -Path $HostFile | %{if($_.StartsWith("
}
