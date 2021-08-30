













param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string] $buildConfig
)

$VerbosePreference = 'Continue'

if ([string]::IsNullOrEmpty($buildConfig))
{
	Write-Verbose "Setting build configuration to 'Release'"
	$buildConfig = 'Release'
}

if($env:AzurePSRoot -eq $null)
{
    $env:AzurePSRoot="$PSScriptRoot\..\..\"
}

Write-Host $env:AzurePSRoot

Write-Verbose "Build configuration is set to $buildConfig"

$output = Join-Path $env:AzurePSRoot "artifacts\$buildConfig"
Write-Verbose "The output folder is set to $output"
$serviceManagementPath = Join-Path $output "ServiceManagement\Azure"
$resourceManagerPath = $output

Write-Verbose "Removing unneeded psd1 and other files"
Remove-Item -Force $resourceManagerPath\AzureRM.DataLakeAnalytics\AzureRM.Tags.psd1 -ErrorAction SilentlyContinue
Remove-Item -Force $resourceManagerPath\AzureRM.DataLakeAnalytics\Microsoft.Azure.Commands.Tags.dll-Help.xml -ErrorAction SilentlyContinue
Remove-Item -Force $resourceManagerPath\AzureRM.DataLakeAnalytics\Microsoft.Azure.Commands.Tags.format.ps1xml -ErrorAction SilentlyContinue
Remove-Item -Force $resourceManagerPath\AzureRM.DataLakeStore\AzureRM.Tags.psd1 -ErrorAction SilentlyContinue
Remove-Item -Force $resourceManagerPath\AzureRM.DataLakeStore\Microsoft.Azure.Commands.Tags.dll-Help.xml -ErrorAction SilentlyContinue
Remove-Item -Force $resourceManagerPath\AzureRM.DataLakeStore\Microsoft.Azure.Commands.Tags.format.ps1xml -ErrorAction SilentlyContinue
Remove-Item -Force $resourceManagerPath\AzureRM.Intune\AzureRM.Intune.psd1 -ErrorAction SilentlyContinue
Remove-Item -Force $resourceManagerPath\AzureRM.RecoveryServices.Backup\AzureRM.RecoveryServices.psd1 -ErrorAction SilentlyContinue

Write-Verbose "Removing duplicated Resources folder"
Remove-Item -Recurse -Force $serviceManagementPath\Compute\Resources\ -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $serviceManagementPath\Sql\Resources\ -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $serviceManagementPath\Storage\Resources\ -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $serviceManagementPath\Networking\Resources\ -ErrorAction SilentlyContinue

Write-Verbose "Removing generated NuGet folders from $output"
$resourcesFolders = @("de", "es", "fr", "it", "ja", "ko", "ru", "zh-Hans", "zh-Hant")
Get-ChildItem -Include $resourcesFolders -Recurse -Force -Path $output | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

Write-Verbose "Removing XML help files for helper dlls from $output"
$exclude = @("*.dll-Help.xml", "Scaffold.xml", "RoleSettings.xml", "WebRole.xml", "WorkerRole.xml")
$include = @("*.xml", "*.lastcodeanalysissucceeded", "*.dll.config", "*.pdb")
Get-ChildItem -Include $include -Exclude $exclude -Recurse -Path $output | Remove-Item -Force -Recurse
Get-ChildItem -Recurse -Path $output -Include *.dll-Help.psd1 | Remove-Item -Force

Write-Verbose "Removing markdown help files and folders"
Get-ChildItem -Recurse -Path $output -Include *.md | Remove-Item -Force
Get-ChildItem -Directory -Include help -Recurse -Path $output | Remove-Item -Force

Write-Verbose "Removing unneeded web deployment dependencies"
$webdependencies = @("Microsoft.Web.Hosting.dll", "Microsoft.Web.Delegation.dll", "Microsoft.Web.Administration.dll", "Microsoft.Web.Deployment.Tracing.dll")
Get-ChildItem -Include $webdependencies -Recurse -Path $output | Remove-Item -Force

if (Get-Command "heat.exe" -ErrorAction SilentlyContinue)
{
	$azureFiles = Join-Path $env:AzurePSRoot 'setup\azurecmdfiles.wxi'
    heat dir $output -srd -sfrag -sreg -ag -g1 -cg azurecmdfiles -dr PowerShellFolder -var var.sourceDir -o $azureFiles
    
	
	(gc $azureFiles).replace('<Wix', '<Include') | Set-Content $azureFiles
	(gc $azureFiles).replace('</Wix' ,'</Include') | Set-Content $azureFiles
}
else
{
    Write-Error "Failed to execute heat.exe, the Wix bin folder is not in PATH"
}
