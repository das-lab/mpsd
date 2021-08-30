











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldFindExistingSection
{
    Assert-True (Test-IisConfigurationSection -SectionPath 'system.webServer/cgi')
}

function Test-ShouldNotFindMissingSection
{
    $error.Clear()
    Assert-False (Test-IisConfigurationSection -SectionPath 'system.webServer/u2')
    Assert-Equal 2 $error.Count
}


