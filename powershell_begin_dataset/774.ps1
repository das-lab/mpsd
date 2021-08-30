$ErrorActionPreference = 'Stop'

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted | Out-Null
if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
    
    Get-Module PowerShellGet,PackageManagement | Remove-Module -Force -Verbose
    powershell -Command { Install-Module -Name PowerShellGet -MinimumVersion 1.6 -Force -Confirm:$false -Verbose }
    powershell -Command { Install-Module -Name PackageManagement -MinimumVersion 1.1.7.0 -Force -Confirm:$false -Verbose }
    Import-Module -Name PowerShellGet -MinimumVersion 1.6 -Force
    Import-Module -Name PackageManagement -MinimumVersion 1.1.7.0 -Force
}


Update-Help -Force -ErrorAction SilentlyContinue


Install-Module InvokeBuild -MaximumVersion 5.1.0 -Scope CurrentUser
Install-Module PlatyPS -RequiredVersion 0.9.0 -Scope CurrentUser

Invoke-Build -Configuration Release
