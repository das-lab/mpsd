
function Test-CPrivilege
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Identity,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Privilege
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $matchingPrivilege = Get-CPrivilege -Identity $Identity |
                            Where-Object { $_ -eq $Privilege }
    return ($matchingPrivilege -ne $null)
}

