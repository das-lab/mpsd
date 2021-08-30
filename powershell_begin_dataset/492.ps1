

function Set-EnvironmentVariableValue{



    [CmdletBinding()]
    param(

		[Parameter(Mandatory=$true)]
		[String]
		$Name,
        
		[Parameter(Mandatory=$true)]
		[String]
		$Value, 
         
		[Parameter(Mandatory=$true)]
		[String]
		$Target,  

		[Switch]
		$Add  
	)  
  
    
    
    

    [Environment]::GetEnvironmentVariable($Name,$Target) | %{
                
        if(-not $_.Contains($Value) -and $Add){
            
            Write-Host "Adding value: $Value to variable: $Name"    
            $Value = ("$_" + $Value)        
            [Environment]::SetEnvironmentVariable($Name, $Value, $Target)
            Invoke-Expression "`$env:$Name = `"$Value`""
        
        }elseif(-not $Add){
        
            Write-Host "Set value: $Value on variable: $Name"
            [Environment]::SetEnvironmentVariable($Name,$Value,$Target)
            Invoke-Expression "`$env:$Name = `"$Value`""          
        }
    }     
}       