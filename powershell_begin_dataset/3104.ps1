param(
    [string]$buildCorePowershellUrl = "https://opbuildstorageprod.blob.core.windows.net/opps1container/.openpublishing.buildcore.ps1",
    [string]$parameters
)

$errorActionPreference = 'Stop'


echo "download build core script to local with source url: $buildCorePowershellUrl"
$repositoryRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$buildCorePowershellDestination = "$repositoryRoot\.openpublishing.buildcore.ps1"
Invoke-WebRequest $buildCorePowershellUrl -OutFile $buildCorePowershellDestination


echo "run build core script with parameters: $parameters"
$arguments = "-parameters:'$parameters'"
Invoke-Expression "$buildCorePowershellDestination $arguments"
exit $LASTEXITCODE