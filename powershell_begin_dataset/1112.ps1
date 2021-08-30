











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

function Test-ShouldDisableAnonymousAuthenticationOnVDir
{
    Disable-IisSecurityAuthentication -SiteName $siteName -Path SubFolder -Anonymous
    Assert-False (Test-IisSecurityAuthentication -SiteName $siteName -Path SubFolder -Anonymous)
}

function Test-ShouldDisableAnonymousAuthentication
{
    Disable-IisSecurityAuthentication -SiteName $siteName -Anonymous
    Assert-False (Test-IisSecurityAuthentication -SiteName $siteName -Anonymous)
}

function Test-ShouldDisableBasicAuthentication
{
    Enable-IisSecurityAuthentication -SiteName $siteName -Basic
    Assert-True (Test-IisSecurityAuthentication -SiteName $siteName -Basic)
    Disable-IisSecurityAuthentication -SiteName $siteName -Basic
    Assert-False (Test-IisSecurityAuthentication -SiteName $siteName -Basic)
}

function Test-ShouldDisableWindowsAuthentication
{
    Enable-IisSecurityAuthentication -SiteName $siteName -Windows
    Assert-True (Test-IisSecurityAuthentication -SiteName $siteName -Windows)
    Disable-IisSecurityAuthentication -SiteName $siteName -Windows
    Assert-False (Test-IisSecurityAuthentication -SiteName $siteName -Windows)
}

function Test-ShouldDisableEnabledAnonymousAuthentication
{
    Enable-IisSecurityAuthentication -SiteName $siteName -Anonymous
    Assert-True (Test-IisSecurityAuthentication -SiteName $siteName -Anonymous)
    Disable-IisSecurityAuthentication -SiteName $siteName -Anonymous
    Assert-False (Test-IisSecurityAuthentication -SiteName $siteName -Anonymous)
}

function Test-ShouldSupportWhatIf
{
    Enable-IisSecurityAuthentication -SiteName $siteName -Anonymous
    Assert-True (Test-IisSecurityAuthentication -SiteName $siteName -Anonymous)
    Disable-IisSecurityAuthentication -SiteName $siteName -Anonymous -WhatIf
    Assert-True (Test-IisSecurityAuthentication -SiteName $siteName -Anonymous)
}

