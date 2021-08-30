











$junctionName = $null
$junctionPath = $null

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    $junctionName = [IO.Path]::GetRandomFilename()    
    $junctionPath = Join-Path $env:Temp $junctionName
    New-Junction -Link $junctionPath -Target $TestDir
}

function Stop-Test
{
    Remove-Junction -Path $junctionPath
}

function Test-ShouldAddIsJunctionProperty
{
    $dirInfo = Get-Item $junctionPath
    Assert-True $dirInfo.IsJunction
    
    $dirInfo = Get-Item $TestDir
    Assert-False $dirInfo.IsJunction
}

function Test-ShouldAddTargetPathProperty
{
    $dirInfo = Get-Item $junctionPath
    Assert-Equal $TestDir $dirInfo.TargetPath
    
    $dirInfo = Get-Item $Testdir
    Assert-Null $dirInfo.TargetPath
    
}

