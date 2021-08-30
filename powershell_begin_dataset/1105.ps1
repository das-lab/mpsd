











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldJoinPaths
{
    Assert-Equal 'SiteName' (Join-IisVirtualPath 'SiteName' '')
    Assert-Equal 'SiteName' (Join-IisVirtualPath 'SiteName' $null)
    Assert-Equal 'SiteName' (Join-IisVirtualPath 'SiteName')
    Assert-Equal 'SiteName/Virtual' (Join-IisVirtualPath 'SiteName' 'Virtual')
    Assert-Equal 'SiteName/Virtual' (Join-IisVirtualPath 'SiteName/' 'Virtual')
    Assert-Equal 'SiteName/Virtual' (Join-IisVirtualPath 'SiteName/' '/Virtual')
    Assert-Equal 'SiteName/Virtual' (Join-IisVirtualPath 'SiteName' '/Virtual')
    Assert-Equal 'SiteName/Virtual' (Join-IisVirtualPath 'SiteName\' 'Virtual')
    Assert-Equal 'SiteName/Virtual' (Join-IisVirtualPath 'SiteName\' '\Virtual')
    Assert-Equal 'SiteName/Virtual' (Join-IisVirtualPath 'SiteName' '\Virtual')
}

