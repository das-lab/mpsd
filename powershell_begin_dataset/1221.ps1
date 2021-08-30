











& (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
$shareName = 'CarbonGetFileShare'
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

function Test-ShouldGetPermissions
{
    $shares = Get-FileShare
    Assert-NotNull $shares 
    $carbonShare = $shares | Where-Object { $_.Name -eq $shareName }
}

function Test-ShouldGetSpecificShare
{
    $carbonShare = Get-FileShare -Name $shareName
    Assert-CarbonShare $carbonShare
}

function Test-ShouldGetOnlyFileShares
{
    $nonFileShares = Get-WmiObject -Class 'Win32_Share' | Where-Object { $_.Type -ne 0 -and $_.Type -ne 2147483648 }
    if( $nonFileShares )
    {
        foreach( $nonFileShare in $nonFileShares )
        {
            $share = Get-FileShare | Where-Object { $_.Name -eq $nonFileShare.Name }
            Assert-Null $share
        }
    }
    else
    {
        Write-Warning ('No non-file shares on this computer.')
    }
}

function Test-ShouldAcceptWildcards
{
    $carbonShare = Get-FileShare 'CarbonGetFile*'
    Assert-CarbonShare $carbonShare
}

function Test-ShouldWriteErrorWhenShareNotFound
{
    $share = Get-FileShare -Name 'fjdksdfjsdklfjsd' -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'not found'
    Assert-Null $share
}

function Test-ShouldNotWriteErrorIfNoWildcardMatches
{
    $carbonShare = Get-FileShare 'fjdskfsdf*'
    Assert-NoError 
    Assert-Null $carbonShare
}

function Test-ShouldIgnoreErrors
{
    Get-FileShare -Name 'fhsdfsdfhsdfsdaf' -ErrorAction Ignore
    Assert-NoError
}

function Assert-CarbonShare
{
    param(
        $Share
    )
    Assert-NotNull $Share
    Assert-Equal $shareDescription $Share.Description
    Assert-Equal $sharePath.FullName $Share.Path
}
