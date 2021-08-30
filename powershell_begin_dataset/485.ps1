

function Remove-EnvironmentVariableValue{



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
		$Clear  
	)  
  
    
    
    

    [Environment]::GetEnvironmentVariable($Name,$Target) | %{
                
        if(($_.Contains($Value) -or (Invoke-Expression "`$env:$Name").contains($Value)) -and -not $Clear){
            
            Write-Host "Remove value: $Value from variable: $Name"            
            $Value = $_.Trim($Value)
            [Environment]::SetEnvironmentVariable($Name, $Value,$Target)
            Invoke-Expression "`$env:$Name = `"$Value`""
        
        }elseif($Clear){
        
            Write-Host "Set value from variable: $Name to `$null"
            [Environment]::SetEnvironmentVariable($Name,$null,$Target)    
            Invoke-Expression "`$env:$Name = `$null"        
        }
    }     
}       