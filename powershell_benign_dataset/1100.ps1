











$siteName = 'CarbonGetIisHttpHeader'
$sitePort = 47939

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Install-IisWebsite -Name $siteName -Path $TestDir -Binding ('http/*:{0}:*' -f $sitePort)
}

function Stop-Test
{
    Uninstall-IisWebsite -Name $siteName
}

function Test-ShouldReturnAllHeaders
{
    $currentHeaders = @( Get-IisHttpHeader -SiteName $siteName )
    
    Set-IisHttpHeader -SiteName $siteName -Name 'X-Carbon-Header1' -Value 'Value1'
    Set-IisHttpHeader -SiteName $siteName -Name 'X-Carbon-Header2' -Value 'Value2'
    
    $newHeaders = Get-IisHttpHeader -SiteName $siteName
    Assert-NotNull $newHeaders
    Assert-True ($newHeaders.Length -ge 2)
}

function Test-ShouldAllowSearchingByWildcard
{
    $name = 'X-Carbon-GetIisHttpRedirect'
    $value = [Guid]::NewGuid()
    Set-IisHttpHeader -SiteName $siteName -Name $name -Value $value
    
    ($name, 'X-Carbon*' ) | ForEach-Object {
        $header = Get-IisHttpHeader -SiteName $siteName -Name $_
        Assert-NotNull $header
        Assert-Equal $name $header.Name
        Assert-Equal $value $header.Value
    }
    
    $header = Get-IisHttpHeader -SiteName $siteName -Name 'blah*'
    Assert-Null $header
}

