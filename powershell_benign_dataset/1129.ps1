











$CategoryName = 'Carbon-PerformanceCounters-UninstallCategory'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    [Diagnostics.PerformanceCounterCategory]::Create( $CategoryName, '', (New-Object Diagnostics.CounterCreationDataCollection) )
    Assert-True (Test-PerformanceCounterCategory -CAtegoryName $CAtegoryName) 
}

function Stop-Test
{
    Uninstall-PerformanceCounterCategory -CategoryName $CategoryName
    Assert-False (Test-PerformanceCounterCategory -CAtegoryName $CAtegoryName) 
}

function Test-ShouldSupportWhatIf
{
    Uninstall-PerformanceCounterCategory -CategoryName $CategoryName -WhatIf
    Assert-True (Test-PerformanceCounterCategory -CategoryName $CategoryName)
}



