











param(
    [Parameter(Mandatory=$true)]
    [string]
    
    $ProtectedString
)

Set-StrictMode -Version 'Latest'

Add-Type -AssemblyName 'System.Security'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Carbon.psd1' -Resolve)

Unprotect-CString -ProtectedString $ProtectedString

