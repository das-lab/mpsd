











$tempDir = $null
$compressedDirPath = $null
$compressedFilePath = $null
$uncompressedDirPath = $null
$uncompressedFilePath = $null

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    $tempDir = New-TempDirectoryTree @'
+ CompressedDir
+ UncompressedDir
* CompressedFile
* UncompressedFile
'@
    $compressedDirPath = Join-Path $tempDir 'CompressedDir' -Resolve
    $compressedFilePath = Join-Path $tempDir 'CompressedFile' -Resolve
    $uncompressedDirPath = Join-Path $tempDir 'UncompressedDir' -Resolve
    $uncompressedFilePath = Join-Path $tempDir 'UncompressedFile' -Resolve

    Enable-NtfsCompression -Path $compressedDirPath
    Enable-NtfsCompression -Path $compressedFilePath
}

function Stop-Test
{
    if( (Test-Path -Path $tempDir -PathType Container) )
    {
        Remove-Item -Path $tempDir -Recurse -Force
    }
}

function Test-ShouldDetectCompression
{
    Assert-True (Test-NtfsCompression -Path $compressedDirPath)
    Assert-True (Test-NtfsCompression -Path $compressedFilePath)
    Assert-False (Test-NtfsCompression -Path $uncompressedDirPath)
    Assert-False (Test-NtfsCompression -Path $uncompressedFilePath)
}

function Test-ShouldHandleBadPaths
{
    $Error.Clear()

    Assert-Null (Test-NtfsCompression -Path 'C:\I\Do\Not\Exist' -ErrorAction SilentlyContinue)

    Assert-Equal 1 $Error.Count
    Assert-True ($Error[0].Exception.Message -like '*not found*')
}

function Test-ShouldHandleHiddenDirectory
{
    $compressedDir = Get-Item -Path $compressedDirPath
    $compressedDir.Attributes = $compressedDir.Attributes -bor ([IO.FileAttributes]::Hidden)

    Assert-True (Test-NtfsCompression $compressedDirPath)
    Assert-NoError
}

