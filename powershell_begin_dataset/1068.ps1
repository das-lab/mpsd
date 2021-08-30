












function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-GetFullPath
{
    $fullpath = Resolve-FullPath (Join-Path $TestDir '..\Tests' )
    $expectedFullPath = [System.IO.Path]::GetFullPath( (Join-Path $TestDir '..\Tests') )
    Assert-Equal $expectedFullPath $fullPath "Didn't get full path for '..\Tests'."
}

function Test-ResolvesRelativePath
{
    Push-Location (Join-Path $env:WinDir system32)
    try
    {
        $fullPath = Resolve-FullPath -Path '..\..\Program Files'
        Assert-Equal $env:ProgramFiles $fullPath
    }
    finally
    {
        Pop-Location
    }
}

