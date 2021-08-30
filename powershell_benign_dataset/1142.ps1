











$username = 'CarbonGrantPrivilege' 
$password = 'a1b2c3d4

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Install-User -Username $username -Password $password -Description 'Account for testing Carbon Grant-Privileges functions.'
}

function Stop-Test
{
    Uninstall-User -Username $username
}

function Test-ShouldGrantAndRevokePrivileges
{
    $serviceName = 'CarbonGrantPrivilege' 
    $servicePath = Join-Path $TestDir ..\Service\NoOpService.exe -Resolve
    Install-Service -Name $serviceName -Path $servicePath -StartupType Manual -Username $username -Password $password
    
    Stop-Service $serviceName
    
    Revoke-Privilege -Identity $username -Privilege SeServiceLogonRight
    Assert-False (Test-Privilege -Identity $username -Privilege SeServiceLogonRight)
    Assert-Null (Get-Privilege -Identity $username | Where-Object { $_ -eq 'SeServiceLogonRight' })
    
    Grant-Privilege -Identity $username -Privilege SeServiceLogonRight
    Assert-True (Test-Privilege -Identity $username -Privilege SeServiceLogonRight)
    Assert-NotNull (Get-Privilege -Identity $username | Where-Object { $_ -eq 'SeServiceLogonRight' })
    
    Start-Service $serviceName
    
    Revoke-Privilege -Identity $username -Privilege SeServiceLogonRight
    Assert-False (Test-Privilege -Identity $username -Privilege SeServiceLogonRight)
    Assert-Null (Get-Privilege -Identity $username | Where-Object { $_ -eq 'SeServiceLogonRight' })
    
    $error.Clear()
    Start-Service $serviceName -ErrorAction SilentlyContinue
    Assert-Equal 0 $error.Count
    
}

function Test-ShouldWriteAnErrorIfIdentityNotFound
{
    $error.Clear()
    Grant-Privilege -Identity 'IDNOTEXIST' -Privilege SeBatchLogonRight -ErrorAction SilentlyContinue
    Assert-True ($error.Count -gt 0)
    Assert-True ($error[0].Exception.Message -like '*Identity * not found*')
}

function Test-ShouldGrantCaseSensitivePermission
{
    $Error.Clear()
    Grant-Privilege -Identity $username -Privilege SESERVICELOGONRIGHT -ErrorAction SilentlyContinue
    Assert-GreaterThan $Error.Count 1
    Assert-Like $Error[0].Exception.Message '*case-sensitive*'
}

