
function Get-CWmiLocalUserAccount
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(0,20)]
        [string]
        
        $Username
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    return Get-WmiObject Win32_UserAccount -Filter "Domain='$($env:ComputerName)' and Name='$Username'"
}

