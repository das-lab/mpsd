
function Get-CPrivilege
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Identity
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    [Carbon.Security.Privilege]::GetPrivileges( $Identity )
}

Set-Alias -Name 'Get-Privileges' -Value 'Get-CPrivilege'

