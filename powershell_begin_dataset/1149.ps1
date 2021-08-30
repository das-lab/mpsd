











$serviceBaseName = 'CarbonGrantControlServiceTest'
$serviceName = $serviceBaseName
$servicePath = Join-Path $TestDir NoOpService.exe

$user = 'CrbnGrantCntrlSvcUsr'
$password = [Guid]::NewGuid().ToString().Substring(0,9) + "Aa1"
$userPermStartPattern = "/pace =$($env:ComputerName)\$user*"
    
function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Install-User -username $user -Password $password
    
    $serviceName = $serviceBaseName + ([Guid]::NewGuid().ToString())
    Install-Service -Name $serviceName -Path $servicePath -Username $user -Password $password
}

function Stop-Test
{
    Uninstall-Service -Name $serviceName
    Uninstall-User -Username $user
}

function Test-ShouldGrantControlServicePermission
{
    $currentPerms = Get-ServicePermission -Name $serviceName -Identity $user
    Assert-Null $currentPerms "User '$user' already has permissions on '$serviceName'."
    
    Grant-ServiceControlPermission -ServiceName $serviceName -Identity $user
    Assert-LastProcessSucceeded
    
    $expectedAccessRights = [Carbon.Security.ServiceAccessRights]::QueryStatus -bor `
                            [Carbon.Security.ServiceAccessRights]::EnumerateDependents -bor `
                            [Carbon.Security.ServiceAccessRights]::Start -bor `
                            [Carbon.Security.ServiceAccessRights]::Stop
    $currentPerms = Get-ServicePermission -Name $serviceName -Identity $user
    Assert-NotNull $currentPerms
    Assert-Equal $expectedAccessRights $currentPerms.ServiceAccessRights
}

function Test-ShouldSupportWhatIf
{
    $currentPerms = Get-ServicePermission -Name $serviceName -Identity $user
    Assert-Null $currentPerms
    
    Grant-ServiceControlPermission -ServiceName $serviceName -Identity $user -WhatIf
    
    $currentPerms = Get-ServicePermission -Name $serviceName -Identity $user
    Assert-Null $currentPerms
}

