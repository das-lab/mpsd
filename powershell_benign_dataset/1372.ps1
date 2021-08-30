
function Get-CIisAppPool
{
    
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.ApplicationPool])]
    param(
        [string]
        
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $mgr = New-Object Microsoft.Web.Administration.ServerManager
    $mgr.ApplicationPools |
        Where-Object { 
            if( -not $PSBoundParameters.ContainsKey('Name') )
            {
                return $true
            }
            return $_.Name -eq $Name 
        } |
        Add-IisServerManagerMember -ServerManager $mgr -PassThru
}

