function log([System.String] $text){write-host $text;}

function logException{
    log "Logging current exception.";
    log $Error[0].Exception;
}


function mytrycatch ([System.Management.Automation.ScriptBlock] $try,
                    [System.Management.Automation.ScriptBlock] $catch,
                    [System.Management.Automation.ScriptBlock]  $finally = $({})){




    $ErrorActionPreference = "Stop";

    
    trap [System.Exception]{
        
        logException;

        
        & $catch;

        
        & $finally

        
        return $false;
    }

    
    & $try;

    
    & $finally

    
    return $true;
}



cls
mytrycatch {
        gi filethatdoesnotexist; 
        write-host "You won't hit me."
    } {
        Write-Host "Caught the exception";
    }





$Packages = @();
$Packages = Get-Item -Path "C:\Users\MMessano\Documents\Visual Studio 2008\Projects\Data Management\Management\BillingReport\BillingReport\*.dtsx";

foreach ($package in $Packages ) 
{
	$DTSXPackage = Get-ISPackage -path $package
	$DTSXPackage.Name
	foreach ($connection in $DTSXPackage.Connections)
	{
		$connection.Name
		$connection.ConnectionString
	}
}