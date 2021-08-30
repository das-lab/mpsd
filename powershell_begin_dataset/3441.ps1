













$scriptFolder = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
. ($scriptFolder + '.\SetupEnv.ps1')

$packageFolder="$env:AzurePSRoot\artifacts"
if (Test-Path $packageFolder) {
    Remove-Item -Path $packageFolder -Recurse -Force	
}

$keyPath = "HKLM:\SOFTWARE\Microsoft\Windows Installer XML"
if (${env:ADX64Platform}){
    $keyPath = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows Installer XML"
}

$allWixVersions = Get-ChildItem $keyPath
if ($allWixVersions -ne $null){
    foreach ($wixVersion in $allWixVersions){
        $wixInstallRoot = $wixVersion.GetValue("InstallRoot", $null)
        if ($wixInstallRoot -ne $null) {
            Write-Verbose "WIX tools was installed at $wixInstallRoot"
            break
        }
    }
}

if ($wixInstallRoot -eq $null){
     Write-Host "You don't have Windows Installer XML Toolset installed, which is needed to build setup." -ForegroundColor "Yellow"
     Write-Host "Press (Y) to install through codeplex web page we will open for you; (N) to skip"    
     $keyPressed = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp")
     if ($keyPressed.Character -eq "y" ){
        Invoke-Expression "cmd.exe /C start http://wix.codeplex.com/downloads/get/762937"
        Read-Host "Press any key to continue after the installtion is finished"
     }
}



$env:path = $env:path + ";$wixInstallRoot"


&"$env:AzurePSRoot\tools\Installer\generate.ps1" 'Debug'


msbuild "$env:AzurePSRoot\build.proj" /t:Build

Write-Host "MSI file path: $env:AzurePSRoot\setup\build\Debug\AzurePowerShell.msi"
