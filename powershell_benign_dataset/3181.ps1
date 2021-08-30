
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
Install-Module PSDepend -Force

Invoke-PSDepend -Force
Set-BuildEnvironment
Invoke-psake .\.build\2.psake.ps1

exit ( [int]( -not $psake.build_success ) )