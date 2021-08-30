











$siteName = 'Carbon-Set-IisWebsiteSslCertificate'
$cert = $null
$appID = '990ae75d-b1c3-4c4e-93f2-9b22dfbfe0ca'
$ipAddress = '43.27.98.0'
$port = '443'
$allPort = '8013'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Install-IisWebsite -Name $siteName -Path $TestDir -Bindings @( "https/$ipAddress`:$port`:", "https/*:$allPort`:" )
    $cert = Install-Certificate -Path (Join-Path $TestDir ..\Certificates\CarbonTestCertificate.cer -Resolve) -StoreLocation LocalMachine -StoreName My
}

function Stop-Test
{
    Uninstall-Certificate -Certificate $cert -StoreLocation LocalMachine -StoreName My
    Uninstall-IisWebsite -Name $siteName
}

function Test-ShouldSetWebsiteSslCertificate
{
    Set-IisWebsiteSslCertificate -SiteName $siteName -Thumbprint $cert.Thumbprint -ApplicationID $appID
    try
    {
        $binding = Get-SslCertificateBinding -IPAddress $ipAddress -Port $port
        Assert-NotNull $binding
        Assert-Equal $cert.Thumbprint $binding.CertificateHash
        Assert-Equal $appID $binding.ApplicationID
        
        $binding = Get-SslCertificateBinding -Port $allPort
        Assert-NotNull $binding
        Assert-Equal $cert.Thumbprint $binding.CertificateHash
        Assert-Equal $appID $binding.ApplicationID
        
    }
    finally
    {
        Remove-SslCertificateBinding -IPAddress $ipAddress -Port $port 
        Remove-SslCertificateBinding -Port $allPort
    } 
}

function Test-ShouldSupportWhatIf
{
    $bindings = @( Get-SslCertificateBinding )
    Set-IisWebsiteSslCertificate -SiteName $siteName -Thumbprint $cert.Thumbprint -ApplicationID $appID -WhatIf
    $newBindings = @( Get-SslCertificateBinding )
    Assert-Equal $bindings.Length $newBindings.Length
}

function Test-ShouldSupportWebsiteWithoutSslBindings
{
    Install-IisWebsite -Name $siteName -Path $TestDir -Bindings @( 'http/*:80:' )
    $bindings = @( Get-SslCertificateBinding )
    Set-IisWebsiteSslCertificate -SiteName $siteName -Thumbprint $cert.Thumbprint -ApplicationID $appID
    $newBindings = @( Get-SslCertificateBinding )
    Assert-Equal $bindings.Length $newBindings.Length
}

