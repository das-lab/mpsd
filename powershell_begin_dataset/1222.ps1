











& (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
$shareName = 'CarbonTestFileShare'
$sharePath = $null
$shareDescription = 'Share for testing Carbon''s Get-FileShare function.'

function Start-TestFixture
{
    $sharePath = New-TempDirectory -Prefix $PSCommandPath
    Install-SmbShare -Path $sharePath -Name $shareName -Description $shareDescription
}

function Stop-TestFixture
{
    $share = Get-WmiObject 'Win32_Share' -Filter "Name='$shareName'"
    if( $share -ne $null )
    {
        [void] $share.Delete()
    }

    Remove-Item -Path $sharePath
}

function Test-ShouldTestShare
{
    $shares = Get-FileShare
    Assert-NotNull $shares 
    $sharesNotFound = $shares | Where-Object { -not (Test-FileShare -Name $_.Name) }
    Assert-Null $sharesNotFound
    Assert-NoError
}

function Test-ShouldDetectSharesThatDoNotExist
{
    Assert-False (Test-FileShare -Name 'fdjfkdsfjdsf')
    Assert-NoError
}

