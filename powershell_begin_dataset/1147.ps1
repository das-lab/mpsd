











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldCreateDisplayNameProperty
{
    $storeNameValues = [Enum]::GetValues( [Security.Cryptography.X509Certificates.StoreName] )
    Get-Item cert:\*\* | ForEach-Object {
        Assert-NotNull $_.DisplayName
        
        $storeName = $null

        $enumValue= $_.Name
        if( $enumValue -eq 'CA' )
        {
            $enumValue = 'CertificateAuthority'
        }
        if( $storeNameValues -contains $enumValue )
        {
            Assert-NotEqual $_.Name $_.DisplayName
        }
        else
        {
            Assert-Equal '' $_.DisplayName
        }
    }
}

