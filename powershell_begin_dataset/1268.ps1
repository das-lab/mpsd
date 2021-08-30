
function Get-CIisVersion
{
    
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $props = Get-ItemProperty hklm:\Software\Microsoft\InetStp
    return $props.MajorVersion.ToString() + "." + $props.MinorVersion.ToString()
}

