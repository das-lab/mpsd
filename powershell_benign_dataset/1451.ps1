
function Test-CIdentity
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [Switch]
        
        $PassThru
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $identity = [Carbon.Identity]::FindByName( $Name )
    if( -not $identity )
    {
        return $false
    }

    if( $PassThru )
    {
        return $identity
    }
    return $true
}

