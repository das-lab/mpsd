











$windowsAuthWasLocked = $false
$windowsAuthConfigPath = 'system.webServer/security/authentication/windowsAuthentication'
$cgiConfigPath = 'system.webServer/cgi'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    $windowsAuthWasLocked = Test-IisConfigurationSection -SectionPath $windowsAuthConfigPath -Locked
    Unlock-IisConfigurationSection -SectionPath $windowsAuthConfigPath
    Assert-False (Test-IisConfigurationSection -SectionPath $windowsAuthConfigPath -Locked)

    $cgiWasLocked = Test-IisConfigurationSection -SectionPath $cgiConfigPath -Locked
    Unlock-IisConfigurationSection -SectionPath $cgiConfigPath
    Assert-False (Test-IisConfigurationSection -SectionPath $cgiConfigPath -Locked)
}

function Stop-Test
{
    
    if( $windowsAuthWasLocked )
    {
        Lock-IisConfigurationSection -SectionPath $windowsAuthConfigPath
    }
    else
    {
        Unlock-IisConfigurationSection -SectionPath $windowsAuthConfigPath
    }
    
    if( $cgiWasLocked )
    {
        Lock-IisConfigurationSection -SectionPath $cgiConfigPath
    }
    else
    {
        Unlock-IisConfigurationSection -SectionPath $cgiConfigPath
    }
    
    $webConfigPath = Join-Path $TestDir web.config
    if( Test-Path -Path $webConfigPath )
    {
        Remove-Item $webConfigPath
    }
}

function Test-ShouldLockOneConfigurationSection
{
    Lock-IisConfigurationSection -SectionPath $windowsAuthConfigPath
    Assert-True (Test-IisConfigurationSection -SectionPath $windowsAuthConfigPath -Locked)
}

function Test-ShouldUnlockMultipleConfigurationSection
{
    Lock-IisConfigurationSection -SectionPath $windowsAuthConfigPath,$cgiConfigPath
    Assert-True (Test-IisConfigurationSection -SectionPath $windowsAuthConfigPath -Locked)
    Assert-True (Test-IisConfigurationSection -SectionPath $cgiConfigPath -Locked)
}

function Test-ShouldSupportWhatIf
{
    Assert-False (Test-IisConfigurationSection -SectionPath $windowsAuthConfigPath -Locked)
    Lock-IisConfigurationSection -SectionPath $windowsAuthConfigPath -WhatIf
    Assert-False (Test-IisConfigurationSection -SectionPath $windowsAuthConfigPath -Locked)
}

