












$SiteName = 'TestSite'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Remove-TestWebsite
}

function Stop-Test
{
    Remove-TestWebsite
}

function Remove-TestWebsite
{
    if( Test-IisWebsite -Name $SiteName )
    {
        Uninstall-IisWebsite -Name $SiteName
        Assert-LastProcessSucceeded 'Unable to delete test site.'
    }
}

function Invoke-RemoveWebsite($Name = $SiteName)
{
    Uninstall-IisWebsite $Name
    Assert-SiteDoesNotExist $Name
}

function Test-ShouldRemoveNonExistentSite
{
    Invoke-RemoveWebsite 'fjsdklfsdjlf'
}

function Test-ShouldRemoveSite
{
    Install-IisWebsite -Name $SiteName -Path $TestDir
    Assert-LastProcessSucceeded 'Unable to create site.'
    
    Invoke-RemoveWebsite

    Assert-SiteDoesNotExist $SiteName    
}

function Assert-SiteDoesNotExist($Name)
{
    Assert-False (Test-IisWebsite -Name $Name) "Website $Name exists!"
}

