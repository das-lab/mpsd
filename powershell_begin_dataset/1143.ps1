











$username = 'CarbonRevokePrivileg' 
$password = 'a1b2c3d4

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Install-User -Username $username -Password $password -Description 'Account for testing Carbon Revoke-Privileges functions.'
    
    Grant-Privilege -Identity $username -Privilege 'SeBatchLogonRight'
    Assert-True (Test-Privilege -Identity $username -Privilege 'SeBatchLogonRight')
}

function Stop-Test
{
    Uninstall-User -Username $username
}

function Test-ShouldNotRevokePrivilegeForNonExistentUser
{
    $error.Clear()
    Revoke-Privilege -Identity 'IDNOTEXIST' -Privilege SeBatchLogonRight -ErrorAction SilentlyContinue
    Assert-True ($error.Count -gt 0)
    Assert-True ($error[0].Exception.Message -like '*Identity * not found*')
}

function Test-ShouldNotBeCaseSensitive
{
    Revoke-Privilege -Identity $username -Privilege SEBATCHLOGONRIGHT
    Assert-False (Test-Privilege -Identity $username -Privilege SEBATCHLOGONRIGHT)
    Assert-False (Test-Privilege -Identity $username -Privilege SeBatchLogonRight)
}

function Test-ShouldRevokeNonExistentPrivilege
{
    $Error.Clear()
    Assert-False (Test-Privilege -Identity $username -Privilege SeServiceLogonRight)
    Revoke-Privilege -Identity $username -Privilege SeServiceLogonRight
    Assert-Equal 0 $Error.Count
    Assert-False (Test-Privilege -Identity $username -Privilege SeServiceLogonRight)
}

