











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    $PSCommandName = Split-Path -Leaf -Path $PSCommandPath
    $tempDir = New-TempDir -Prefix $PSCommandName
    $zipPath = Join-Path -Path $tempDir -ChildPath ('{0}.zip' -f $PSCommandName)
    Compress-Item -Path $PSCommandPath -OutFile $zipPath
}

function Stop-Test
{
    Remove-Item -Path $tempDir -Recurse
}

function Test-ShouldDetectZipFile
{
    Assert-True (Test-ZipFile -Path $zipPath)
}

function Test-ShouldTestNonZipFile
{
    Assert-False (Test-ZipFile -Path $PSCommandPath)
}

function Test-ShouldTestWithRelativePath
{
    $tempDir2 = New-TempDirectory -Prefix $PSCommandPath
    Push-Location $tempDir2
    try
    {
        $relativePath = Resolve-RelativePath -Path $zipPath -FromDirectory (Get-Location).ProviderPath
        Assert-True (Test-ZipFile -Path $relativePath)
    }
    finally
    {
        Pop-Location
        Remove-Item -Path $tempDir2 -Recurse
    }
}

function Test-ShouldTestNonExistentFile
{
    Assert-Null (Test-ZipFile -Path 'kablooey.zip' -ErrorAction SilentlyContinue)
    Assert-Error -Last -Regex 'not found'
}

