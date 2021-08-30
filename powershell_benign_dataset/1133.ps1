











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldConvertSecureStringToString
{
    $secret = "Hello World!"
    $secureString = ConvertTo-SecureString -String $secret -AsPlainText -Force
    $notSoSecret = Convert-SecureStringToString $secureString
    Assert-Equal $secret $notSoSecret "Didn't convert a secure string to a string."
}

