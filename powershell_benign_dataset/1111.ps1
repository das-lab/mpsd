











$siteName = 'Anonymous Authentication'
$sitePort = 4387
$webConfigPath = Join-Path $TestDir web.config

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Uninstall-IisWebsite $siteName
    Install-IisWebsite -Name $siteName -Path $TestDir -Bindings "http://*:$sitePort"
    if( Test-Path $webConfigPath -PathType Leaf )
    {
        Remove-Item $webConfigPath
    }
}

function Stop-Test
{
    Uninstall-IisWebsite $siteName
}

function Test-ShouldEnableAnonymousAuthentication
{
    Enable-IisSecurityAuthentication -SiteName $siteName -Anonymous
    Assert-True (Test-IisSecurityAuthentication -SiteName $siteName -Anonymous)
    Assert-FileDoesNotExist $webConfigPath 
}

function Test-ShouldEnableBasicAuthentication
{
    Enable-IisSecurityAuthentication -SiteName $siteName -Basic
    Assert-True (Test-IisSecurityAuthentication -SiteName $siteName -Basic)
    Assert-FileDoesNotExist $webConfigPath 
}

function Test-ShouldEnableWindowsAuthentication
{
    Enable-IisSecurityAuthentication -SiteName $siteName -Windows
    Assert-True (Test-IisSecurityAuthentication -SiteName $siteName -Windows)
    Assert-FileDoesNotExist $webConfigPath 
}

function Test-ShouldEnableAnonymousAuthenticationOnSubFolders
{
    Enable-IisSecurityAuthentication -SiteName $siteName -Path SubFolder -Anonymous
    Assert-True (Test-IisSecurityAuthentication -SiteName $siteName -Path SubFolder -Anonymous)
}

function Test-ShouldSupportWhatIf
{
    Disable-IisSecurityAuthentication -SiteName $siteName -Anonymous
    Assert-False (Test-IisSecurityAuthentication -SiteName $siteName -Anonymous)
    Enable-IisSecurityAuthentication -SiteName $siteName -Anonymous -WhatIf
    Assert-False (Test-IisSecurityAuthentication -SiteName $siteName -Anonymous)
}

