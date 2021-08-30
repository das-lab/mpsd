











$tempDir = $null
$zipPath = $null
$outputRoot = $null
$PSCommandName = Split-Path -Leaf -Path $PSCommandPath

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    $tempDir = New-TempDir -Prefix ('{0}-{1}' -f $PSCommandName,([IO.Path]::GetRandomFileName()))
    $zipPath = Join-Path -Path $tempDir -ChildPath ('{0}.zip' -f $PSCommandName)
    Compress-Item -Path $PSCommandPath -OutFile $zipPath

    $outputRoot = Join-Path -Path $tempDir -ChildPath 'OutputRoot'
}

function Stop-Test
{
    Uninstall-Directory -Path $tempDir -Recurse
}

function Test-ShouldFailIfFileNotAZipFile
{
    $outputRoot = Expand-Item -Path $PSCommandPath -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'not a ZIP file'
    Assert-Null $outputRoot
}

function Test-ShouldExpandWithRelativePathToZip
{
    $tempDir2 = New-TempDirectory -Prefix $PSCommandPath
    Push-Location $tempDir2
    try
    {
        $relativePath = Resolve-Path -Relative -Path $zipPath
        $result = Expand-Item -Path $relativePath -OutDirectory $outputRoot
        Assert-NoError
        Assert-NotNull $result
        Assert-FileExists (Join-Path -Path $outputRoot -ChildPath $PSCommandName)
    }
    finally
    {
        Pop-Location
        Uninstall-Directory -Path $tempDir2 -Recurse
    }
}

function Test-ShouldExpandWithRelativePathToOutput
{
    $tempDir2 = New-TempDirectory -Prefix $PSCommandPath
    Push-Location -Path $tempDir2
    try
    {
        New-Item -Path $outputRoot -ItemType 'Directory'
        $relativePath = Resolve-Path -Relative -Path $outputRoot
        $result = Expand-Item -Path $zipPath -OutDirectory $relativePath
        Assert-NoError
        Assert-NotNull $result
        Assert-FileExists (Join-Path -Path $outputRoot -ChildPath $PSCommandName)
    }
    finally
    {
        Pop-Location
        Uninstall-Directory -Path $tempDir2 -Recurse
    }
}

function Test-ShouldCreateOutputDirectory
{
    $result = Expand-Item -Path $zipPath -OutDirectory $outputRoot
    Assert-DirectoryExists $result.FullName
    Assert-DirectoryExists $outputRoot
}

function Test-ShouldCarryOnIfOutputDirectoryIsEmpty
{
    New-Item -Path $outputRoot -ItemType 'Directory'
    $result = Expand-Item -Path $zipPath -OutDirectory $outputRoot
    Assert-Equal $outputRoot $result.FullName
    Assert-NoError 
    Assert-Equal 1 @(Get-ChildItem $outputRoot).Count
}

function Test-ShouldStopIfOutputDirectoryNotEmpty
{
    New-Item -Path $outputRoot -ItemType 'Directory'
    $filePath = Join-Path -Path $outputRoot -ChildPath 'fubar'
    New-Item -Path $filePath -ItemType 'File'
    $result = Expand-Item -Path $zipPath -OutDirectory $outputRoot -ErrorAction SilentlyContinue
    Assert-Null $result
    Assert-Error -Last -Regex 'not empty'
    Assert-Null (Get-Content -Raw -Path $filePath)
}

function Test-ShouldReplaceOutputDirectoryWithForceFlag
{
    New-Item -Path $outputRoot -ItemType 'Directory'
    $fubarPath = Join-Path -Path $outputRoot -ChildPath 'fubar'
    New-Item -Path $fubarPath -ItemType 'File'
    $filePath = Join-Path -Path $outputRoot -ChildPath $PSCommandName
    New-Item -Path $filePath -ItemType 'File'
    $result = Expand-Item -Path $zipPath -OutDirectory $outputRoot -Force
    Assert-NoError
    Assert-Equal $outputRoot $result.FullName
    Assert-NotNull (Get-Content -Raw -Path $filePath)
}

function Test-ShouldNotExtractNonExistentFile
{
    $result = Expand-Item -Path 'C:\fubar.zip' -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'does not exist'
    Assert-Null $result
}

