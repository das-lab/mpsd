















[CmdletBinding()]
param(
)

Set-StrictMode -Version Latest
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

if( (Get-Module Silk) )
{
    Remove-Module Silk
}

Import-Module (Join-Path $PSScriptRoot Silk.psd1 -Resolve) -ErrorAction Stop
