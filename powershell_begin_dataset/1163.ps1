












function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-NewTempDir
{
    $tmpDir = New-TempDir 
    try
    {
        Assert-DirectoryExists $tmpDir
    }
    finally
    {
        Uninstall-Directory -Path $tmpDir -Recurse
    }
}

function Test-ShouldSupportPrefix
{
    $tempDir = New-TempDir -Prefix 'fubar'
    try
    {
        Assert-DirectoryExists $tempDir
        Assert-Like $tempDir.Name 'fubar*'
    }
    finally
    {
        Uninstall-Directory -Path $tempDir -Recurse
    }
}

function Test-ShouldSupportPathsForPrefix
{
    $tempDir = New-TempDirectory -Prefix $PSCommandPath
    try
    {
        Assert-DirectoryExists $tempDir
        Assert-Like $tempDir.Name ('{0}*' -f (Split-Path -Leaf -Path $PSCommandPath))
    }
    finally
    {
        Uninstall-Directory -Path $tempDir -Recurse
    }
}

