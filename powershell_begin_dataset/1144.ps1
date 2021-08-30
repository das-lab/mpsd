











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldGetCallStores
{
    foreach( $location in ([enum]::GetValues('Security.Cryptography.X509Certificates.StoreLocation')) )
    {
        foreach( $name in ([Enum]::GetValues('Security.Cryptography.X509Certificates.StoreName')) )
        {
            Write-Verbose ('Location: {0}; Name: {1}' -f $location,$name)
            [Security.Cryptography.X509Certificates.X509Store]$store = Get-CertificateStore -StoreLocation $location -StoreName $name
            Assert-NotNull $store
            $actual = $store.Name
            if( $actual -eq 'CA' )
            {
                $actual = 'CertificateAuthority'
            }
            Assert-Equal $location $store.Location 
            Assert-Equal $name $actual
        }
    }
}

function Test-ShouldCreateStore
{
    $store = Get-CertificateStore -StoreLocation CurrentUser -CustomStoreName 'fubar'
    Assert-NotNull $store
    Assert-Equal 0 $store.Certificates.Count
    Assert-Equal 'fubar' $store.Name
}

