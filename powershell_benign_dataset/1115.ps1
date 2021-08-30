











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldNotFindNonExistentWebsite
{
    $result = Test-IisWebsite 'jsdifljsdflkjsdf'
    Assert-False $result "Found a non-existent website!"
}

function Test-ShouldFindExistentWebsite
{
    Install-IisWebsite -Name 'Test Website Exists' -Path $TestDir
    try
    {
        $result = Test-IisWebsite 'Test Website Exists'
        Assert-True $result "Did not find existing website."
    }
    finally
    {
        Uninstall-IisWebsite 'Test Website Exists'
    }
}

