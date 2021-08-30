
function Test-CGroup
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $group = Get-CGroup -Name $Name -ErrorAction Ignore
    if( $group )
    {
        $group.Dispose()
        return $true
    }
    else
    {
        return $false
    }
}

