











$username = 'CarbonRemoveUser'
$password = 'IM33tRequ!rem$'

function Start-Test
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    net user $username $password /add
}

function Stop-Test
{
    if( Test-User -Username $username )
    {
        net user $username /delete
    }
}

function Test-ShouldRemoveUser
{
    Uninstall-User -Username $username
    Assert-False (Test-User -Username $username)
}

function Test-ShouldHandleRemovingNonExistentUser
{
    $Error.Clear()
    Uninstall-User -Username ([Guid]::NewGuid().ToString().Substring(0,20))
    Assert-False $Error
}

function Test-ShouldSupportWhatIf
{
    Uninstall-User -Username $username -WhatIf
    Assert-True (Test-User -Username $username)
}

