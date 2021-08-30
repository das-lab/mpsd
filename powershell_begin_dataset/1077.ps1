











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldDetectIfOSIs64Bit
{
    $is64Bit = (Test-Path env:"ProgramFiles(x86)")
    Assert-Equal $is64Bit (Test-OSIs64Bit)
}

