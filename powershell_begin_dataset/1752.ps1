






Get-Command -Module PowerShellGet


Find-Script
Find-Script -Name Start-Demo


Save-Script Start-Demo -Repository PSGallery -Path /tmp
Get-ChildItem -Path /tmp/Start-Demo.ps1


Find-Script -Name Start-Demo -Repository PSGallery  | Install-Script
Get-InstalledScript


Install-Script Fabrikam-Script -RequiredVersion 1.0
Get-InstalledScript
Get-InstalledScript Fabrikam-Script | Format-List *


Update-Script -WhatIf
Update-Script
Get-InstalledScript


Uninstall-Script Fabrikam-Script -Verbose







Find-Module -Tag 'PowerShellCore_Demo'


Save-Module -Tag 'PowerShellCore_Demo' -Path /tmp


Find-Module -Tag 'PowerShellCore_Demo' | Install-Module -Verbose
Get-InstalledModule


Update-Module






Find-Script -Tag 'PowerShellCore_Demo'


Find-Script -Tag 'PowerShellCore_Demo' | Install-Script -Verbose
Get-InstalledScript






Get-PSRepository


Register-PSRepository -Name "myPrivateGallery" –SourceLocation "https://www.myget.org/F/powershellgetdemo/api/v2" -InstallationPolicy Trusted


Set-PSRepository -Name "myPrivateGallery" -InstallationPolicy "Untrusted"


Unregister-PSRepository -Name "myPrivateGallery"


