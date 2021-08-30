
function Test-CIisAppPool
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $appPool = Get-CIisAppPool -Name $Name
    if( $appPool )
    {
        return $true
    }
    
    return $false
}

Set-Alias -Name 'Test-IisAppPoolExists' -Value 'Test-CIisAppPool'
