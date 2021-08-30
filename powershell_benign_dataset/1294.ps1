
function Assert-CService
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-CService $Name) )
    {
        Write-Error ('Service {0} not found.' -f $Name)
        return $false
    }
    
    return $true
}

