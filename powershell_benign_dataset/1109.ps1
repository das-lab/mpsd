











$appPoolName = 'CarbonTestUninstallAppPool'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Uninstall-IisAppPool -Name $appPoolName
    Assert-False (Test-IisAppPool -Name $appPoolName)
}

function Stop-Test
{
    Uninstall-IisAppPool -Name $appPoolName
}

function Test-ShouldRemoveAppPool
{
    Install-IisAppPool -Name $appPoolName
    Assert-True (Test-IisAppPool -Name $appPoolName)
    Uninstall-IisAppPool -Name $appPoolName 
    Assert-False (Test-IisAppPool -Name $appPoolName)    
}

function Test-ShouldRemvoeMissingAppPool
{
    $missingAppPool = 'IDoNotExist'
    Assert-False (Test-IisAppPool -Name $missingAppPool)
    Uninstall-IisAppPool -Name $missingAppPool 
    Assert-False (Test-IisAppPool -Name $missingAppPool)    
}

function Test-ShouldSupportWhatIf
{
    Install-IisAppPool -Name $appPoolName
    Assert-True (Test-IisAppPool -Name $appPoolName)
    
    Uninstall-IisAppPool -Name $appPoolName -WhatIf
    Assert-True (Test-IisAppPool -Name $appPoolName)
}

