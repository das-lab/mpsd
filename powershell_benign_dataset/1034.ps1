














Set-StrictMode -Version Latest

& (Join-Path $PSScriptRoot Carbon\Import-Carbon.ps1 -Resolve)

$websitePath = Join-Path $PSScriptRoot Website -Resolve
Install-IisWebsite -Name 'get-carbon.org' -Path $websitePath -Bindings 'http/*:80:'
Grant-Permission -Identity Everyone -Permission ReadAndExecute -Path $websitePath
