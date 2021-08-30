

function Get-HostFileEntries{




    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$false)]
		[String]
		$Filter
	)
    
    
    
    
    function New-ObjectHostFileEntry{
        param(
            [string]$IP,
            [string]$DNS
        )
        New-Object PSObject -Property @{
            IP = $IP
            DNS = $DNS
        }
    }
    
    
    
    

    $Entries = $(get-content "$env:windir\System32\drivers\etc\hosts") | %{
    
        if(!$_.StartsWith("

            $IP = ([regex]"(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))").match($_).value
            $DNS = ($_ -replace $IP, "") -replace  '\s+',""
            
            if($Filter -and (($IP -match $Filter) -or ($DNS -match $Filter))){
                
                New-ObjectHostFileEntry -IP $IP -DNS $DNS
                
            }elseif($Filter -eq ""){
            
                New-ObjectHostFileEntry -IP $IP -DNS $DNS
            }
        }  
    } 
    
    if($Entries -ne $Null){                
        $Entries      
    }else{
        Write-Error "No entries found in host file"
    }
}