











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldNotFindNonExistentAppPool
{
    $exists = Test-IisAppPool -Name 'ANameIMadeUpThatShouldNotExist'
    Assert-False $exists "A non-existent app pool exists."
    Assert-NoError
}

function Test-ShouldFindAppPools
{
    $apppools = Get-IisAppPool
    Assert-GreaterThan $apppools.Length 0 "There aren't any app pools on the current machine!"
    foreach( $apppool in $apppools )
    {
        $exists = Test-IisAppPool -Name $appPool.Name
        Assert-True $exists "An existing app pool '$($appPool.Name)' not found."
    }
}


