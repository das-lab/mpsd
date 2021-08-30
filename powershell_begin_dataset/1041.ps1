













[CmdletBinding()]
param(
)

Set-StrictMode -Version 'Latest'
$PSCommandPath = $MyInvocation.MyCommand.Definition
$PSScriptRoot = Split-Path -Parent -Path $PSCommandPath

$os = Get-WmiObject -Class 'Win32_OperatingSystem'


$osVersion = [version]$os.Version
if( $osVersion.Major -eq 6 -and $osVersion.Minor -eq 1 )
{
    Import-Module -Name 'ServerManager'
    Add-WindowsFeature -Name 'PowerShell-ISE','MSMQ-Server','Net-Framework-Core','Web-Server'
}

elseif( $osVersion.Major -eq 6 -and $osVersion.Minor -eq 3 )
{
    Install-WindowsFeature -Name 'Web-Server','MSMQ-Server','Web-Scripting-Tools'
}

choco install 'sysinternals' -y
choco install 'conemu' -y

& (Join-Path -Path $PSScriptRoot -ChildPath '.\Carbon\Import-Carbon.ps1')

Uninstall-IisWebsite -Name 'Default Web Site'


Add-TrustedHost -Entry $env:COMPUTERNAME
