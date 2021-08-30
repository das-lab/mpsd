
function Test-CService
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $service = Get-Service -Name $Name -ErrorAction Ignore 
    if( $service )
    {
        return $true
    }
    else
    {
        return $false
    }
}
