











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldDetectIfOSIs32Bit
{
    $is32Bit = -not (Test-Path env:"ProgramFiles(x86)")
    Assert-Equal $is32Bit (Test-OSIs32Bit)
}

