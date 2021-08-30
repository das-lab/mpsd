













[CmdletBinding()]
param(

)


Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'

$base64Snk = $env:SNK
if( -not $base64Snk )
{
    return
}

$snkPath = Join-Path -Path $PSScriptRoot -ChildPath 'Source\Carbon.snk'
Write-Verbose -Message ('Saving signing key to "{0}".' -f $snkPath)
[IO.File]::WriteAllBytes($snkPath, [Convert]::FromBase64String($base64Snk))
