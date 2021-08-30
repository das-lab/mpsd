











$siteName = 'DefaultDocument'
$sitePort = 4387
$webConfigPath = Join-Path $TestDir web.config

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)

    Install-IisAppPool -Name $siteName
}

function Stop-TestFixture
{
    Uninstall-IisAppPool -Name $siteName
}

function Start-Test
{
    Uninstall-IisWebsite $siteName
    Install-IisWebsite -Name $siteName -Path $TestDir -Bindings "http://*:$sitePort" -AppPoolName $siteName
    if( Test-Path $webConfigPath -PathType Leaf )
    {
        Remove-Item $webConfigPath
    }
}

function Stop-Test
{
    Uninstall-IisWebsite $siteName
}

function Test-ShouldAddDefaultDocument
{
    Add-IISDefaultDocument -Site $SiteName -FileName 'NewWebsite.html'
    Assert-DefaultDocumentReturned
    Assert-FileDoesNotExist $webConfigPath "Settings were made in site web.config, not apphost.config."
}

function Test-ShouldAddDefaultDocumentTwice
{
    Add-IISDefaultDocument -Site $SiteName -FileName 'NewWebsite.html'
    Add-IISDefaultDocument -Site $SiteName -FileName 'NewWebsite.html'
    Assert-NoError
    $section = Get-IisConfigurationSection -SiteName $SiteName -SectionPath 'system.webServer/defaultDocument'
    Assert-NotNull $section
    Assert-Is ($section.GetCollection('files') | Where-Object { $_['value'] -eq 'NewWebsite.html' }) ([Microsoft.Web.Administration.ConfigurationElement])
    Assert-DefaultDocumentReturned
}

function Assert-DefaultDocumentReturned()
{
    $html = ''
    $maxTries = 10
    $tryNum = 0
    $defaultDocumentReturned = $false
    do
    {
        try
        {    
            $browser = New-Object Net.WebClient
            $html = $browser.downloadString( "http://localhost:$sitePort/" )
            Assert-Like $html 'NewWebsite Test Page' 'Unable to download from new website.'   
            $defaultDocumentReturned = $true
        }
        catch
        {
            Start-Sleep -Milliseconds 100
        }
        $tryNum += 1
    }
    while( $tryNum -lt $maxTries -and -not $defaultDocumentReturned )
    
    Assert-True $defaultDocumentReturned "Default document never returned."
}

