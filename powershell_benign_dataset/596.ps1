

function Run-SQLServerAgentJob{



    [CmdletBinding()]
    param(

        [Parameter(Mandatory = $true)]
        [String]
        $JobName,

        [Parameter(Mandatory = $false)]
        [String]
        $Hostname = $env:COMPUTERNAME,

        [Parameter(Mandatory=$false)]
        [ScriptBlock]
		$LogScriptBlock = {Write-Host $Message}
    )
      
    
    
    
	
    
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null

    
    [Microsoft.SqlServer.Management.Smo.Server]$SqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server $HostName

    
    if(-not $SqlServer.Urn){

        throw "The hostname provided is not a valid SQL Server instance. Did you mistype the alias or forget to add the instance name?"
    }

    
    $Job = $SqlServer.JobServer.Jobs | where{ $_.Name -eq $JobName }

    
    if(-not $Job){

        throw "No such job on the server.";
    }

    Write-Host "Executing job: $JobName";
    $Job.Start();
}