
function Get-CServiceSecurityDescriptor
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $sdBytes = [Carbon.Service.ServiceSecurity]::GetServiceSecurityDescriptor($Name)
    New-Object Security.AccessControl.RawSecurityDescriptor $sdBytes,0
}

