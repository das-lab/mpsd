











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldTestUncPath
{
    Assert-True (Test-UncPath -Path '\\computer\share')
}

function Test-ShouldTestRelativePath
{
    Assert-False (Test-UncPath -Path '..\..\foo\bar')
}

function Test-ShouldTestNtfsPath
{
    Assert-False (Test-UncPath -Path 'C:\foo\bar\biz\baz\buz')
}

