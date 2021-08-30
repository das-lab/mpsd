
function Assert-CAdminPrivilege
{
    
    [CmdletBinding()]
    param(
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-CAdminPrivilege) )
    {
        Write-Error "You are not currently running with administrative privileges.  Please re-start PowerShell as an administrator (right-click the PowerShell application, and choose ""Run as Administrator"")."
        return $false
    }
    return $true
}

Set-Alias -Name 'Assert-AdminPrivileges' -Value 'Assert-CAdminPrivilege'

