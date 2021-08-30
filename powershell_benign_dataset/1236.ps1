











param(
    [Parameter(Mandatory=$true)]
    [string]
    $ProtectedString
)

Set-StrictMode -Version 'Latest'


$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

Add-Type -AssemblyName 'System.Security'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon.psd1' -Resolve)

$string = Unprotect-CString -ProtectedString $ProtectedString
Protect-CString -String $string -ForUser

