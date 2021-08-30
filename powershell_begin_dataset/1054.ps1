











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldDetect32BitProcess
{
    $expectedResult = ( $env:PROCESSOR_ARCHITECTURE -eq 'x86' )
    Assert-Equal $expectedResult (Test-PowerShellIs32Bit)
}

