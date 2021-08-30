











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldDetect64BitProcess
{
    $expectedResult = ( $env:PROCESSOR_ARCHITECTURE -eq 'AMD64' )
    Assert-Equal $expectedResult (Test-PowerShellIs64Bit)
}

