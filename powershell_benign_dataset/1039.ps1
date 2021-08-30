











[CmdletBinding()]
param(
)


Set-StrictMode -Version Latest

& (Join-Path $PSScriptRoot ..\Import-Carbon.ps1 -Resolve)

$ccservicePath = 'Path\to\ccservice.exe'
$ccserviceUser = 'example.com\CCServiceUser'
$ccservicePassword = 'CCServiceUserPassword'
Install-Service -Name CCService -Path $ccservicePath -Username $ccserviceUser -Password $ccservicePassword

$pathToVersionControlRepository = 'Path\to\version\control\repository'
$pathToBuildOutput = 'Path\to\build\output'
Grant-Permission -Identity $ccserviceUser -Permission FullControl -Path $pathToVersionControlRepository
Grant-Permission -Identity $ccserviceUser -Permission FullControl -Path $pathToBuildOutput
