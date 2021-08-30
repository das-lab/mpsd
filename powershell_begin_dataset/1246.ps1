











[CmdletBinding()]
param(
)


Set-StrictMode -Version 'Latest'

Write-Verbose ('Checking if Carbon module loaded.')
if( -not (Get-Module -Name 'Carbon') )
{
    Write-Verbose ('Loading Carbon module.')
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon.psd1' -Resolve) -Global
}

